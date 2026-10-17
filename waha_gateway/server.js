const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const QRCode = require('qrcode');
const pino = require('pino');
const {
  default: makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion,
} = require('@whiskeysockets/baileys');

const app = express();
const PORT = process.env.PORT || 3000;
const SESSIONS_DIR = path.join(__dirname, 'sessions');

if (!fs.existsSync(SESSIONS_DIR)) {
  fs.mkdirSync(SESSIONS_DIR, { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Sesi WhatsApp State
let sock = null;
let currentStatus = 'STOPPED'; // 'STARTING', 'SCAN_QR_CODE', 'WORKING', 'STOPPED', 'FAILED'
let currentQrRaw = null;
let currentQrBuffer = null;
let accountInfo = null;
let isStarting = false;

// Logger
const logger = pino({ level: 'silent' });

// =============================================================================
// FILE PERSISTENCE: CONFIG, COURSES, & HISTORY
// =============================================================================
const CONFIG_FILE = path.join(SESSIONS_DIR, 'auto_reminder_config.json');
const COURSES_FILE = path.join(SESSIONS_DIR, 'courses_cache.json');
const HISTORY_FILE = path.join(SESSIONS_DIR, 'reminder_history.json');

function loadAutoReminderConfig() {
  const defaultConfig = {
    enabled: true,
    komtiPhone: '',
    komtiName: 'Ketua Kelas ILKOM',
    delayMinutes: 45,
    hMinusOneHour: '18:00',
    todayHour: '06:30',
    autoSendIfNoReply: true,
  };

  try {
    if (fs.existsSync(CONFIG_FILE)) {
      const data = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      return { ...defaultConfig, ...data };
    }
  } catch (e) {
    console.error('[WAHA Gateway] Gagal membaca auto_reminder_config.json:', e);
  }
  return defaultConfig;
}

function saveAutoReminderConfig(cfg) {
  try {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), 'utf8');
  } catch (e) {
    console.error('[WAHA Gateway] Gagal menyimpan auto_reminder_config.json:', e);
  }
}

function loadCoursesCache() {
  try {
    if (fs.existsSync(COURSES_FILE)) {
      return JSON.parse(fs.readFileSync(COURSES_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('[WAHA Gateway] Gagal membaca courses_cache.json:', e);
  }
  return [];
}

function saveCoursesCache(courses) {
  try {
    fs.writeFileSync(COURSES_FILE, JSON.stringify(courses, null, 2), 'utf8');
  } catch (e) {
    console.error('[WAHA Gateway] Gagal menyimpan courses_cache.json:', e);
  }
}

function logReminderHistory(entry) {
  try {
    let history = [];
    if (fs.existsSync(HISTORY_FILE)) {
      history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf8'));
    }
    history.unshift({
      ...entry,
      timestamp: new Date().toISOString(),
    });
    // Simpan maks 200 history terbaru
    if (history.length > 200) history = history.slice(0, 200);
    fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2), 'utf8');
  } catch (e) {
    console.error('[WAHA Gateway] Gagal menulis reminder_history.json:', e);
  }
}

// In-Memory Pending Reminders (Menunggu Konfirmasi Komti)
// Key: pendingId -> { id, course, scenario, komtiPhone, dosenPhone, scheduledAt, timer, senderName }
const pendingReminders = new Map();
// Cache tracking pengiriman hari ini agar tidak dobel
const sentHistoryToday = new Set();

// =============================================================================
// HELPER FORMATTING & MESSAGING
// =============================================================================
function formatToBaileysJid(phone) {
  if (!phone) return null;
  let digits = phone.toString().replace(/[^0-9]/g, '');
  if (digits.startsWith('0')) digits = '62' + digits.substring(1);
  else if (digits.startsWith('8')) digits = '62' + digits;
  if (!digits.startsWith('62')) digits = '62' + digits;
  return `${digits}@s.whatsapp.net`;
}

function formatDisplayPhone(phone) {
  let digits = (phone || '').toString().replace(/[^0-9]/g, '');
  if (digits.startsWith('0')) digits = '62' + digits.substring(1);
  return digits;
}

function getWibDate() {
  const utc = Date.now() + (new Date().getTimezoneOffset() * 60000);
  return new Date(utc + (3600000 * 7));
}

function buildAcademicMessage({ course, senderName, scenario }) {
  const wib = getWibDate();
  const hour = wib.getHours();
  let salutation = 'Selamat Malam';
  if (hour >= 4 && hour < 11) salutation = 'Selamat Pagi';
  else if (hour >= 11 && hour < 15) salutation = 'Selamat Siang';
  else if (hour >= 15 && hour < 18) salutation = 'Selamat Sore';

  const cleanSender = senderName || 'Ketua Kelas';
  const dosen = course.dosen || 'Dosen Pengampu';
  const ruang = course.ruangan || 'Ruang Kelas';

  let body = '';
  if (scenario === 'H-1') {
    body = `Izin mengonfirmasi terkait agenda perkuliahan untuk *esok hari*:\n📚 *Mata Kuliah* : ${course.nama} (${course.kode || 'MK'})\n🗓️ *Hari / Waktu* : ${course.hari}, ${course.jamMulai} - ${course.jamSelesai} WIB\n📍 *Ruangan*     : ${ruang}\n🎯 *Beban Studi* : ${course.sks || 2} SKS\n\nMohon konfirmasi apakah perkuliahan esok hari dapat dilaksanakan sesuai jadwal di atas, atau apakah ada arahan/materi yang perlu rekan-rekan mahasiswa persiapkan terlebih dahulu?`;
  } else {
    body = `Izin mengingatkan bahwa *hari ini* terjadwal sesi perkuliahan:\n📚 *Mata Kuliah* : ${course.nama} (${course.kode || 'MK'})\n⏰ *Waktu*       : Hari ini, Pukul ${course.jamMulai} - ${course.jamSelesai} WIB\n📍 *Ruangan*     : ${ruang}\n\nRuang kelas dan rekan-rekan mahasiswa saat ini telah siap. Mohon konfirmasi kesediaan Bapak/Ibu atau arahan jika ada penyesuaian waktu.`;
  }

  return `Assalamu’alaikum Warahmatullahi Wabarakatuh,\n${salutation} Bapak/Ibu ${dosen}.\n\nMohon maaf mengganggu waktu dan aktivitas Bapak/Ibu. Saya *${cleanSender}*, mahasiswa S1 Ilmu Komunikasi UNAZLAM (Koordinator/Ketua Kelas ILKOM 2026).\n\n${body}\n\nTerima kasih banyak atas perhatian, bimbingan, dan waktu yang Bapak/Ibu luangkan.\n\nWassalamu’alaikum Warahmatullahi Wabarakatuh.`;
}

function buildKomtiPromptMessage({ course, scenario, delayMinutes }) {
  const targetLabel = scenario === 'H-1' ? 'Esok Hari' : 'Hari Ini';
  return `🔔 *[PENGINGAT KULIAH UNAZLAM]*\nHalo Ketua Kelas / Komti! 👋\n\nTerjadwal perkuliahan untuk *${targetLabel}*:\n📚 *MK*: ${course.nama} (${course.kode || 'MK'})\n👨‍🏫 *Dosen*: ${course.dosen}\n⏰ *Waktu*: ${course.hari}, ${course.jamMulai} - ${course.jamSelesai} WIB\n📍 *Ruangan*: ${course.ruangan}\n\n⏳ *Otomatisasi Cerdas (Smart Reminder)*:\nPesan konfirmasi resmi akan *otomatis dikirimkan ke WhatsApp Dosen* (${course.dosenWa || 'Nomor tercatat'}) dalam waktu *${delayMinutes} menit* ke depan jika Anda sedang sibuk.\n\n👉 *PILIHAN ANDA*:\n• Balas *KIRIM* : Kirimkan sekarang juga ke dosen.\n• Balas *BATAL* : Batalkan pengiriman (misal: dosen sudah izin di grup).\n\n_Sistem Otomasi ILKOM UNAZLAM Hub_`;
}

async function sendDirectWhatsApp(phone, text) {
  if (!sock || currentStatus !== 'WORKING') {
    throw new Error('WhatsApp belum terhubung (status: ' + currentStatus + ')');
  }
  const jid = formatToBaileysJid(phone);
  if (!jid) throw new Error('Nomor telepon tidak valid: ' + phone);

  const sent = await sock.sendMessage(jid, { text });
  console.log(`[WAHA Gateway] Pesan terkirim ke ${jid} (ID: ${sent?.key?.id})`);
  return sent?.key?.id;
}

// =============================================================================
// SMART AUTO-REMINDER CORE WORKFLOW
// =============================================================================
async function triggerReminderFlow(course, scenario) {
  const config = loadAutoReminderConfig();
  if (!config.enabled) return;

  const wib = getWibDate();
  const dateStr = wib.toISOString().split('T')[0];
  const pendingId = `${course.id}_${scenario}_${dateStr}`;

  if (pendingReminders.has(pendingId) || sentHistoryToday.has(pendingId)) {
    console.log(`[WAHA Gateway] Pengingat ${pendingId} sudah pernah diproses.`);
    return;
  }

  const dosenPhone = course.dosenWa;
  if (!dosenPhone) {
    console.log(`[WAHA Gateway] Dosen ${course.dosen} belum memiliki nomor WhatsApp.`);
    return;
  }

  const komtiPhone = config.komtiPhone;
  const delayMs = (config.delayMinutes || 45) * 60 * 1000;
  const scheduledTime = new Date(Date.now() + delayMs);

  console.log(`[WAHA Gateway] 🚀 Menjalankan alur Kombinasi Cerdas untuk: ${course.nama} (${scenario})`);

  // Jika nomor Komti terdaftar, kirim pengingat ke Komti terlebih dahulu!
  if (komtiPhone && komtiPhone.trim().length >= 8) {
    try {
      const promptText = buildKomtiPromptMessage({
        course,
        scenario,
        delayMinutes: config.delayMinutes || 45,
      });
      await sendDirectWhatsApp(komtiPhone, promptText);
      console.log(`[WAHA Gateway] ✅ Prompt verifikasi berhasil dikirim ke Komti (${komtiPhone})`);
    } catch (e) {
      console.error(`[WAHA Gateway] Gagal mengirim prompt ke Komti:`, e);
    }
  }

  // Daftarkan Timer Auto-Send jika Komti tidak membalas / lupa
  const timer = setTimeout(async () => {
    await executeAutoSend(pendingId, 'TIMEOUT');
  }, delayMs);

  pendingReminders.set(pendingId, {
    id: pendingId,
    course,
    scenario,
    komtiPhone,
    dosenPhone,
    senderName: config.komtiName,
    scheduledAt: scheduledTime.toISOString(),
    timer,
  });
}

async function executeAutoSend(pendingId, triggerSource = 'KOMTI') {
  const item = pendingReminders.get(pendingId);
  if (!item) return;

  // Hapus dari pending & batalkan timer jika ada
  if (item.timer) clearTimeout(item.timer);
  pendingReminders.delete(pendingId);
  sentHistoryToday.add(pendingId);

  const { course, scenario, senderName, komtiPhone, dosenPhone } = item;

  try {
    const textDosen = buildAcademicMessage({ course, senderName, scenario });
    await sendDirectWhatsApp(dosenPhone, textDosen);

    logReminderHistory({
      courseId: course.id,
      courseName: course.nama,
      dosen: course.dosen,
      dosenPhone,
      scenario,
      status: 'SENT',
      trigger: triggerSource, // 'KOMTI' | 'TIMEOUT'
    });

    console.log(`[WAHA Gateway] ✅ Pesan resmi berhasil dikirim ke dosen ${course.dosen} (Trigger: ${triggerSource})`);

    // Kirim notifikasi konfirmasi ke Komti
    if (komtiPhone) {
      const notifyKomti = triggerSource === 'TIMEOUT'
        ? `✅ *[AUTO-REMINDER TERKIRIM]*\nWaktu tunggu ${loadAutoReminderConfig().delayMinutes} menit telah selesai. Pesan pengingat resmi perkuliahan *${course.nama}* telah otomatis dikirimkan ke WhatsApp Bapak/Ibu *${course.dosen}*.`
        : `✅ *[TERKIRIM KE DOSEN]*\nPesan pengingat resmi perkuliahan *${course.nama}* telah berhasil dikirimkan ke WhatsApp Bapak/Ibu *${course.dosen}*. Terima kasih!`;
      try {
        await sendDirectWhatsApp(komtiPhone, notifyKomti);
      } catch (_) {}
    }
  } catch (err) {
    console.error(`[WAHA Gateway] Gagal mengirim pesan ke dosen ${course.dosen}:`, err);
    logReminderHistory({
      courseId: course.id,
      courseName: course.nama,
      dosen: course.dosen,
      dosenPhone,
      scenario,
      status: 'FAILED',
      error: err.message,
      trigger: triggerSource,
    });
  }
}

async function cancelAutoSend(pendingId, reason = 'KOMTI_CANCEL') {
  const item = pendingReminders.get(pendingId);
  if (!item) return false;

  if (item.timer) clearTimeout(item.timer);
  pendingReminders.delete(pendingId);
  sentHistoryToday.add(pendingId);

  logReminderHistory({
    courseId: item.course.id,
    courseName: item.course.nama,
    dosen: item.course.dosen,
    scenario: item.scenario,
    status: 'CANCELLED',
    reason,
  });

  console.log(`[WAHA Gateway] 🛑 Pengingat ${pendingId} berhasil dibatalkan oleh Komti.`);

  if (item.komtiPhone) {
    try {
      await sendDirectWhatsApp(
        item.komtiPhone,
        `🛑 *[PENGIRIMAN DIBATALKAN]*\nPengingat perkuliahan *${item.course.nama}* ke dosen *${item.course.dosen}* telah dibatalkan. Tidak ada pesan yang dikirim ke dosen.`
      );
    } catch (_) {}
  }
  return true;
}

// Handler balasan interaktif pesan masuk WhatsApp dari Komti
async function handleIncomingKomtiReply(senderJid, text) {
  const config = loadAutoReminderConfig();
  const cleanSender = senderJid.replace(/[^0-9]/g, '');
  const cleanKomti = (config.komtiPhone || '').replace(/[^0-9]/g, '');

  // Cek apakah pesan berasal dari Komti
  if (!cleanKomti || !cleanSender.endsWith(cleanKomti)) {
    return;
  }

  const upper = text.toUpperCase().trim();

  // Ambil pending reminder paling relevan / terakhir
  const pendingKeys = Array.from(pendingReminders.keys());
  if (pendingKeys.length === 0) {
    if (upper === 'STATUS') {
      await sendDirectWhatsApp(
        senderJid,
        `📊 *STATUS AUTO-REMINDER ILKOM UNAZLAM*\n• Mode: Kombinasi Cerdas (Aktif)\n• Antrean: Tidak ada pengingat yang sedang menunggu konfirmasi saat ini.`
      );
    }
    return;
  }

  const latestKey = pendingKeys[pendingKeys.length - 1];

  if (upper === 'KIRIM' || upper === '1' || upper === 'YA' || upper === 'YES') {
    await executeAutoSend(latestKey, 'KOMTI');
  } else if (upper === 'BATAL' || upper === '2' || upper === 'CANCEL') {
    await cancelAutoSend(latestKey, 'KOMTI_COMMAND');
  } else if (upper === 'STATUS') {
    const item = pendingReminders.get(latestKey);
    await sendDirectWhatsApp(
      senderJid,
      `📊 *STATUS ANTREAN PENGINGAT*\n• Mata Kuliah: ${item.course.nama}\n• Dosen: ${item.course.dosen}\n• Jadwal Kirim Otomatis: ${item.scheduledAt}\n\nBalas *KIRIM* untuk langsung kirim atau *BATAL* untuk membatalkan.`
    );
  }
}

// =============================================================================
// SCHEDULER: RUNS EVERY 60 SECONDS
// =============================================================================
const DAY_NAMES = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

function checkScheduledReminders() {
  const config = loadAutoReminderConfig();
  if (!config.enabled) return;

  const wib = getWibDate();
  const hours = String(wib.getHours()).padStart(2, '0');
  const minutes = String(wib.getMinutes()).padStart(2, '0');
  const currentTime = `${hours}:${minutes}`;

  const courses = loadCoursesCache();
  if (courses.length === 0) return;

  const todayIndex = wib.getDay();
  const todayName = DAY_NAMES[todayIndex];
  const tomorrowIndex = (todayIndex + 1) % 7;
  const tomorrowName = DAY_NAMES[tomorrowIndex];

  // 1. Cek Jadwal H-1 (Esok Hari)
  if (currentTime === config.hMinusOneHour) {
    const tomorrowCourses = courses.filter((c) => {
      const h = (c.hari || '').trim().toLowerCase();
      return h === tomorrowName.toLowerCase() && !c.isCancelledToday;
    });

    for (const c of tomorrowCourses) {
      triggerReminderFlow(c, 'H-1');
    }
  }

  // 2. Cek Jadwal Hari-H (Hari Ini)
  if (currentTime === config.todayHour) {
    const todayCourses = courses.filter((c) => {
      const h = (c.hari || '').trim().toLowerCase();
      return h === todayName.toLowerCase() && !c.isCancelledToday;
    });

    for (const c of todayCourses) {
      triggerReminderFlow(c, 'Hari-H');
    }
  }
}

// Inisialisasi loop background setiap 60 detik
setInterval(checkScheduledReminders, 60000);

// =============================================================================
// BAILEYS WHATSAPP CLIENT INITIALIZATION
// =============================================================================
async function initWhatsAppSession() {
  if (isStarting) return;
  isStarting = true;
  currentStatus = 'STARTING';
  currentQrRaw = null;
  currentQrBuffer = null;

  try {
    const sessionPath = path.join(SESSIONS_DIR, 'default');
    if (!fs.existsSync(sessionPath)) {
      fs.mkdirSync(sessionPath, { recursive: true });
    }

    const { state, saveCreds } = await useMultiFileAuthState(sessionPath);
    const { version, isLatest } = await fetchLatestBaileysVersion();
    console.log(`[WAHA Gateway] Memulai WhatsApp Web version: v${version.join('.')}, isLatest: ${isLatest}`);

    sock = makeWASocket({
      version,
      auth: state,
      logger,
      printQRInTerminal: false,
      browser: ['ILKOM UNAZLAM Hub', 'Chrome', '1.0.0'],
      connectTimeoutMs: 60000,
      defaultQueryTimeoutMs: 60000,
      keepAliveIntervalMs: 10000,
    });

    sock.ev.on('creds.update', saveCreds);

    // Tangkap pesan masuk WhatsApp (untuk interaksi konfirmasi Komti)
    sock.ev.on('messages.upsert', async ({ messages, type }) => {
      try {
        if (type !== 'notify') return;
        for (const m of messages) {
          if (m.key.fromMe) continue;
          const senderJid = m.key.remoteJid;
          const text = (m.message?.conversation || m.message?.extendedTextMessage?.text || '').trim();
          if (!text) continue;
          await handleIncomingKomtiReply(senderJid, text);
        }
      } catch (upsertErr) {
        console.error('[WAHA Gateway] Error processing incoming message:', upsertErr);
      }
    });

    sock.ev.on('connection.update', async (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        currentQrRaw = qr;
        try {
          currentQrBuffer = await QRCode.toBuffer(qr, {
            type: 'png',
            width: 320,
            margin: 2,
            color: { dark: '#0F172A', light: '#FFFFFF' },
          });
          currentStatus = 'SCAN_QR_CODE';
        } catch (qrErr) {
          console.error('[WAHA Gateway] Gagal membuat buffer QR:', qrErr);
        }
      }

      if (connection === 'open') {
        currentStatus = 'WORKING';
        currentQrRaw = null;
        currentQrBuffer = null;
        const user = sock.user;
        accountInfo = {
          id: user?.id || 'Connected Account',
          pushName: user?.name || user?.notify || 'Admin ILKOM UNAZLAM',
        };
        console.log(`[WAHA Gateway] ✅ BERHASIL TERHUBUNG ke WhatsApp: ${accountInfo.id} (${accountInfo.pushName})`);
      } else if (connection === 'close') {
        const statusCode = lastDisconnect?.error?.output?.statusCode;
        const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
        console.log(`[WAHA Gateway] ⚠️ Koneksi ditutup (code: ${statusCode}). Mencoba hubungkan ulang: ${shouldReconnect}`);

        if (statusCode === DisconnectReason.loggedOut) {
          currentStatus = 'STOPPED';
          accountInfo = null;
          currentQrRaw = null;
          currentQrBuffer = null;
          try {
            fs.rmSync(sessionPath, { recursive: true, force: true });
          } catch (_) {}
        } else {
          currentStatus = 'STARTING';
          setTimeout(() => {
            isStarting = false;
            initWhatsAppSession();
          }, 3000);
        }
      }
    });

    isStarting = false;
  } catch (err) {
    console.error('[WAHA Gateway] Error menginisialisasi Baileys:', err);
    currentStatus = 'FAILED';
    isStarting = false;
  }
}

// =============================================================================
// WAHA REST API ENDPOINTS
// =============================================================================

// 1. Status Sesi: GET /api/sessions/:session atau GET /api/sessions
app.get(['/api/sessions', '/api/sessions/:session'], (req, res) => {
  const sessionName = req.params.session || 'default';
  res.json({
    name: sessionName,
    status: currentStatus,
    me: currentStatus === 'WORKING' && accountInfo ? accountInfo : null,
    engine: 'BAILEYS_NATIVE',
  });
});

// 2. Mulai Sesi: POST /api/sessions/start atau POST /api/sessions/:session/start atau POST /api/sessions
app.post(['/api/sessions/start', '/api/sessions/:session/start', '/api/sessions'], async (req, res) => {
  if (currentStatus !== 'WORKING' && currentStatus !== 'STARTING' && currentStatus !== 'SCAN_QR_CODE') {
    initWhatsAppSession();
  }
  res.status(200).json({
    status: currentStatus,
    message: 'Engine WhatsApp sedang diinisialisasi.',
  });
});

// 3. Hentikan Sesi: POST /api/sessions/stop atau POST /api/sessions/:session/stop
app.post(['/api/sessions/stop', '/api/sessions/:session/stop'], async (req, res) => {
  try {
    if (sock) {
      sock.end(undefined);
    }
  } catch (_) {}
  currentStatus = 'STOPPED';
  currentQrRaw = null;
  currentQrBuffer = null;
  res.status(200).json({ status: 'STOPPED' });
});

// 4. Logout Sesi: POST /api/sessions/logout atau POST /api/sessions/:session/logout
app.post(['/api/sessions/logout', '/api/sessions/:session/logout'], async (req, res) => {
  try {
    if (sock) {
      await sock.logout();
    }
  } catch (_) {}
  const sessionPath = path.join(SESSIONS_DIR, 'default');
  try {
    fs.rmSync(sessionPath, { recursive: true, force: true });
  } catch (_) {}
  currentStatus = 'STOPPED';
  accountInfo = null;
  currentQrRaw = null;
  currentQrBuffer = null;
  res.status(200).json({ status: 'STOPPED', message: 'Sesi berhasil logout.' });
});

// 5. Ambil Gambar QR Code: GET /api/:session/auth/qr
app.get('/api/:session/auth/qr', (req, res) => {
  if (currentQrBuffer && currentStatus === 'SCAN_QR_CODE') {
    res.setHeader('Content-Type', 'image/png');
    return res.send(currentQrBuffer);
  }
  if (currentStatus === 'WORKING') {
    return res.status(204).end();
  }
  res.status(404).json({ error: 'Kode QR tidak tersedia atau sesi sudah terhubung.' });
});

// 6. Kirim Pesan Teks: POST /api/sendText
app.post('/api/sendText', async (req, res) => {
  const { chatId, text } = req.body;

  if (!sock || currentStatus !== 'WORKING') {
    return res.status(503).json({
      error: 'WhatsApp belum terhubung. Silakan scan QR code terlebih dahulu di aplikasi.',
    });
  }

  if (!chatId || !text) {
    return res.status(400).json({
      error: 'Parameter chatId dan text wajib diisi.',
    });
  }

  try {
    const id = await sendDirectWhatsApp(chatId, text);
    res.status(200).json({
      id,
      timestamp: Date.now(),
      status: 'delivered',
    });
  } catch (err) {
    console.error(`[WAHA Gateway] Gagal mengirim pesan ke ${chatId}:`, err);
    res.status(500).json({
      error: `Gagal mengirim pesan: ${err.message || err}`,
    });
  }
});

// =============================================================================
// AUTO-REMINDER REST API ENDPOINTS
// =============================================================================

// Ambil Konfigurasi Pengingat Otomatis
app.get('/api/auto-reminder/config', (req, res) => {
  const config = loadAutoReminderConfig();
  const pendingList = Array.from(pendingReminders.values()).map((p) => ({
    id: p.id,
    courseName: p.course.nama,
    lecturerName: p.course.dosen,
    scenario: p.scenario,
    scheduledAt: p.scheduledAt,
  }));

  res.json({
    config,
    pendingReminders: pendingList,
    pendingCount: pendingList.length,
  });
});

// Simpan Konfigurasi Pengingat Otomatis
app.post('/api/auto-reminder/config', (req, res) => {
  const current = loadAutoReminderConfig();
  const updated = {
    ...current,
    ...req.body,
  };
  saveAutoReminderConfig(updated);
  res.json({ success: true, config: updated });
});

// Sinkronkan Data Jadwal Mata Kuliah dari Aplikasi Flutter
app.post('/api/auto-reminder/sync-courses', (req, res) => {
  const { courses, komtiPhone, komtiName } = req.body;
  if (Array.isArray(courses)) {
    saveCoursesCache(courses);
  }
  if (komtiPhone) {
    const config = loadAutoReminderConfig();
    config.komtiPhone = komtiPhone;
    if (komtiName) config.komtiName = komtiName;
    saveAutoReminderConfig(config);
  }
  res.json({ success: true, totalCourses: (courses || []).length });
});

// Simulasi Uji Coba Pengingat Sekarang (Trigger Test)
app.post('/api/auto-reminder/trigger-test', async (req, res) => {
  const courses = loadCoursesCache();
  if (courses.length === 0) {
    return res.status(400).json({
      error: 'Belum ada data mata kuliah yang tersinkronisasi. Buka aplikasi untuk sinkronisasi jadwal.',
    });
  }

  const course = courses[0]; // Ambil mata kuliah pertama sebagai sampel uji coba
  await triggerReminderFlow(course, 'Hari-H');

  res.json({
    success: true,
    message: `Simulasi pengingat Kombinasi Cerdas telah dipicu untuk mata kuliah "${course.nama}". Pesan verifikasi dikirimkan ke WhatsApp Komti.`,
    course: course.nama,
  });
});

// Ambil Riwayat Pengingat
app.get('/api/auto-reminder/history', (req, res) => {
  try {
    if (fs.existsSync(HISTORY_FILE)) {
      const history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf8'));
      return res.json(history);
    }
  } catch (_) {}
  res.json([]);
});

// Info Server: GET /api/server/version
app.get('/api/server/version', (req, res) => {
  res.json({
    version: '2026.2.0',
    engine: 'BAILEYS_NATIVE',
    status: currentStatus,
    timestamp: new Date().toISOString(),
  });
});

// Tampilan Halaman Web (http://localhost:3000/)
app.get('/', (req, res) => {
  const isConnected = currentStatus === 'WORKING';
  const config = loadAutoReminderConfig();
  const qrHtml = currentQrRaw
    ? `<div style="margin:20px 0; background:white; padding:16px; display:inline-block; border-radius:16px; box-shadow:0 4px 14px rgba(0,0,0,0.08); border:2px solid #E2E8F0;">
         <img src="/api/default/auth/qr" alt="QR Code" style="width:260px;height:260px;display:block;" />
         <p style="margin-top:10px; font-weight:700; color:#0F172A; font-size:13px;">Pindai dengan WhatsApp di HP</p>
       </div>`
    : (isConnected
        ? `<div style="padding:16px; background:#DCFCE7; color:#15803D; border-radius:12px; font-weight:700; display:inline-block; margin:20px 0;">
             ✅ WhatsApp Aktif: ${accountInfo?.id || 'Connected'} (${accountInfo?.pushName || 'Admin'})
           </div>`
        : `<div style="padding:16px; background:#F1F5F9; color:#475569; border-radius:12px; display:inline-block; margin:20px 0;">
             Status: <strong>${currentStatus}</strong>. Klik tombol "Mulai Sesi" di aplikasi Flutter atau klik <a href="/api/sessions/start" style="color:#059669; font-weight:700;">di sini</a>.
           </div>`);

  res.send(`
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>ILKOM UNAZLAM - WhatsApp Gateway</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0F172A; color: #F8FAFC; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; }
    .card { background: #1E293B; border: 1px solid #334155; border-radius: 24px; padding: 36px; max-width: 540px; width: 100%; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.3); }
    h1 { font-size: 22px; font-weight: 800; margin: 0 0 6px 0; color: #FFFFFF; }
    p { font-size: 13px; color: #94A3B8; margin: 0 0 16px 0; line-height: 1.5; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 999px; font-size: 11px; font-weight: 800; background: #059669; color: white; margin-bottom: 18px; }
    .feature-box { background: #0F172A; border-radius: 14px; padding: 14px; margin-top: 18px; text-align: left; font-size: 12px; border: 1px solid #334155; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">WAHA REST API PORT: ${PORT}</div>
    <h1>ILKOM UNAZLAM WhatsApp Gateway</h1>
    <p>Server Gateway aktif melayani broadcast, warta pengumuman, dan otomatisasi pengingat dosen.</p>
    ${qrHtml}
    <div class="feature-box">
      <div style="font-weight: 700; color: #38BDF8; margin-bottom: 6px;">🤖 Mode Kombinasi Cerdas Aktif</div>
      <div>• Pengingat ke Komti: <strong>${config.komtiPhone || 'Belum diatur'}</strong></div>
      <div>• Waktu Tunggu Auto-Send: <strong>${config.delayMinutes} menit</strong></div>
      <div>• Jadwal H-1: <strong>${config.hMinusOneHour} WIB</strong> | Hari-H: <strong>${config.todayHour} WIB</strong></div>
    </div>
  </div>
</body>
</html>
  `);
});

// Mulai Server
app.listen(PORT, () => {
  console.log(`\n=============================================================`);
  console.log(`  🚀 ILKOM UNAZLAM WhatsApp Gateway Aktif di Port ${PORT}`);
  console.log(`  🌐 URL Server: http://localhost:${PORT}`);
  console.log(`  🤖 Mode: Smart Auto-Reminder Scheduler Aktif!`);
  console.log(`=============================================================\n`);

  initWhatsAppSession();
});
