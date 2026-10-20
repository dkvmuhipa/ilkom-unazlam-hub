# Security Policy & Audit Report (OWASP Standards)

**Application**: ILKOM UNAZLAM Hub (Platform Manajemen Akademik & Kelas Terpadu)  
**Latest Audit Date**: 2026-10-20 (Audit Keamanan Menyeluruh: Persistent Reminder Gateway, Student Groups RLS Hardening, Religion-Based Course Filtering, & Real Admin Identity Audit Trail)  
**Audit Scope**: Codebase Flutter (`lib/`), Gateway WhatsApp (`waha_gateway/`), Persistent Reminder Service (`reminder_service/`), Supabase Migrations (`supabase_migrations/`), Supabase Edge Functions (`supabase/functions/`), dan Dependensi Pihak Ketiga (`pubspec.yaml`, `package.json`).  
**Audit Standards**: OWASP Top 10 (2021) & Mobile/API Security Best Practices  

---

## 1. Ringkasan Eksekutif (Executive Summary)

Audit keamanan komprehensif (*Paranoid Mode*) telah dilaksanakan kembali pada **20 Oktober 2026** menyusul penambahan modul **Persistent Reminder Gateway (`reminder_service`)**, isolasi ketat **Student Groups Membership-Scoped RPC**, penyaringan mata kuliah berbasis preferensi agama (`agama`), serta penguatan integritas **Audit Trail Identitas Administrator Asli**.

### Rangkuman Status Keamanan:
- 🟢 **0 Kredensial Bocor (Zero Secrets Leakage)**: Tidak ada *service_role key*, token rahasia, atau kredensial database privat yang tersimpan di repositori Git. Kunci Supabase di aplikasi klien beroperasi menggunakan `role: anon` publik. Seluruh file sensitif (`.env`, `*.env`, `waha_gateway/sessions/`, `android/key.properties`, `google-services.json`) terlindungi 100% dalam `.gitignore`.
- 🟢 **0 Vulnerabilities Dependensi (Rantai Pasok Bersih)**: 
  - `waha_gateway`: `npm audit` menunjukkan **0 vulnerabilities**.
  - `reminder_service`: Dibangun menggunakan runtime murni Node.js 22 (`node:http`, `node:crypto`, `node:test`) dengan **0 dependensi pihak ketiga**, mengeliminasi 100% risiko rantai pasok (*zero supply-chain risk*).
  - Flutter: Seluruh dependensi pada `pubspec.yaml` berada dalam rentang versi stabil terverifikasi.
- 🟢 **Perlindungan Injeksi & Hijacking Search-Path**: 100% kueri database pada Flutter menggunakan PostgREST query builder terparameterisasi. Seluruh fungsi PL/pgSQL database menggunakan pola `SECURITY DEFINER SET search_path = ''` atau `SECURITY INVOKER SET search_path = public` guna meniadakan eksploitasi search-path hijacking.
- 🟢 **Penegakan Kontrol Akses (Broken Access Control & IDOR)**:
  - Hak `INSERT`, `UPDATE`, `DELETE` ditarik total dari peran `anon` pada skema publik.
  - Tabel kelompok belajar (`student_groups`, `student_group_members`) ditarik hak akses langsungnya dari `PUBLIC`, `anon`, dan `authenticated`; akses hanya dibuka melalui RPC `get_student_groups()` yang membatasi hak baca secara ketat hanya untuk anggota kelompok bersangkutan atau pengurus kelas/admin.
  - Perubahan profil mahasiswa dibatasi hanya untuk pemilik akun (`nim = current_student_nim()` atau `auth_user_id = auth.uid()`) dan dilindungi trigger anti-eskalasi peran `trg_prevent_privilege_escalation`.
- 🟢 **Otentikasi & Mitigasi Timing Attack**:
  - `reminder_service` menggunakan fungsi `timingSafeEqual` dari `node:crypto` untuk verifikasi `GATEWAY_API_KEY` dan `WEBHOOK_SECRET`, mencegah timing attack.
  - Endpoint dibatasi payload maksimum 1MB untuk mitigasi DoS.
  - Komunikasi ke WAHA Gateway dikunci menggunakan whitelisting endpoint ketat (*reverse proxy whitelist*) guna mencegah Server-Side Request Forgery (SSRF).
- 🟢 **Audit Trail & Akuntabilitas**:
  - `AdminAuditService` mencatat setiap aksi mutasi administratif ke tabel `audit_logs` dengan identitas asli admin (`16110376` / `Admin Program Studi`), mencegah pemalsuan jejak audit.

---

## 2. Matriks Evaluasi OWASP Top 10 (2021)

| Kategori OWASP | Komponen & Fitur | Tingkat Risiko | Status Audit | Catatan & Mitigasi |
| :--- | :--- | :---: | :---: | :--- |
| **A01: Broken Access Control** | Penegakan RLS pada tabel master data, profil, dan kelompok belajar. | Rendah | 🟢 **Lolos (Aman - Smart RLS & RPC Scoping)** | Seluruh mutasi `anon` dicabut. Tabel `student_groups` sepenuhnya terisolasi via RPC dengan verifikasi keanggotaan NIM mahasiswa. Profil dilindungi trigger `trg_prevent_privilege_escalation`. |
| **A01: Broken Access Control** | Otorisasi Gateway WAHA & Auto-Reminder Service. | Rendah | 🟢 **Lolos (Aman)** | Verifikasi nomor pengirim Komti (`senderJid.endsWith(komtiPhone)`) dan kode konfirmasi 4-digit unik untuk setiap jadwal. Header `X-Api-Key` dan `X-Webhook-Secret` diverifikasi dengan `timingSafeEqual`. |
| **A02: Cryptographic Failures**| Penyimpanan kata sandi & token sesi WhatsApp. | Rendah | 🟢 **Lolos (Aman)** | Plaintext dieliminasi 100%. Digantikan Salted SHA-256 (`crypto: ^3.0.7`). Token sesi Baileys disimpan di folder lokal terisolasi yang diabaikan oleh Git. |
| **A03: Injection** | Injeksi filter PostgREST atau kueri database PostgreSQL. | Rendah | 🟢 **Lolos (Aman)** | Semua parameter kueri di-bind aman via client SDK. Seluruh fungsi database menggunakan `search_path = ''` atau `search_path = public`. |
| **A04: Insecure Design** | Alur otomatisasi pengingat dosen, voting, dan simulasi. | Rendah | 🟢 **Lolos (Aman)** | Fitur simulasi pengingat dijamin secara deterministik tidak pernah mengirimkan pesan ke dosen nyata. Voting dilindungi pencegahan suara ganda per-NIM (`UNIQUE(poll_id, voter_nim)`). |
| **A05: Security Misconfiguration**| Konfigurasi CORS, Secrets, dan Service Role Keys. | Rendah | 🟢 **Lolos (Aman)** | Service role key hanya diakses di sisi server (`Deno.env` atau server environment), tidak pernah dimasukkan ke bundle klien Flutter. Gateway reverse proxy hanya meloloskan endpoint terdaftar. |
| **A06: Vulnerable Components** | Audit dependensi (`pubspec.yaml`, `waha_gateway/`, `reminder_service/`). | Rendah | 🟢 **Lolos (Aman)** | `npm audit` menunjukkan 0 vulnerabilities. `reminder_service` menggunakan 0 dependensi eksternal (100% native Node.js 22). |
| **A07: Identification & Auth** | Autentikasi ganda & reset password mandiri. | Rendah | 🟢 **Lolos (Aman)** | RPC `student_self_reset_password` dan Supabase Auth recovery token. Pesan kesalahan login bersifat generik untuk mencegah *user enumeration*. |
| **A08: Software & Data Integrity**| Skema tautan eksternal, QR Code, dan integritas data. | Rendah | 🟢 **Lolos (Aman)** | Validasi skema URL via `safeLaunchUrl()` menolak skema non-web (`file:`, `javascript:`, `intent:`). QR Code digenerate in-memory. |
| **A09: Logging & Monitoring** | Audit trail administratif & log pengingat otomatis. | Rendah | 🟢 **Lolos (Aman)** | Seluruh tindakan kritis admin (CREATE, UPDATE, DELETE, EXPORT, BULK_ASSIGN, BROADCAST) dicatat ke `audit_logs` dengan identitas pengguna nyata (`user_identifier`, `user_name`). |
| **A10: Server-Side Request Forgery**| Pemanggilan webhook & proxy API WAHA. | Rendah | 🟢 **Lolos (Aman)** | `reminder_service` membatasi URL proxy upstream hanya pada whitelist path statis yang diizinkan (`allowedGet`, `allowedPost`) dengan URL target terkonfigurasi. |

---

## 3. Rincian Teknis & Pengamanan Mutakhir (Audit 20 Oktober 2026)

### 1. Persistent Reminder Gateway (`reminder_service`)
- **Zero Third-Party Dependency**:
  Layanan berjalan di atas Node.js 22 murni tanpa modul eksternal pihak ketiga, menghilangkan risiko serangan *supply chain* seperti modifikasi paket *npm*.
- **Perlindungan Timing Attack**:
  ```javascript
  function equal(a, b) {
    const aa = Buffer.from(String(a || ''));
    const bb = Buffer.from(String(b || ''));
    return aa.length === bb.length && timingSafeEqual(aa, bb);
  }
  ```
- **Reverse Proxy Whitelist & Anti-SSRF**:
  Gateway menolak pemanggilan path arbitrer dari klien:
  ```javascript
  const allowedGet = [`/api/sessions/${encoded}`, `/api/${encoded}/auth/qr`, '/api/server/version'];
  const allowedPost = [`/api/sessions/${encoded}/start`, `/api/sessions/${encoded}/stop`, `/api/sessions/${encoded}/logout`, '/api/sessions', '/api/sendText'];
  ```
- **Batas Beban Request**:
  Payload request dibatasi maksimal 1 MB untuk menangkal serangan Denial-of-Service berbasis konsumsi memori.

### 2. Penegakan Kontrol Akses Kelompok Mahasiswa (`student_groups`)
- Tabel `student_groups` dan `student_group_members` menerapkan model **Zero Direct Table Access**:
  - Seluruh akses diblokir dari `PUBLIC`, `anon`, dan `authenticated`.
  - Pembacaan data dilakukan melalui fungsi RPC `get_student_groups()` yang secara eksplisit memverifikasi keanggotaan mahasiswa:
    ```sql
    WHERE EXISTS (
      SELECT 1 FROM public.student_group_members gm
      WHERE gm.group_id = g.id AND gm.student_nim = v_nim
    ) OR v_is_admin OR (v_is_officer AND g.class_key = v_class)
    ```
  - Mencegah kerentanan IDOR (Insecure Direct Object Reference) di mana mahasiswa kelas lain tidak dapat mengintip atau memodifikasi tugas kelompok yang bukan haknya.

### 3. Perlindungan Integritas Audit Trail Administrator
- Pada `AdminAuditService`, pencatatan aksi administrator tidak lagi menggunakan UUID anonim atau teks placeholder statis, melainkan mengikat langsung NIM asli administrator (`16110376`) dan nama akun aktif (`Admin Program Studi`):
  - Memudahkan penelusuran forensik apabila terjadi modifikasi data kritis (penghapusan kelas, perubahan nilai, ekspor data, atau pengiriman siaran massal).
  - Tersimpan secara persisten di database Supabase `audit_logs` dan cadangan *in-memory* lokal.

### 4. Validasi Preferensi Agama & Penjadwalan Akademik
- Fitur pemfilteran jadwal berbasis agama (`agama`) divalidasi di tingkat model dan sanitasi input sebelum disinkronkan ke basis data Supabase (`students.agama`).
- Tidak ada kueri raw SQL dinamis yang digunakan; seluruh seleksi menggunakan query builder PostgREST terparameterisasi.

---

## 4. Hasil Verifikasi Otomatis (Automated Test Suite)

| Kategori Pengujian | Cakupan | Hasil |
| :--- | :--- | :---: |
| **Flutter Widget & Unit Tests** | Seluruh modul (`test/`), smoke test, responsivitas, dan form validation | 🟢 **110 / 110 Lulus (100%)** |
| **Reminder Gateway Unit Tests** | Otentikasi gateway, normalisasi nomor, reply code uniqueness, restart persistence, dan simulasi aman | 🟢 **11 / 11 Lulus (100%)** |
| **NPM Audit (WAHA Gateway)** | Dependensi Node.js Baileys dan web server | 🟢 **0 Kerentanan Ditemukan** |

---

## 5. Prosedur Pelaporan Kerentanan (Vulnerability Disclosure)

Jika Anda menemukan potensi celah keamanan atau kerentanan baru pada aplikasi ini:
1. Laporkan temuan secara privat melalui email tim pengembang: `gellonaindonesia@gmail.com`.
2. Jangan mempublikasikan isu keamanan secara publik (*responsible disclosure*) sebelum tim pengembang merilis perbaikan (*patch*).
3. Tim pengembang berkomitmen merespons dan mengevaluasi laporan dalam waktu 1x24 jam kerja.
