-- Migration: 20261013_add_avatar_url_to_students.sql
-- Description: Menambahkan kolom avatar_url pada tabel public.students untuk mendukung penyimpanan foto profil mahasiswa

ALTER TABLE public.students ADD COLUMN IF NOT EXISTS avatar_url TEXT;
