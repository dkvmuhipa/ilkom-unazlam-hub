# Security Policy & Audit Report (OWASP Standards)

**Application**: ILKOM UNAZLAM Hub (Platform Manajemen Akademik & Kelas Terpadu)  
**Latest Audit Date**: 2026-10-17 (Audit Keamanan Menyeluruh: WAHA Gateway, Smart Auto-Reminder, & Persistensi Profil)  
**Audit Scope**: Codebase Flutter (`lib/`), Gateway WhatsApp (`waha_gateway/`), Supabase Migrations (`supabase_migrations/`), Supabase Edge Functions (`supabase/functions/`), dan Dependensi Pihak Ketiga (`pubspec.yaml`, `package.json`).  
**Audit Standards**: OWASP Top 10 (2021) & Mobile/API Security Best Practices  

---

## 1. Ringkasan Eksekutif (Executive Summary)

Audit keamanan komprehensif (*Paranoid Mode*) telah dilaksanakan pada **17 Oktober 2026** menyusul penambahan modul **WAHA Gateway (Native Baileys WhatsApp Engine)**, sistem pengingat otomatis jadwal kuliah ke dosen (**Smart Auto-Reminder Kombinasi Cerdas**), serta integrasi persistensi profil mahasiswa ke basis data Supabase.

### Rangkuman Temuan Utama:
- **0 Secrets Leakage (Kredensial Aman)**: Tidak ada *service_role key*, *secret key*, atau kredensial database privat yang tersimpan di repositori klien. Kunci Supabase di aplikasi klien beroperasi menggunakan `role: anon` publik. Sesi autentikasi WhatsApp Baileys (`waha_gateway/sessions/`), file environment (`.env`, `*.env`), keystore Android (`key.properties`), dan kredensial Firebase (`google-services.json`) terlindungi 100% dalam `.gitignore`.
- **0 Dependencies CVEs (Rantai Pasok Bersih)**: Pemindaian rantai pasok (*supply chain audit*) pada gateway Node.js menghasilkan **0 vulnerabilities** (`npm audit`). Seluruh dependensi Flutter pada `pubspec.yaml` menggunakan versi stabil terkini tanpa adanya kerentanan yang diketahui.
- **Verifikasi Otorisasi Perintah Bot WhatsApp**: Pada sistem pengingat otomatis, fungsi penerima balasan pesan masuk (`handleIncomingKomtiReply`) memverifikasi nomor pengirim (`senderJid`) terhadap nomor resmi Ketua Kelas/Komti (`config.komtiPhone`). Pengirim tidak dikenal dilarang mengeksekusi perintah kontrol (`KIRIM`, `BATAL`, `STATUS`).
- **Pengamanan API Gateway (X-Api-Key Middleware)**: Gateway menyertakan middleware verifikasi header `X-Api-Key` berbasis variabel lingkungan `WAHA_API_KEY`.
- **0 SQL / PostgREST Injection**: Seluruh interaksi basis data menggunakan PostgREST SDK terparameterisasi penuh (`.eq()`, `.match()`, dll.). Fungsi-fungsi database PostgreSQL dibangun menggunakan pola `SECURITY DEFINER` dengan penguncian skema `SET search_path = ''` guna menangkal eksploitasi search-path hijacking.
- **Kriptografi Lokal Terverifikasi**: Penyimpanan kata sandi mahasiswa pada `SharedPreferences` menggunakan hashing satu arah **Salted SHA-256** (`custom_pwd_hash_$nim`), bukan plaintext. Kata sandi akun Administrator dilarang keras dan tidak pernah disimpan di penyimpanan lokal perangkat.
- **Validasi Skema URL Ketat**: Pembukaan tautan eksternal dilindungi oleh fungsi `safeLaunchUrl()` yang membatasi skema hanya pada `http://` dan `https://`, mencegah eksploitasi skema berbahaya (`javascript:`, `file:`, `intent:`).

---

## 2. Matriks Evaluasi OWASP Top 10 (2021)

| Kategori OWASP | Deskripsi & Komponen | Tingkat Risiko | Status Audit | Catatan & Mitigasi |
| :--- | :--- | :---: | :---: | :--- |
| **A01: Broken Access Control** | Penegakan RLS pada tabel master data & admin. | Sedang | 🟡 **Warning (Fase Transisi)** | Pada migrasi saat ini, RLS dibuka (`USING (true)`) untuk mendukung operasi CRUD hibrida mahasiswa saat domain email kampus belum aktif. Disarankan bertransisi ke RLS berbasis `auth.uid()` setelah seluruh akun terikat resmi. |
| **A01: Broken Access Control** | Otorisasi perintah WhatsApp Bot & Gateway API. | Rendah | 🟢 **Lolos (Aman)** | Verifikasi pengirim pesan WhatsApp (`cleanSender.endsWith(cleanKomti)`) mencegah perintah palsu. Dukungan otentikasi `X-Api-Key` pada endpoint REST. |
| **A02: Cryptographic Failures**| Penyimpanan kredensial di `SharedPreferences` & Sesi WhatsApp. | Rendah | 🟢 **Lolos (Aman)** | Plaintext dieliminasi 100%. Digantikan Salted SHA-256 (`crypto: ^3.0.7`). Token sesi Baileys disimpan di folder lokal terisolasi yang diabaikan oleh Git. |
| **A03: Injection** | Injeksi filter PostgREST atau kueri database PostgreSQL. | Rendah | 🟢 **Lolos (Aman)** | Semua parameter kueri di-bind secara aman via client SDK. Fungsi database menggunakan `SECURITY DEFINER` dengan `SET search_path = ''`. |
| **A04: Insecure Design** | Alur otomatisasi pengingat dosen & presensi kelas. | Rendah | 🟢 **Lolos (Aman)** | Mekanisme *Kombinasi Cerdas* memberi jeda toleransi (45 menit) bagi Komti untuk membatalkan sebelum pesan otomatis meluncur ke dosen. Voting dilindungi pencegahan suara ganda per-NIM (`UNIQUE(poll_id, voter_nim)`). |
| **A05: Security Misconfiguration**| Konfigurasi CORS, Secrets, dan Service Role Keys. | Rendah | 🟢 **Lolos (Aman)** | Service role key hanya diakses di sisi server Deno (`Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')`). Gateway WhatsApp berjalan pada localhost port 3000. |
| **A06: Vulnerable Components** | Audit dependensi (`pubspec.yaml`, `waha_gateway/package.json`). | Rendah | 🟢 **Lolos (Aman)** | `npm audit` menunjukkan 0 vulnerabilities. Pustaka Flutter menggunakan versi teruji tanpa CVE aktif. |
| **A07: Identification & Auth** | Mekanisme autentikasi ganda (Supabase Auth + Fallback NIM). | Sedang | 🟢 **Lolos (Terkontrol)** | Endpoint `student-login` mengembalikan refresh token resmi Supabase tanpa membocorkan pemetaan email ke klien. Pesan kesalahan login bersifat generik untuk mencegah *user enumeration*. |
| **A08: Software & Data Integrity**| Tautan eksternal, QR Code Baileys, dan unggahan data mahasiswa. | Rendah | 🟢 **Lolos (Aman)** | Validasi skema URL via `safeLaunchUrl()`. QR Code Baileys digenerate in-memory tanpa mengekspos raw token ke publik. |
| **A09: Logging & Monitoring** | Audit trail tindakan administratif & log pengingat otomatis. | Rendah | 🟢 **Lolos (Aman)** | Seluruh tindakan kritis admin (CREATE, UPDATE, DELETE, EXPORT) dicatat ke `audit_logs`. Pengiriman pengingat dosen dicatat ke `reminder_history.json`. |
| **A10: Server-Side Request Forgery**| Pengiriman webhook notifikasi FCM & panggilan API WAHA. | Rendah | 🟢 **Lolos (Aman)** | Endpoint FCM terkunci pada Google API resmi (`fcm.googleapis.com`). Panggilan API WAHA diarahkan ke target URL internal terkonfigurasi. |

---

## 3. Rincian Temuan & Rekomendasi Mitigasi

### 1. Keamanan WAHA Gateway & Otomasi Pengingat Dosen
* **Verifikasi Pengirim Perintah Masuk**:
  Gateway WhatsApp secara aktif memantau pesan masuk melalui event listener `messages.upsert`. Untuk mencegah pihak ketiga yang tidak bertanggung jawab mengirimkan perintah seperti `KIRIM` atau `BATAL`, sistem memvalidasi bahwa nomor pengirim (`senderJid`) cocok dengan nomor WhatsApp Ketua Kelas yang tersimpan di konfigurasi:
  ```javascript
  const cleanSender = senderJid.replace(/[^0-9]/g, '');
  const cleanKomti = (config.komtiPhone || '').replace(/[^0-9]/g, '');
  if (!cleanKomti || !cleanSender.endsWith(cleanKomti)) return;
  ```
* **Perlindungan Kredensial Sesi WhatsApp**:
  Folder `waha_gateway/sessions/` yang berisi kunci enkripsi Noise protocol dan token autentikasi multi-device telah terdaftar di `.gitignore`. File ini tidak akan terunggah ke repositori publik.
* **Pengamanan Endpoint API Gateway**:
  Tersedia middleware `WAHA_API_KEY`. Dalam penyebaran di server publik atau multi-user, cukup tetapkan environment variable `WAHA_API_KEY` untuk mengunci seluruh endpoint `/api`.

### 2. Kebijakan Row Level Security (RLS) pada Fase Transisi
* **Kondisi Saat Ini**:
  Untuk memastikan seluruh fitur CRUD (Kas, Pengumuman, Tugas, Nilai, Surat Izin, Polling, dan Data Kelas) dapat beroperasi tanpa kendala saat mahasiswa masih dalam proses klaim akun dengan email pribadi, migrasi `20261013_full_crud_permissions_fix.sql` mengizinkan operasi `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` kepada role `public`.
* **Rekomendasi Lingkungan Produksi**:
  Setelah seluruh mahasiswa mengklaim akun resmi mereka:
  1. Perketat kebijakan RLS pada tabel `students` agar hanya pemilik akun (`auth.uid() = auth_user_id`) yang dapat memperbarui profilnya.
  2. Batasi operasi `INSERT`/`UPDATE`/`DELETE` pada `announcements`, `courses`, dan `academic_classes` hanya untuk akun dengan peran `ADMIN` atau pengurus kelas terverifikasi (`has_class_role(ARRAY['ADMIN', 'KETUA KELAS', 'SEKRETARIS'])`).
  3. Batasi pengisian kas kelas hanya untuk peran `BENDAHARA` dan `ADMIN`.

### 3. Keamanan Kriptografi & Proteksi Kredensial Klien
* **Pencegahan Kebocoran**:
  - `crypto: ^3.0.7` digunakan untuk membuat hash kata sandi lokal mahasiswa:
    $$\text{Hash} = \text{SHA256}(\text{nim} \parallel \text{":salt\_ilkom\_unazlam\_2026:"} \parallel \text{password})$$
  - Akun Administrator wajib melakukan verifikasi online langsung melalui Supabase Auth; kredensial admin tidak pernah disimpan di storage lokal perangkat.
  - Kunci plaintext lama (`custom_pwd_$nim`, `custom_pwd_admin`) secara otomatis dihapus dari `SharedPreferences` saat login berhasil.

### 4. Integritas Data & Validasi Input
* **Pemberian Suara (Voting)**:
  Tabel `poll_votes` memiliki kekangan unik `UNIQUE(poll_id, voter_nim)` di tingkat database, menjamin tidak ada duplikasi suara meskipun terjadi percobaan manipulasi dari aplikasi klien.
* **Arsip Surat Izin**:
  Setiap surat izin yang dibuat oleh mahasiswa otomatis terindeks dengan `student_nim` dan waktu pembuatan `created_at` yang tidak dapat dimanipulasi secara retrospektif.
* **Validasi Skema URL**:
  Semua tautan keluar dikonfirmasi melalui `safeLaunchUrl()` untuk menolak skema `file:`, `javascript:`, atau `intent:`.

---

## 4. Prosedur Pelaporan Kerentanan (Vulnerability Disclosure)

Jika Anda menemukan potensi celah keamanan atau kerentanan baru pada aplikasi ini:
1. Laporkan temuan secara privat melalui email tim pengembang: `gellonaindonesia@gmail.com`.
2. Jangan mempublikasikan isu keamanan secara publik (*responsible disclosure*) sebelum tim pengembang merilis perbaikan (*patch*).
3. Tim pengembang berkomitmen merespons dan mengevaluasi laporan dalam waktu 1x24 jam kerja.

---

*Laporan audit keamanan ini diverifikasi dan disetujui sesuai standar OWASP Top 10 pada 2026-10-17.*
