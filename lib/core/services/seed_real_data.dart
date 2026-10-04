import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  const supabaseUrl = 'https://boffbpvyqhajfiqzyztx.supabase.co';
  const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvZmZicHZ5cWhhamZpcXp5enR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExMTY0MzQsImV4cCI6MjEwNjY5MjQzNH0.taJwWfaI0SuBOU3D7SFF2MRuXsCzkdj4Wrsc5DG5GJw';

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  print('Menghapus data jadwal contoh lama...');
  try {
    await client.from('courses').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  } catch (e) {
    print('Warning delete: $e');
  }

  print('Memasukkan data jadwal resmi FISIP UNAZLAM...');
  final realCourses = [
    {
      'kode_mk': '2 PK 100',
      'nama_mk': 'Pendidikan Pancasila',
      'sks': 2,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu Pancasila',
      'dosen_wa': '081234567890',
      'hari': 'Senin',
      'jam_mulai': '15:30:00',
      'jam_selesai': '17:00:00',
      'ruangan': 'Ruang A2',
    },
    {
      'kode_mk': '2 PK 103',
      'nama_mk': 'Pendidikan Kewarganegaraan',
      'sks': 2,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu Kewarganegaraan',
      'dosen_wa': '081234567891',
      'hari': 'Senin',
      'jam_mulai': '18:30:00',
      'jam_selesai': '20:00:00',
      'ruangan': 'Ruang B1',
    },
    {
      'kode_mk': '3 PK 101A',
      'nama_mk': 'Pendidikan Agama Islam *',
      'sks': 3,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu PAI',
      'dosen_wa': '081234567892',
      'hari': 'Selasa',
      'jam_mulai': '15:30:00',
      'jam_selesai': '17:45:00',
      'ruangan': 'Ruang A1',
    },
    {
      'kode_mk': '3 PK 101B',
      'nama_mk': 'Pendidikan Agama Kristen *',
      'sks': 3,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu PAK',
      'dosen_wa': '081234567893',
      'hari': 'Selasa',
      'jam_mulai': '15:30:00',
      'jam_selesai': '17:45:00',
      'ruangan': 'Ruang B1',
    },
    {
      'kode_mk': '2 PK 106',
      'nama_mk': 'Ilmu Kealaman Dasar *',
      'sks': 2,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu IKD',
      'dosen_wa': '081234567894',
      'hari': 'Selasa',
      'jam_mulai': '18:30:00',
      'jam_selesai': '20:45:00',
      'ruangan': 'Ruang A2',
    },
    {
      'kode_mk': '3 PK 105',
      'nama_mk': 'Bahasa Indonesia *',
      'sks': 3,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu Bahasa Indonesia',
      'dosen_wa': '081234567895',
      'hari': 'Rabu',
      'jam_mulai': '15:30:00',
      'jam_selesai': '17:45:00',
      'ruangan': 'Ruang A2',
    },
    {
      'kode_mk': '3 PK 104',
      'nama_mk': 'Bahasa Inggris *',
      'sks': 3,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu Bahasa Inggris',
      'dosen_wa': '081234567896',
      'hari': 'Kamis',
      'jam_mulai': '18:30:00',
      'jam_selesai': '20:45:00',
      'ruangan': 'Ruang A1',
    },
    {
      'kode_mk': '3 PK 201',
      'nama_mk': 'Pengantar Ilmu Politik *',
      'sks': 3,
      'semester': 1,
      'dosen_pengampu': 'Dosen Pengampu Pengantar Ilmu Politik',
      'dosen_wa': '081234567897',
      'hari': 'Jumat',
      'jam_mulai': '18:30:00',
      'jam_selesai': '20:45:00',
      'ruangan': 'Ruang B1',
    },
  ];

  await client.from('courses').insert(realCourses);
  print('Berhasil memasukkan ${realCourses.length} mata kuliah resmi ke Supabase!');
}
