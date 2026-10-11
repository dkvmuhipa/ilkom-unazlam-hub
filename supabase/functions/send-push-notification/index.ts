import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Dapatkan OAuth2 Access Token dari Firebase Service Account JSON (FCM HTTP v1)
async function getGoogleAccessToken(serviceAccountJson: string): Promise<{ accessToken: string; projectId: string }> {
  const sa = JSON.parse(serviceAccountJson);
  const jwtClient = new JWT({
    email: sa.client_email,
    key: sa.private_key,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });

  const tokens = await jwtClient.authorize();
  if (!tokens.access_token) {
    throw new Error('Gagal mendapatkan access token dari Google OAuth2');
  }

  return {
    accessToken: tokens.access_token,
    projectId: sa.project_id,
  };
}

// Kirim notifikasi menggunakan FCM HTTP v1 API (Resmi & Modern)
async function sendFcmV1(
  projectId: string,
  accessToken: string,
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
) {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const results = { success: 0, failure: 0, errors: [] as string[] };

  for (const token of tokens) {
    try {
      const payload = {
        message: {
          token,
          notification: {
            title,
            body,
          },
          data: data ?? {},
          android: {
            priority: 'HIGH',
            notification: {
              channel_id: 'high_importance_channel',
              sound: 'default',
            },
          },
        },
      };

      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        results.success++;
      } else {
        results.failure++;
        const errJson = await res.text();
        results.errors.push(`Token ${token.substring(0, 10)}...: ${errJson}`);
      }
    } catch (e: unknown) {
      results.failure++;
      results.errors.push(`Token error: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  return results;
}

// Fallback jika masih menggunakan FCM Legacy Server Key
async function sendFcmLegacy(fcmServerKey: string, tokens: string[], title: string, body: string, data?: Record<string, string>) {
  if (tokens.length === 0) return { success: 0, failure: 0 };

  const url = 'https://fcm.googleapis.com/fcm/send';
  const payload = {
    registration_ids: tokens,
    notification: {
      title,
      body,
      sound: 'default',
      android_channel_id: 'high_importance_channel',
    },
    data: data ?? {},
    priority: 'high',
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `key=${fcmServerKey}`,
    },
    body: JSON.stringify(payload),
  });

  return await response.json();
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SECRET_KEY');
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');

  if (!supabaseUrl || !secretKey) {
    return jsonResponse(500, { error: 'Konfigurasi Supabase belum lengkap.' });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, { error: 'Format JSON payload tidak valid.' });
  }

  const record = (payload.record ?? payload) as Record<string, unknown>;
  const table = (payload.table ?? 'announcements') as string;

  let title = 'Notifikasi Kelas ILKOM UNAZLAM';
  let body = 'Ada pembaruan informasi akademik terbaru.';
  const dataPayload: Record<string, string> = {
    table,
    timestamp: new Date().toISOString(),
  };

  // Format pesan ramah dan informatif berdasarkan event tabel
  if (table === 'announcements') {
    const judul = typeof record.judul === 'string' ? record.judul : 'Pengumuman Baru';
    const isi = typeof record.isi === 'string' ? record.isi : '';
    title = `📢 Pengumuman: ${judul}`;
    body = isi.length > 90 ? `${isi.substring(0, 90)}...` : (isi || 'Pengumuman baru telah diterbitkan.');
    dataPayload.targetTab = '7'; // Navigasi langsung ke Tab Pengumuman
  } else if (table === 'assignments') {
    const judul = typeof record.judul === 'string' ? record.judul : 'Tugas Baru';
    const course = typeof record.mata_kuliah === 'string' ? record.mata_kuliah : '';
    title = `📝 Tugas Baru: ${judul}`;
    body = course ? `Mata Kuliah: ${course}` : 'Segera periksa rincian tugas dan tenggat waktu.';
    dataPayload.targetTab = '2'; // Navigasi langsung ke Tab Tugas
  } else if (table === 'attendance_sessions') {
    const course = typeof record.course_name === 'string' ? record.course_name : 'Mata Kuliah';
    title = `⚡ Presensi Dibuka: ${course}`;
    body = 'Sesi presensi aktif! Buka aplikasi dan konfirmasi kehadiran sekarang.';
    dataPayload.targetTab = '5'; // Navigasi langsung ke Tab Presensi
  }

  // Ambil semua token perangkat mahasiswa aktif dari user_push_tokens
  const adminClient = createClient(supabaseUrl, secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: tokenRows, error: tokenError } = await adminClient
    .from('user_push_tokens')
    .select('token');

  if (tokenError) {
    return jsonResponse(500, { error: 'Gagal mengambil token pengguna:', detail: tokenError.message });
  }

  const tokens = (tokenRows ?? []).map((row) => row.token).filter((t): t is string => typeof t === 'string' && t.length > 0);

  if (tokens.length === 0) {
    return jsonResponse(200, { message: 'Belum ada perangkat mahasiswa terdaftar.', sent: 0 });
  }

  // 1. Prioritaskan FCM HTTP v1 menggunakan FIREBASE_SERVICE_ACCOUNT
  if (serviceAccountJson) {
    try {
      const { accessToken, projectId } = await getGoogleAccessToken(serviceAccountJson);
      const v1Result = await sendFcmV1(projectId, accessToken, tokens, title, body, dataPayload);
      return jsonResponse(200, {
        success: true,
        protocol: 'FCM_HTTP_V1',
        recipients: tokens.length,
        result: v1Result,
      });
    } catch (e: unknown) {
      return jsonResponse(500, {
        error: 'Gagal mengirim melalui FCM v1 Service Account',
        detail: e instanceof Error ? e.message : String(e),
      });
    }
  }

  // 2. Fallback jika masih menggunakan FCM Legacy Server Key
  if (fcmServerKey) {
    const legacyResult = await sendFcmLegacy(fcmServerKey, tokens, title, body, dataPayload);
    return jsonResponse(200, {
      success: true,
      protocol: 'FCM_LEGACY',
      recipients: tokens.length,
      result: legacyResult,
    });
  }

  return jsonResponse(200, {
    message: 'FIREBASE_SERVICE_ACCOUNT belum diset di Supabase Secrets. Notifikasi siap begitu secret ditambahkan.',
    targetDevices: tokens.length,
    sampleNotification: { title, body },
  });
});
