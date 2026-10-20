-- Migration: Add agama column to students table for religion-based elective course filtering
ALTER TABLE students ADD COLUMN IF NOT EXISTS agama TEXT DEFAULT 'Islam';

-- Update existing students without agama to 'Islam' as default
UPDATE students SET agama = 'Islam' WHERE agama IS NULL OR trim(agama) = '';
