# Audit frontend — 18 Oktober 2026

## Ruang lingkup dan bukti

Audit atas working tree saat ini, termasuk tiga file UI yang masih belum di-commit. Penelusuran mencakup shell/navigasi, komponen bersama, autentikasi, beranda, layanan, presensi, tugas, jadwal, notifikasi, KHS, materi, kas, surat, dan sampel dialog administrasi. Ini audit frontend berbasis kode dengan pengujian widget terarah; bukan sertifikasi bahwa semua halaman telah diuji visual setelah login.

- `dart analyze lib`: selesai, 0 error, 0 warning, 15 info. Catatan mencakup API deprecated, penggunaan library web, print, dan dua lint BuildContext pada ekspor admin. Lint belum otomatis dianggap bug runtime.
- Dua pengujian widget sementara terhadap MoreServicesModal: keduanya gagal karena masalah produk yang dijelaskan di bawah. Pengujian menggunakan viewport logis 360×640, DPR 1, font nyata Segoe UI untuk menghindari ukuran teks Ahem yang tidak representatif, serta profil admin sintetis. Tidak mengakses atau mengubah data produksi. File tes sementara sudah dihapus.
- Tes keyboard memakai inset bawah 300 px. Hasil: RenderFlex overflow bawah 146 px.
- Tes clear: ketik `Presensi`, tekan ikon clear, baca EditableText. Hasil: teks tetap `Presensi`, sedangkan filter internal telah kosong.
- Kode aplikasi tidak diubah dalam audit ini. Perubahan UI dari pekerjaan sebelumnya dipertahankan.

## Temuan berprioritas

P1 = berpotensi menyesatkan aktivitas akademik; P2 = fungsi/aksesibilitas terganggu; P3 = konsistensi dan kejelasan UI. Temuan kode berarti mekanismenya terlihat pada implementasi, tetapi belum direproduksi lewat akun pengguna langsung.

### 1. P1 — Kegagalan memuat status tugas dianggap belum dikerjakan

Lokasi: `lib/features/assignments/assignments_screen.dart:96`.

`getPersonalAssignmentStatusesStrict` menangkap error dan mengembalikan map kosong. Selanjutnya setiap tugas diberi status `cloudStatuses[id] ?? 'belum'`. Jika permintaan status gagal sementara daftar tugas berhasil, tugas yang sudah dikumpulkan/dinilai terlihat belum dikerjakan tanpa pesan kegagalan status.

Perbaikan: bedakan status tidak tersedia dari status belum dikerjakan; pertahankan status terakhir dan sediakan retry. Jangan memungkinkan aksi status berdasarkan fallback yang belum terverifikasi. Bukti: kode.

### 2. P1 — Notifikasi jadwal mengabaikan perubahan sesi

Lokasi: `lib/features/notifications/notification_screen.dart:145`; pembanding `lib/core/services/supabase_repository.dart:398`.

Notifikasi mengambil `getCourses()`, memfilter hari master, dan menampilkan `jamMulai`, `jamSelesai`, serta `ruangan` master. Halaman jadwal sudah memakai penggabungan override. Pada sesi dipindah/diganti/dibatalkan, informasi notifikasi bisa berbeda dari jadwal efektif.

Perbaikan: gunakan sumber jadwal efektif yang sama untuk tanggal hari ini dan besok, termasuk status pembatalan serta lokasi/jam pengganti. Bukti: kode.

### 3. P1 — Form surat memakai tanggal dan identitas akademik tetap

Lokasi: `lib/features/letters/letters_screen.dart:36`, `:44`, `:118`.

Tanggal awal adalah `Rabu, 7 Oktober 2026`, alasan sakit terisi otomatis, dan isi surat memuat Semester 1 serta Reguler 2026. Pengguna dapat menghasilkan surat dengan tanggal/semester yang salah jika tidak menyunting. Mata kuliah dan dosen contoh juga tetap ada bila pemuatan gagal.

Perbaikan: tanggal dari pemilih tanggal, identitas dari profil, alasan kosong dengan validasi, dan tampilkan kegagalan pemuatan pilihan. Bukti: kode.

### 4. P2 — Direktori layanan overflow saat keyboard terbuka

Lokasi: `lib/features/dashboard/widgets/more_services_modal.dart:133`.

Bottom sheet menambahkan seluruh `viewInsets.bottom` ke padding dalam Column tanpa menyediakan scroll keseluruhan. Grid shrinkWrap tidak dapat menyelamatkan layout vertikal yang kehabisan tinggi. Pada 360×640 dan keyboard 300 px, overflow bawah 146 px terkonfirmasi.

Perbaikan: batasi tinggi sheet menurut area tersedia, pindahkan kompensasi keyboard ke pembungkus luar, dan sediakan scroll dengan header/pencarian yang tetap dapat dijangkau. Bukti: tes widget.

### 5. P2 — Tombol clear tidak menghapus teks pencarian

Lokasi: `lib/features/dashboard/widgets/more_services_modal.dart:207`, `:230`.

Ikon clear hanya mengubah `_searchQuery`; TextField tidak memiliki controller yang ikut dibersihkan. Daftar kembali penuh tetapi kotak masih menampilkan kata sebelumnya. Terbukti dengan input `Presensi`.

Perbaikan: satu TextEditingController, clear controller dan filter bersama, dispose controller. Bukti: tes widget.

### 6. P2 — Notifikasi jadwal berikutnya mewarisi dismissal minggu sebelumnya

Lokasi: `lib/features/notifications/notification_screen.dart:150`, `:163`, `:176`, `:466`.

ID `schedule_today_<courseId>` dan `schedule_tomorrow_<courseId>` tidak memuat tanggal. Dismissal disimpan ke SharedPreferences dan diterapkan pada ID yang sama di semua minggu. Menghapus pengingat pertemuan ini bisa menyembunyikan pengingat pertemuan mendatang.

Perbaikan: sertakan tanggal pertemuan dalam ID; bersihkan state kedaluwarsa. Bukti: kode.

### 7. P2 — Tombol ScaleButton tidak mendukung aktivasi keyboard

Lokasi: `lib/core/widgets/scale_button.dart:31`.

Komponen menggunakan GestureDetector dan AnimatedScale tanpa Focus, Actions, atau kontrol tombol Material. Layanan, avatar, dan kontrol yang dibangun dengannya tidak menyediakan interaksi Tab/Enter/Space seperti tombol standar. Gesture tap dapat membawa semantics tertentu, tetapi tidak menggantikan dukungan keyboard.

Perbaikan: gunakan tombol Material atau FocusableActionDetector dengan semantics tombol, indikator fokus, dan shortcut aktivasi. Bukti: kode komponen bersama.

### 8. P2 — Kegagalan jadwal dan pencarian menyerupai hasil kosong

Lokasi: `lib/core/services/supabase_repository.dart:253`; `lib/features/schedule/schedule_screen.dart:113`; `lib/core/widgets/universal_search_modal.dart:61`.

Repository jadwal mengembalikan cache atau list kosong saat gagal. Jadwal hanya mencatat error ke log. Pencarian universal juga hanya mengakhiri loading dalam catch. UI tidak cukup membedakan tidak ada data, data lama, dan layanan gagal.

Perbaikan: state success/empty/stale/error yang berbeda, dengan retry dan keterangan data lama. Bukti: kode.

### 9. P2 — Badge beranda tidak sinkron setelah notifikasi dibaca

Lokasi: `lib/features/dashboard/student_home_screen.dart:105`, `:164`; `lib/main.dart:501`; `lib/features/notifications/notification_screen.dart:73`.

Jumlah unread beranda dihitung saat `_loadDashboard`. Layar notifikasi menulis SharedPreferences tanpa mengabari beranda. IndexedStack mempertahankan beranda saat berpindah tab, sehingga kembali ke beranda tidak menjalankan initState lagi. Badge bisa tetap menampilkan hitungan sebelum dibaca sampai pemuatan berikutnya.

Perbaikan: gunakan notifier/store bersama untuk status notifikasi atau invalidasi beranda saat kembali. Bukti: kode.

### 10. P2 — Animasi beranda tetap aktif saat tab tersembunyi

Lokasi: `lib/main.dart:501`; `lib/features/dashboard/student_home_screen.dart:69`.

IndexedStack mempertahankan tab yang pernah dibuka. Beranda menjalankan AnimationController.repeat dan tidak dibungkus TickerMode per tab. Animasi masih dapat memicu tick/rebuild walau beranda tidak terlihat. Belum ada profiling yang mengukur dampak baterai/FPS.

Perbaikan: TickerMode untuk tab aktif; hormati preferensi pengurangan animasi. Bukti: kode; besaran dampak belum diukur.

### 11. P2 — Subscription surat tidak dilepas bersama layar

Lokasi: `lib/features/letters/letters_screen.dart:42`, `:72`, `:105`; `lib/core/services/supabase_repository.dart:160`.

Hasil `subscribeToPermissionLetters` tidak disimpan. Field `_realtimeSub` bertipe StreamSubscription tidak pernah diisi, sedangkan repository mengembalikan RealtimeChannel. Dispose membatalkan field kosong, sehingga subscription dapat bertahan setelah shell/layer layar dilepas.

Perbaikan: simpan RealtimeChannel yang dikembalikan dan gunakan unsubscribeChannel pada dispose. Bukti: kode.

### 12. P2 — KHS memakai latar terang tetap dalam mode gelap

Lokasi: `lib/features/gpa/academic_grades_screen.dart:382`.

Scaffold menetapkan AppColors.background yang tetap, sedangkan kartu memakai Theme.of(context).colorScheme.surface. Mode gelap menghasilkan permukaan yang tidak konsisten. Belum dilakukan pengukuran rasio kontras seluruh layar.

Perbaikan: gunakan scaffoldBackgroundColor/colorScheme dari tema, lalu periksa kontras tiap pasangan warna. Bukti: kode.

### 13. P3 — Label navigasi dan shortcut menjanjikan perilaku berbeda

Lokasi: `lib/features/dashboard/widgets/more_services_modal.dart:120`; `lib/main.dart:450`; `lib/features/dashboard/student_home_screen.dart:533`.

`Panel Komti` menuju index 7, yaitu Pengumuman. Petunjuk `Ctrl K` tampil pada pencarian desktop tetapi tidak ditemukan binding Ctrl+K di kode aplikasi. Keduanya membuat pengguna mengharapkan aksi yang tidak disediakan.

Perbaikan: sesuaikan label tujuan atau implementasikan panel yang benar; hubungkan Ctrl+K ke pencarian atau hapus petunjuk. Bukti: pemetaan navigasi dan pencarian kode.

### 14. P3 — Pencarian layanan mewarisi dekorasi input ganda

Lokasi: `lib/features/dashboard/widgets/more_services_modal.dart:192`, `:214`; `lib/core/theme/app_theme.dart:181`.

Container pencarian sudah memiliki fill/border, tetapi input hanya menimpa `border: InputBorder.none`. Tema masih menyediakan filled, fillColor, enabledBorder, focusedBorder, dan contentPadding. Screenshot pengguna memperlihatkan input putih berbentuk kapsul di dalam bingkai lain.

Perbaikan: jadikan TextField satu-satunya komponen visual atau override seluruh dekorasi turunan secara eksplisit. Bukti: screenshot pengguna dan kode tema.

## Hal yang perlu keputusan produk atau verifikasi lanjutan

- IPK menjumlahkan semua nilai tercatat (`academic_grades_screen.dart:120`), termasuk pengulangan mata kuliah. Teks menyebut kebijakan prodi tetapi kebijakan pemilihan nilai belum diwujudkan dalam perhitungan. Tentukan nilai terbaru/terbaik/semua sebelum menyebut hasil sebagai IPK resmi. Jangan mengasumsikan kebijakan kampus.
- Mode gelap, font 150–200%, layar 320/360/430/768/1280, keyboard, dan navigasi pembaca layar belum diverifikasi end-to-end pada semua halaman akun mahasiswa/pengurus/admin.
- Dialog admin broadcast sudah punya batas tinggi dan penyesuaian inset. Lebar tetap di dalam dialog tidak otomatis berarti overflow karena parent Flutter dapat membatasinya; perlu uji layar nyata sebelum menjadi temuan.
- Label WIB di notifikasi perlu dicocokkan dengan zona waktu kampus. Zona waktu perangkat pengguna tidak otomatis menentukan zona jadwal kampus.
- Tes existing hanya smoke test aplikasi; belum ada cakupan regresi layout, keyboard, status jaringan, dan perpindahan akun.
- Loading beranda mengganti seluruh isi saat refresh/realtime. Ini peluang perbaikan UX: pertahankan konten lama dan tampilkan indikator pembaruan ringan.

## Urutan tindak lanjut

1. Kebenaran informasi akademik: status tugas, jadwal notifikasi, default surat.
2. Fungsi ponsel: bottom sheet/keyboard dan clear pencarian; tambahkan regresi terarah.
3. Navigasi dan aksesibilitas bersama: ScaleButton, badge unread, ID notifikasi, tujuan menu.
4. Konsistensi state/tema dan efisiensi: error vs empty, dark mode, ticker, subscription.
5. Verifikasi visual lintas ukuran, teks besar, dan peran; lalu putuskan aturan IPK bersama pihak akademik.


## Implementasi perbaikan — 18 Oktober 2026

Perbaikan kode telah diterapkan untuk temuan 1–14:

- Status tugas menggunakan jalur strict; kegagalan mengambil status juga diteruskan pada beranda.
- Notifikasi memakai perubahan/pembatalan jadwal per tanggal dan ID per pertemuan, tanpa asumsi zona WIB.
- Surat memakai tanggal pilihan dan profil mahasiswa, validasi kolom wajib, serta konten arsip sebagai sumber salin/bagikan. Pesan WhatsApp tidak mengklaim pesan telah terkirim.
- Direktori layanan dapat digulir ketika keyboard terbuka, mendukung teks besar, membersihkan input dan filter, serta memakai satu bingkai pencarian.
- Tombol mendukung fokus/aktivasi keyboard dan preferensi pengurangan animasi.
- Jadwal/pencarian menampilkan kegagalan dengan aksi coba lagi; badge beranda mengikuti perubahan status baca lokal.
- Halaman tersembunyi menonaktifkan ticker; kanal realtime surat dibersihkan saat dispose.
- Latar KHS mengikuti tema. Label menu menjadi Pengumuman, petunjuk shortcut yang belum tersedia dihapus.
- Refresh beranda mempertahankan konten; header presensi dan grid layanan memakai tata letak responsif.

Validasi: 15 tes regresi lulus (lebar 320/360/430/768/1280, skala teks 100%/200%, keyboard, clear pencarian, tombol keyboard, ID jadwal, perubahan dan pembatalan jadwal). Analyzer lib: 0 error, 0 warning, 15 info lama. `git diff --check` lolos. Pengujian akun nyata lintas peran, seluruh halaman mode gelap/pembaca layar, dan keputusan kebijakan nilai ulang masih diperlukan. Tidak ada migrasi atau perubahan data produksi dalam perbaikan ini.
