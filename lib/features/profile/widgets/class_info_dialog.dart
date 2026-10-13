import 'package:flutter/material.dart';

class ClassInfoDialog {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF1E40AF), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Informasi Kelas ILKOM',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfoRow('Program Studi', 'S1 Ilmu Komunikasi', isDark),
            _buildClassInfoRow('Fakultas', 'Ilmu Sosial dan Ilmu Politik (FISIP)', isDark),
            _buildClassInfoRow('Universitas', 'Universitas Abdul Azis Lamadjido (UNAZLAM)', isDark),
            _buildClassInfoRow('Angkatan', '2026 (Semester 1 Reguler)', isDark),
            _buildClassInfoRow('Total Mahasiswa', '23 Orang Mahasiswa Aktif', isDark),
            _buildClassInfoRow('Ruang Utama', 'Ruang A2 FISIP UNAZLAM Palu', isDark),
            _buildClassInfoRow('Ketua Kelas', 'Nur Farida (260250023)', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildClassInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
