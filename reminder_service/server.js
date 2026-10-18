const http = require('node:http');
const { timingSafeEqual } = require('node:crypto');
const { Scheduler, phone } = require('./scheduler');

function equal(a, b) {
  const aa = Buffer.from(String(a || '')); const bb = Buffer.from(String(b || ''));
  return aa.length === bb.length && timingSafeEqual(aa, bb);
}
async function body(req) {
  let data = ''; for await (const chunk of req) {
    data += chunk; if (Buffer.byteLength(data) > 1024 * 1024) throw new Error('Request terlalu besar');
  }
  return data ? JSON.parse(data) : {};
}
function createService(env = process.env, fetchImpl = fetch) {
  const upstream = new URL(env.WAHA_UPSTREAM_URL);
  if (!['http:', 'https:'].includes(upstream.protocol)) throw new Error('WAHA_UPSTREAM_URL harus HTTP(S)');
  for (const key of ['GATEWAY_API_KEY', 'WAHA_UPSTREAM_API_KEY', 'WEBHOOK_SECRET', 'DATA_DIR']) {
    if (!env[key]) throw new Error(`${key} wajib diisi`);
  }
  const session = env.WAHA_SESSION || 'default';
  const request = async (pathname, method = 'GET', payload) => {
    const result = await fetchImpl(new URL(pathname, upstream), {
      method, headers: { 'X-Api-Key': env.WAHA_UPSTREAM_API_KEY, 'Content-Type': 'application/json' },
      ...(payload === undefined ? {} : { body: JSON.stringify(payload) }),
      signal: AbortSignal.timeout(15000), redirect: 'error',
    });
    return result;
  };
  const scheduler = new Scheduler({ dataDir: env.DATA_DIR, timeZone: env.APP_TIMEZONE || 'Asia/Makassar',
    send: async (recipient, text) => {
      const result = await request('/api/sendText', 'POST', { session, chatId: `${phone(recipient)}@c.us`, text });
      if (!result.ok) throw new Error(`WAHA sendText HTTP ${result.status}`);
      return result.json();
    },
  });
  let ticking = false;
  async function tick() {
    if (ticking || !scheduler.state.config.enabled) return;
    ticking = true;
    try {
      if (env.SUPABASE_URL && env.SUPABASE_SERVICE_ROLE_KEY) {
        const result = await fetchImpl(new URL('/rest/v1/rpc/get_reminder_schedule', env.SUPABASE_URL), {
          method: 'POST', headers: { apikey: env.SUPABASE_SERVICE_ROLE_KEY,
            Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ p_timezone: scheduler.timeZone }), signal: AbortSignal.timeout(15000), redirect: 'error',
        });
        if (!result.ok) throw new Error(`Supabase schedule HTTP ${result.status}`);
        scheduler.sync({ courses: await result.json() });
      }
      await scheduler.tick();
    } catch (error) { console.error('Reminder tick:', error.message); }
    finally { ticking = false; }
  }
  const server = http.createServer(async (req, res) => {
    const json = (status, value) => { res.writeHead(status, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(value)); };
    const url = new URL(req.url, 'http://localhost');
    res.setHeader('Access-Control-Allow-Origin', env.APP_ORIGIN || '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type,X-Api-Key');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    if (req.method === 'OPTIONS') { res.writeHead(204); return res.end(); }
    if (url.pathname === '/health' && req.method === 'GET') return json(200, { status: 'ok' });
    try {
      if (url.pathname === '/webhooks/waha' && req.method === 'POST') {
        if (!equal(req.headers['x-webhook-secret'], env.WEBHOOK_SECRET)) return json(401, { error: 'Unauthorized' });
        const event = await body(req);
        if (event.session === session && event.event === 'message' && event.payload?.fromMe === false) {
          // Resolve hidden IDs through WAHA, never interpret LID digits as a phone.
          let sender = event.payload.from;
          if (typeof sender === 'string' && /^\d+@lid$/.test(sender)) {
            const mapping = await request(`/api/${encodeURIComponent(session)}/lids/${encodeURIComponent(sender)}`);
            sender = mapping.ok ? (await mapping.json()).pn : null;
          }
          if (typeof sender === 'string' && /@(c\.us|s\.whatsapp\.net)$/.test(sender)) {
            await scheduler.reply(sender, event.payload.body, event.id);
          }
        }
        return json(200, { success: true });
      }
      if (!equal(req.headers['x-api-key'], env.GATEWAY_API_KEY)) return json(401, { error: 'Unauthorized' });
      if (url.pathname === '/api/auto-reminder/config') {
        if (req.method === 'GET') return json(200, scheduler.configResult());
        if (req.method === 'POST') return json(200, { success: true, ...scheduler.configure(await body(req)) });
      }
      if (url.pathname === '/api/auto-reminder/sync-courses' && req.method === 'POST') return json(200, scheduler.sync(await body(req)));
      if (url.pathname === '/api/auto-reminder/history' && req.method === 'GET') return json(200, scheduler.state.history);
      if (url.pathname === '/api/auto-reminder/trigger-test' && req.method === 'POST') {
        const course = scheduler.state.courses[0];
        if (!course || !scheduler.state.config.enabled) return json(400, { error: 'Aktifkan pengingat dan sinkronkan jadwal terlebih dahulu.' });
        const created = await scheduler.create(course, 'Hari-H', scheduler.now().toISOString(), true);
        return json(200, { success: created, message: 'Simulasi dikirim hanya ke Komti; tidak ada pesan uji coba ke dosen.' });
      }
      // Proxy only the exact endpoints used by Flutter; never arbitrary upstream URLs.
      const encoded = encodeURIComponent(session);
      const allowedGet = [`/api/sessions/${encoded}`, `/api/${encoded}/auth/qr`, '/api/server/version'];
      const allowedPost = [`/api/sessions/${encoded}/start`, `/api/sessions/${encoded}/stop`, `/api/sessions/${encoded}/logout`, '/api/sessions', '/api/sendText'];
      if (!(req.method === 'GET' && allowedGet.includes(url.pathname)) &&
          !(req.method === 'POST' && allowedPost.includes(url.pathname))) return json(404, { error: 'Not found' });
      const payload = req.method === 'POST' ? await body(req) : undefined;
      if (payload && url.pathname === '/api/sendText') payload.session = session;
      if (payload && url.pathname === '/api/sessions') payload.name = session;
      const result = await request(url.pathname + url.search, req.method, payload);
      const type = result.headers.get('content-type') || 'application/json';
      if (result.ok && url.pathname === `/api/sessions/${encoded}`) {
        return json(result.status, { ...await result.json(), capabilities: ['auto-reminder'] });
      }
      res.writeHead(result.status, { 'Content-Type': type });
      res.end(Buffer.from(await result.arrayBuffer()));
    } catch (error) {
      console.error('Reminder request:', error.message);
      json(error instanceof SyntaxError || /valid|wajib|harus|besar/.test(error.message) ? 400 : 502,
        { error: 'Permintaan gagal. Periksa konfigurasi dan koneksi layanan.' });
    }
  });
  return { server, scheduler, tick };
}
if (require.main === module) {
  const service = createService();
  const timer = setInterval(service.tick, 30000);
  service.server.listen(Number(process.env.PORT || 8080), '0.0.0.0', () => {
    console.log('ILKOM reminder gateway listening'); service.tick();
  });
  process.on('SIGTERM', () => { clearInterval(timer); service.server.close(); });
}
module.exports = { createService };
