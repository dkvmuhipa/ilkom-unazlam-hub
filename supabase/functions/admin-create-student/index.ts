import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function readString(value: unknown, maxLength: number): string | null {
  if (typeof value !== 'string') return null;
  const result = value.trim();
  return result.length > 0 && result.length <= maxLength ? result : null;
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'Metode tidak didukung.' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const publishableKey =
    Deno.env.get('SUPABASE_ANON_KEY') ??
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY');
  const secretKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SUPABASE_SECRET_KEY');
  if (!supabaseUrl || !publishableKey || !secretKey) {
    return jsonResponse(500, { error: 'Konfigurasi fungsi belum lengkap.' });
  }

  const authorization = request.headers.get('Authorization') ?? '';
  const accessToken = authorization.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) {
    return jsonResponse(401, { error: 'Sesi login diperlukan.' });
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const adminClient = createClient(supabaseUrl, secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: userData, error: userError } =
    await userClient.auth.getUser(accessToken);
  if (userError || !userData.user) {
    return jsonResponse(401, { error: 'Sesi login tidak valid.' });
  }

  const { data: adminProfile, error: profileError } = await adminClient
    .from('students')
    .select('role, is_aktif')
    .eq('auth_user_id', userData.user.id)
    .maybeSingle();
  if (
    profileError ||
    !adminProfile ||
    !adminProfile.is_aktif ||
    String(adminProfile.role).toUpperCase() !== 'ADMIN'
  ) {
    return jsonResponse(403, { error: 'Hanya admin aktif yang dapat membuat akun.' });
  }

  let body: Record<string, unknown>;
  try {
    const parsed: unknown = await request.json();
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
      return jsonResponse(400, { error: 'Data akun tidak valid.' });
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return jsonResponse(400, { error: 'Format data tidak valid.' });
  }

  const nama = readString(body.nama, 120);
  const nim = readString(body.nim, 20);
  const email = readString(body.email, 254)?.toLowerCase() ?? null;
  const initialPassword =
    typeof body.initial_password === 'string' ? body.initial_password : '';
  const noWa = typeof body.no_wa === 'string' ? body.no_wa.trim() : '';
  const peminatan =
    typeof body.peminatan === 'string' ? body.peminatan.trim() : '';
  const semester = Number(body.semester);

  if (
    !nama ||
    !nim ||
    !/^\d{6,20}$/.test(nim) ||
    !email ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
    initialPassword.length < 8 ||
    initialPassword.length > 128 ||
    noWa.length > 32 ||
    peminatan.length > 80 ||
    !Number.isInteger(semester) ||
    semester < 1 ||
    semester > 8
  ) {
    return jsonResponse(400, { error: 'Periksa kembali data akun yang dimasukkan.' });
  }

  const { data: duplicateNim, error: nimLookupError } = await adminClient
    .from('students')
    .select('id')
    .eq('nim', nim)
    .maybeSingle();
  if (nimLookupError) {
    return jsonResponse(500, { error: 'Data mahasiswa belum dapat diperiksa.' });
  }
  if (duplicateNim) {
    return jsonResponse(409, { error: 'NIM tersebut sudah terdaftar.' });
  }

  const { data: duplicateEmail, error: emailLookupError } = await adminClient
    .from('students')
    .select('id')
    .ilike('email', email)
    .maybeSingle();
  if (emailLookupError) {
    return jsonResponse(500, { error: 'Data email belum dapat diperiksa.' });
  }
  if (duplicateEmail) {
    return jsonResponse(409, { error: 'Email tersebut sudah terdaftar.' });
  }

  const { error: insertError } = await adminClient.from('students').insert({
    id: nim,
    nim,
    nama,
    email,
    no_wa: noWa,
    peminatan,
    prodi: 'Ilmu Komunikasi',
    semester,
    kelas: 'Ilmu Komunikasi',
    role: 'MAHASISWA',
    jabatan: 'Mahasiswa',
    is_aktif: true,
  });
  if (insertError) {
    return jsonResponse(409, { error: 'Profil mahasiswa gagal dibuat. Periksa NIM.' });
  }

  const { data: invited, error: inviteError } = await adminClient.auth.admin
    .inviteUserByEmail(email, {
      data: { nama, nim },
    });
  if (inviteError || !invited.user) {
    const { error: cleanupError } = await adminClient
      .from('students')
      .delete()
      .eq('nim', nim);
    if (cleanupError) {
      return jsonResponse(500, {
        error: 'Undangan gagal dikirim dan profil sementara gagal dibersihkan. Hubungi administrator untuk menghapus profil tersebut sebelum mencoba lagi.',
      });
    }
    return jsonResponse(502, {
      error: 'Undangan email gagal dikirim. Profil sementara sudah dibersihkan; silakan coba lagi.',
    });
  }

  const { error: passwordError } = await adminClient.auth.admin.updateUserById(
    invited.user.id,
    { password: initialPassword },
  );
  if (passwordError) {
    const { error: authCleanupError } = await adminClient.auth.admin.deleteUser(
      invited.user.id,
    );
    const { error: profileCleanupError } = await adminClient
      .from('students')
      .delete()
      .eq('nim', nim);
    if (authCleanupError || profileCleanupError) {
      return jsonResponse(500, {
        error: 'Kata sandi awal gagal disetel dan pembersihan akun tidak tuntas. Hubungi administrator untuk memeriksa pengguna Auth dan profil mahasiswa.',
      });
    }
    return jsonResponse(500, {
      error: 'Kata sandi awal gagal disetel. Akun sementara sudah dibersihkan; silakan coba lagi.',
    });
  }

  const { error: linkError } = await adminClient
    .from('students')
    .update({ auth_user_id: invited.user.id })
    .eq('nim', nim);
  if (linkError) {
    const { error: authCleanupError } = await adminClient.auth.admin.deleteUser(
      invited.user.id,
    );
    const { error: profileCleanupError } = await adminClient
      .from('students')
      .delete()
      .eq('nim', nim);
    if (authCleanupError || profileCleanupError) {
      return jsonResponse(500, {
        error: 'Profil gagal ditautkan dan pembersihan akun tidak tuntas. Hubungi administrator untuk memeriksa pengguna Auth dan profil mahasiswa sebelum mencoba lagi.',
      });
    }
    return jsonResponse(500, {
      error: 'Profil gagal ditautkan. Akun dan profil sementara sudah dibersihkan; silakan coba lagi.',
    });
  }

  return jsonResponse(201, {
    ok: true,
    message: 'Akun mahasiswa dibuat dan undangan email dikirim.',
  });
});
