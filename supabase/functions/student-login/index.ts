import { createClient } from 'npm:@supabase/supabase-js@2';

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

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'Metode tidak didukung.' });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY') ??
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY');
  const secretKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SUPABASE_SECRET_KEY');
  if (!supabaseUrl || !publishableKey || !secretKey) {
    return jsonResponse(500, { error: 'Konfigurasi fungsi belum lengkap.' });
  }

  // This endpoint is public so the API gateway can accept unauthenticated login
  // requests. Require the project's public API key and keep credentials private.
  if (request.headers.get('apikey') !== publishableKey) {
    return jsonResponse(401, { error: 'Permintaan login tidak valid.' });
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse(400, { error: 'Format data login tidak valid.' });
  }
  if (payload === null || typeof payload !== 'object' || Array.isArray(payload)) {
    return jsonResponse(400, { error: 'Format data login tidak valid.' });
  }

  const body = payload as Record<string, unknown>;
  const nim = typeof body.nim === 'string' ? body.nim.trim() : '';
  const password = typeof body.password === 'string' ? body.password : '';
  if (!/^\d{6,20}$/.test(nim) || password.length < 1 || password.length > 128) {
    return jsonResponse(401, { error: 'NIM atau kata sandi salah, atau akun belum aktif.' });
  }

  const adminClient = createClient(supabaseUrl, secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const loginClient = createClient(supabaseUrl, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: student, error: studentError } = await adminClient
    .from('students')
    .select('email, auth_user_id')
    .eq('nim', nim)
    .eq('is_aktif', true)
    .maybeSingle();
  if (studentError || !student?.email || !student.auth_user_id) {
    return jsonResponse(401, { error: 'NIM atau kata sandi salah, atau akun belum aktif.' });
  }

  const { data, error } = await loginClient.auth.signInWithPassword({
    email: student.email,
    password,
  });
  if (error || !data.user || !data.session || data.user.id !== student.auth_user_id) {
    return jsonResponse(401, { error: 'NIM atau kata sandi salah, atau akun belum aktif.' });
  }

  // Do not return the email or profile mapping to the client.
  return jsonResponse(200, { refresh_token: data.session.refresh_token });
});
