const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');

const defaults = {
  enabled: false, komtiPhone: '', komtiName: 'Ketua Kelas ILKOM',
  delayMinutes: 45, hMinusOneHour: '18:00', todayHour: '06:30',
  autoSendIfNoReply: true,
};
const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
function phone(value) {
  const raw = String(value || '').split('@')[0].split(':')[0];
  let digits = raw.replace(/\D/g, '');
  if (digits.startsWith('0')) digits = '62' + digits.slice(1);
  else if (digits.startsWith('8')) digits = '62' + digits;
  if (!/^[1-9]\d{7,14}$/.test(digits)) throw new Error('Nomor WhatsApp tidak valid');
  return digits;
}
function calendar(now, timeZone) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(now);
  const p = Object.fromEntries(parts.map(x => [x.type, x.value]));
  const date = `${p.year}-${p.month}-${p.day}`;
  return { date, time: `${p.hour}:${p.minute}`, day: new Date(`${date}T12:00:00Z`).getUTCDay() };
}
function validateConfig(input, previous = defaults) {
  const config = { ...previous };
  for (const key of Object.keys(defaults)) if (Object.hasOwn(input, key)) config[key] = input[key];
  if (typeof config.enabled !== 'boolean' || typeof config.autoSendIfNoReply !== 'boolean') throw new Error('Status pengingat harus boolean');
  if (!Number.isInteger(config.delayMinutes) || config.delayMinutes < 1 || config.delayMinutes > 1440) throw new Error('Waktu tunggu harus 1–1440 menit');
  for (const key of ['hMinusOneHour', 'todayHour']) if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(config[key])) throw new Error('Jam harus HH:mm');
  if (config.komtiPhone) config.komtiPhone = phone(config.komtiPhone);
  if (config.enabled && !config.komtiPhone) throw new Error('Nomor Komti wajib diisi sebelum mengaktifkan pengingat');
  config.komtiName = String(config.komtiName).slice(0, 100);
  return config;
}
function validateCourses(input) {
  if (!Array.isArray(input) || input.length > 1000) throw new Error('Daftar mata kuliah tidak valid');
  const ids = new Set();
  return input.map(c => {
    if (!c.id || ids.has(String(c.id)) || !c.nama || !days.includes(c.hari)) throw new Error('ID, nama, atau hari mata kuliah tidak valid');
    ids.add(String(c.id));
    for (const key of ['jamMulai', 'jamSelesai']) if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(c[key])) throw new Error('Jam kuliah harus HH:mm');
    return { id: String(c.id), nama: String(c.nama).slice(0, 200), kode: String(c.kode || ''),
      dosen: String(c.dosen || 'Dosen Pengampu'), dosenWa: c.dosenWa ? phone(c.dosenWa) : '',
      hari: c.hari, jamMulai: c.jamMulai, jamSelesai: c.jamSelesai,
      ruangan: String(c.ruangan || 'Sesuai jadwal'), isCancelledToday: c.isCancelledToday === true,
      ...(c.targetDate ? { targetDate: String(c.targetDate) } : {}) };
  });
}

class Scheduler {
  constructor({ dataDir, send, timeZone = 'Asia/Makassar', now = () => new Date() }) {
    this.file = path.join(dataDir, 'reminders.json');
    this.send = send; this.timeZone = timeZone; this.now = now; this.busy = false;
    calendar(now(), timeZone); // Validate timezone before starting.
    fs.mkdirSync(dataDir, { recursive: true });
    this.state = fs.existsSync(this.file) ? JSON.parse(fs.readFileSync(this.file, 'utf8')) : {
      config: { ...defaults }, courses: [], jobs: {}, history: [], syncedAt: null,
    };
    // An interrupted send may already have reached WAHA: never retry it automatically.
    for (const job of Object.values(this.state.jobs)) {
      if (['prompting', 'sending'].includes(job.status)) job.status = 'uncertain';
    }
    this.persist();
  }
  persist() {
    fs.writeFileSync(this.file + '.tmp', JSON.stringify(this.state), { mode: 0o600 });
    fs.renameSync(this.file + '.tmp', this.file);
  }
  configResult() {
    const pending = Object.values(this.state.jobs).filter(x => x.status === 'pending');
    return { config: this.state.config, replyCodeDigits: 4, pendingCount: pending.length,
      pendingReminders: pending.map(x => ({ id: x.code || x.id, courseName: x.course.nama, scenario: x.scenario, scheduledAt: x.scheduledAt })),
      syncedAt: this.state.syncedAt, timeZone: this.timeZone };
  }
  configure(input) {
    this.state.config = validateConfig(input, this.state.config);
    this.persist(); return this.configResult();
  }
  sync(input) {
    const courses = validateCourses(input.courses);
    const config = validateConfig({
      ...(input.komtiPhone ? { komtiPhone: input.komtiPhone } : {}),
      ...(input.komtiName ? { komtiName: input.komtiName } : {}),
    }, this.state.config);
    this.state.courses = courses; this.state.config = config;
    this.state.syncedAt = this.now().toISOString(); this.persist();
    return { success: true, totalCourses: courses.length };
  }
  record(job, status) {
    job.status = status;
    this.state.history.unshift({ id: job.id, courseName: job.course.nama, scenario: job.scenario, status, timestamp: this.now().toISOString() });
    this.state.history = this.state.history.slice(0, 500);
    this.persist();
  }
  async create(course, scenario, date, test = false) {
    if (!this.state.config.enabled && !test) return false;
    if (!course.dosenWa && !test) return false;
    const id = createHash('sha256').update(`${course.id}|${scenario}|${date}|${test ? 'test' : 'live'}`).digest('hex').slice(0, 12);
    if (this.state.jobs[id]) return false;
    const config = this.state.config;
    const usedCodes = new Set(Object.values(this.state.jobs).map(job => job.code));
    let code;
    const start = parseInt(id.slice(0, 8), 16) % 10000;
    for (let offset = 0; offset < 10000; offset++) {
      const candidate = String((start + offset) % 10000).padStart(4, '0');
      if (!usedCodes.has(candidate)) { code = candidate; break; }
    }
    if (!code) throw new Error('Kode pengingat habis; hubungi administrator.');
    const job = { id, code, course: { ...course }, scenario, date, test, status: 'prompting',
      komtiPhone: config.komtiPhone, senderName: config.komtiName,
      autoSendIfNoReply: !test && config.autoSendIfNoReply,
      scheduledAt: new Date(this.now().getTime() + config.delayMinutes * 60000).toISOString() };
    this.state.jobs[id] = job; this.persist(); // Claim before network I/O.
    try {
      await this.send(job.komtiPhone,
        `${test ? '[SIMULASI — tidak mengirim ke dosen]\n' : ''}Pengingat ${scenario}: ${course.nama}\nDosen: ${course.dosen}\nJadwal: ${course.hari}, ${course.jamMulai}–${course.jamSelesai} (${this.timeZone})\nRuangan: ${course.ruangan}\n\nBalas KIRIM ${code} atau BATAL ${code}.\n${job.autoSendIfNoReply ? `Batas tunggu ${config.delayMinutes} menit sebelum pengiriman otomatis.` : 'Pesan hanya dikirim setelah konfirmasi Komti.'}`);
      this.record(job, 'pending'); return true;
    } catch (error) {
      this.record(job, 'uncertain'); throw error;
    }
  }
  async deliver(job) {
    if (job.status !== 'pending' || (!this.state.config.enabled && !job.test)) return;
    this.record(job, 'sending');
    try {
      const c = job.course;
      const text = `Assalamu’alaikum Bapak/Ibu ${c.dosen}.\nSaya ${job.senderName}, Koordinator Kelas ILKOM UNAZLAM.\nIzin mengonfirmasi jadwal perkuliahan ${job.scenario === 'H-1' ? 'besok' : 'hari ini'}:\n${c.nama} (${c.kode})\n${c.hari}, ${c.jamMulai}–${c.jamSelesai} (${this.timeZone})\nRuangan: ${c.ruangan}\nMohon konfirmasi kesediaan Bapak/Ibu atau arahan jika ada penyesuaian. Terima kasih.`;
      await this.send(job.test ? job.komtiPhone : c.dosenWa, job.test ? `[SIMULASI]\n${text}` : text);
      this.record(job, 'sent');
    } catch (error) {
      this.record(job, 'uncertain'); throw error;
    }
  }
  async reply(sender, text, eventId) {
    const match = /^(KIRIM|BATAL)\s+(\d{4}|[a-f0-9]{12})$/i.exec(String(text).trim());
    if (!match) return;
    let normalized;
    try { normalized = phone(sender); } catch { return; }
    const token = match[2].toLowerCase();
    const job = token.length === 4
      ? Object.values(this.state.jobs).find(item => item.code === token)
      : this.state.jobs[token];
    if (!job || job.status !== 'pending' || normalized !== job.komtiPhone) return;
    if (!this.state.config.enabled && !job.test) return;
    if (match[1].toUpperCase() === 'BATAL') this.record(job, 'cancelled');
    else await this.deliver(job);
  }
  async tick() {
    if (this.busy || !this.state.config.enabled) return;
    this.busy = true;
    try {
      const now = this.now(); const c = calendar(now, this.timeZone);
      // A sync snapshot older than 24 hours must not silently send outdated schedules.
      const fresh = this.state.syncedAt && now - new Date(this.state.syncedAt) < 86400000;
      if (fresh) {
        for (const course of this.state.courses) {
          if (c.time === this.state.config.hMinusOneHour && course.hari === days[(c.day + 1) % 7]) {
            await this.create(course, 'H-1', c.date);
          }
          if (c.time === this.state.config.todayHour && course.hari === days[c.day] && !course.isCancelledToday) {
            await this.create(course, 'Hari-H', c.date);
          }
        }
      }
      for (const job of Object.values(this.state.jobs)) {
        if (job.status === 'pending' && fresh && job.course.targetDate) {
          const latest = this.state.courses.find(x => x.id === job.course.id);
          if (!latest || !latest.dosenWa) this.record(job, 'cancelled');
          else { job.course = { ...latest }; this.persist(); }
        }
        if (job.status === 'pending' && now - new Date(job.scheduledAt) > 86400000) this.record(job, 'expired');
        if (job.status === 'pending' && job.autoSendIfNoReply && new Date(job.scheduledAt) <= now) await this.deliver(job);
      }
    } finally { this.busy = false; }
  }
}
module.exports = { Scheduler, phone, calendar, validateConfig, validateCourses };
