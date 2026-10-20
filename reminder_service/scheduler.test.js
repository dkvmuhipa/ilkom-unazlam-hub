const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'); const os = require('node:os'); const path = require('node:path');
const { Scheduler, calendar, phone } = require('./scheduler');
const { createService } = require('./server');
const course = { id: 'mk1', nama: 'Komunikasi', kode: 'ILK1', dosen: 'Dosen', dosenWa: '081234567890', hari: 'Senin', jamMulai: '08:00', jamSelesai: '10:00', ruangan: 'A' };
function setup(t, send = async () => {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'ilkom-reminders-'));
  t.after(() => {
    const root = path.resolve(os.tmpdir()) + path.sep;
    if (!path.resolve(dir).startsWith(root) || !path.basename(dir).startsWith('ilkom-reminders-')) throw new Error('Invalid test cleanup path');
    fs.rmSync(dir, { recursive: true, force: true });
  });
  let time = new Date('2026-10-19T06:30:00+08:00');
  const args = { dataDir: dir, send, now: () => time };
  const scheduler = new Scheduler(args);
  scheduler.configure({ enabled: true, komtiPhone: '081111111111', delayMinutes: 1 });
  scheduler.sync({ courses: [course] });
  return { scheduler, args, setTime: x => { time = new Date(x); } };
}
test('Timezone is independent of host and Indonesian phone normalizes exactly', () => {
  assert.deepEqual(calendar(new Date('2026-10-18T22:30:00Z'), 'Asia/Makassar'), { date: '2026-10-19', time: '06:30', day: 1 });
  assert.equal(phone('081234567890'), '6281234567890');
  assert.throws(() => phone('123'));
});

test('Four digit reply codes remain unique across restart and completed jobs', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  await f.scheduler.create(course, 'Hari-H', 'code-one', true);
  const first = Object.values(f.scheduler.state.jobs)[0];
  assert.match(first.code, /^\d{4}$/);
  assert.ok(sends[0][1].includes(`KIRIM ${first.code}`));
  await f.scheduler.reply('6281111111111@c.us', `BATAL ${first.code}`);
  const restarted = new Scheduler(f.args);
  await restarted.create(course, 'Hari-H', 'code-two', true);
  const second = Object.values(restarted.state.jobs).find(x => x.id !== first.id);
  assert.notEqual(second.code, first.code);
  await restarted.reply('6281111111111@c.us', `KIRIM ${first.code}`);
  assert.equal(second.status, 'pending');
  await restarted.reply('6281111111111@c.us', `KIRIM ${second.code}`);
  assert.equal(second.status, 'sent');
});
test('A scheduled reminder survives restart and sends at most once', async t => {
  const sends = []; const fixture = setup(t, async (...args) => sends.push(args));
  await Promise.all([fixture.scheduler.tick(), fixture.scheduler.tick()]);
  assert.equal(sends.length, 1);
  const restarted = new Scheduler(fixture.args);
  await restarted.tick(); assert.equal(sends.length, 1);
  fixture.setTime('2026-10-19T06:32:00+08:00');
  await restarted.tick(); await restarted.tick(); assert.equal(sends.length, 2);
  assert.equal(sends[1][0], '6281234567890');
});
test('Only the correct Komti and exact job can confirm; duplicate replies are harmless', async t => {
  const sends = []; const { scheduler } = setup(t, async (...args) => sends.push(args));
  await scheduler.tick(); const job = Object.values(scheduler.state.jobs)[0];
  await scheduler.reply('628222222222@c.us', `KIRIM ${job.code}`); assert.equal(sends.length, 1);
  await scheduler.reply('6281111111111@c.us', 'KIRIM'); assert.equal(sends.length, 1);
  await Promise.all([scheduler.reply('6281111111111@c.us', `KIRIM ${job.code}`), scheduler.reply('6281111111111@c.us', `KIRIM ${job.code}`)]);
  assert.equal(sends.length, 2);
});
test('Cancellation and disabled feature prevent timeout sends', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  await f.scheduler.tick(); const job = Object.values(f.scheduler.state.jobs)[0];
  await f.scheduler.reply('6281111111111@c.us', `BATAL ${job.code}`);
  f.setTime('2026-10-19T06:32:00+08:00'); await f.scheduler.tick(); assert.equal(sends.length, 1);
  f.scheduler.configure({ enabled: false });
  await f.scheduler.create(course, 'H-1', '2026-10-20'); assert.equal(sends.length, 1);
});
test('Ambiguous network failures are persisted and not retried on restart', async t => {
  let calls = 0; const f = setup(t, async () => { calls++; throw new Error('timeout'); });
  await assert.rejects(f.scheduler.tick());
  const restarted = new Scheduler(f.args); await restarted.tick(); assert.equal(calls, 1);
  assert.equal(Object.values(restarted.state.jobs)[0].status, 'uncertain');
});
test('Simulation never sends to a lecturer, including confirmation', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  f.scheduler.configure({ enabled: false });
  await f.scheduler.create(course, 'Hari-H', 'test', true);
  const job = Object.values(f.scheduler.state.jobs)[0];
  assert.equal(job.autoSendIfNoReply, false);
  await f.scheduler.reply('6281111111111@c.us', `KIRIM ${job.code}`);
  assert.equal(sends.length, 2); assert.ok(sends.every(x => x[0] === '6281111111111'));
});
test('Stale course snapshots do not create unattended reminders', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  f.setTime('2026-10-26T06:30:00+08:00'); await f.scheduler.tick(); assert.equal(sends.length, 0);
});
test('Live cancellation removes a pending reminder before its timeout', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  f.scheduler.sync({ courses: [{ ...course, targetDate: '2026-10-19' }] });
  await f.scheduler.tick();
  f.scheduler.sync({ courses: [] });
  f.setTime('2026-10-19T06:32:00+08:00');
  await f.scheduler.tick();
  assert.equal(sends.length, 1);
  assert.equal(Object.values(f.scheduler.state.jobs)[0].status, 'cancelled');
});
test('Pending delivery uses the latest time and room from Supabase sync', async t => {
  const sends = []; const f = setup(t, async (...args) => sends.push(args));
  f.scheduler.sync({ courses: [{ ...course, targetDate: '2026-10-19' }] });
  await f.scheduler.tick();
  f.scheduler.sync({ courses: [{ ...course, targetDate: '2026-10-19', jamMulai: '09:00', ruangan: 'B' }] });
  f.setTime('2026-10-19T06:32:00+08:00');
  await f.scheduler.tick();
  assert.match(sends[1][1], /09:00/); assert.match(sends[1][1], /Ruangan: B/);
});
test('Gateway requires API auth and webhook secret, advertises capability, and proxies fixed session', async t => {
  const f = setup(t); const forwarded = [];
  const service = createService({ WAHA_UPSTREAM_URL: 'https://waha.example', WAHA_UPSTREAM_API_KEY: 'upstream',
    GATEWAY_API_KEY: 'gateway', WEBHOOK_SECRET: 'webhook', DATA_DIR: f.args.dataDir,
  }, async (url, options) => {
    forwarded.push({ url: url.toString(), options });
    return Response.json({ name: 'default', status: 'WORKING', engine: { engine: 'NOWEB' } });
  });
  await new Promise(resolve => service.server.listen(0, '127.0.0.1', resolve));
  t.after(() => { service.server.closeAllConnections(); service.server.close(); });
  const base = `http://127.0.0.1:${service.server.address().port}`;
  assert.equal((await fetch(`${base}/api/auto-reminder/config`)).status, 401);
  assert.equal((await fetch(`${base}/webhooks/waha`, { method: 'POST' })).status, 401);
  const response = await fetch(`${base}/api/sessions/default`, { headers: { 'X-Api-Key': 'gateway' } });
  assert.deepEqual((await response.json()).capabilities, ['auto-reminder']);
  assert.equal(forwarded[0].options.headers['X-Api-Key'], 'upstream');
  assert.equal((await fetch(`${base}/api/sessions/other`, { headers: { 'X-Api-Key': 'gateway' } })).status, 404);
  service.scheduler.configure({ enabled: false, komtiPhone: '6281111111111' });
  await service.scheduler.create(course, 'Hari-H', 'test-webhook', true);
  const job = Object.values(service.scheduler.state.jobs).find(x => x.test);
  const event = { event: 'message', session: 'default', engine: 'NOWEB', payload: {
    from: '987654321@lid', fromMe: false, body: `KIRIM ${job.code}`,
    _data: { key: { remoteJid: '987654321@lid', remoteJidAlt: '6281111111111@s.whatsapp.net', fromMe: false } },
  } };
  const webhook = value => fetch(`${base}/webhooks/waha`, { method: 'POST',
    headers: { 'X-Webhook-Secret': 'webhook', 'Content-Type': 'application/json' }, body: JSON.stringify(value) });
  const group = structuredClone(event); group.payload.from = '123@g.us';
  await webhook(group); assert.equal(job.status, 'pending');
  const mismatch = structuredClone(event); mismatch.payload._data.key.remoteJid = 'other@lid';
  await webhook(mismatch); assert.equal(job.status, 'pending');
  await webhook(event); assert.equal(job.status, 'sent');
  const sent = forwarded.filter(x => x.url.endsWith('/api/sendText'));
  assert.equal(sent.length, 2);
  assert.ok(sent.every(x => JSON.parse(x.options.body).chatId === '6281111111111@c.us'));
});
