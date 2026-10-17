-- Migration: 20261017_profile_persistence_and_directory.sql
-- Description: Menambahkan kolom bio & avatar_url pada tabel students dan memperbarui fungsi RPC get_class_directory agar mengembalikan profil lengkap.

-- 1. Tambah kolom bio dan avatar_url jika belum ada
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS bio TEXT;

-- 2. Perbarui RPC get_class_directory agar mengembalikan avatar_url, bio, dan email
CREATE OR REPLACE FUNCTION public.get_class_directory()
RETURNS TABLE (
  id text,
  nim text,
  nama text,
  email text,
  no_wa text,
  peminatan text,
  prodi text,
  semester integer,
  kelas text,
  role text,
  jabatan text,
  is_aktif boolean,
  instagram text,
  linkedin text,
  avatar_url text,
  bio text
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT 
    s.id, 
    s.nim, 
    s.nama, 
    COALESCE(s.email, '') as email,
    COALESCE(s.no_wa, '') as no_wa, 
    COALESCE(s.peminatan, '') as peminatan, 
    COALESCE(s.prodi, 'Ilmu Komunikasi') as prodi, 
    COALESCE(s.semester, 1) as semester,
    COALESCE(s.kelas, 'Ilmu Komunikasi') as kelas, 
    COALESCE(s.role, 'MAHASISWA') as role, 
    COALESCE(s.jabatan, 'Mahasiswa') as jabatan, 
    COALESCE(s.is_aktif, true) as is_aktif, 
    s.instagram, 
    s.linkedin,
    s.avatar_url,
    s.bio
  FROM public.students s
  WHERE s.is_aktif = true
    AND (SELECT public.current_student_nim()) IS NOT NULL
  ORDER BY s.nama;
$$;

GRANT EXECUTE ON FUNCTION public.get_class_directory() TO anon, authenticated;
