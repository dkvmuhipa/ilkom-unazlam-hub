import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/features/admin/views/admin_roles_view.dart';
import 'package:class_manager/models/models.dart';

void main() {
  testWidgets('AdminRolesView safely handles custom jabatan (e.g. Koordinator Perlengkapan)', (tester) async {
    final students = [
      StudentProfile(
        id: '1',
        nim: '210101001',
        nama: 'Andi Saputra',
        email: 'andi@stiencas.ac.id',
        noWa: '081234567891',
        kelas: 'IK-2A',
        role: 'MAHASISWA',
        jabatan: 'Koordinator Perlengkapan',
      ),
      StudentProfile(
        id: '2',
        nim: '210101002',
        nama: 'Budi Santoso',
        email: 'budi@stiencas.ac.id',
        noWa: '081234567892',
        kelas: 'IK-2A',
        role: 'MAHASISWA',
        jabatan: 'Ketua Kelas',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminRolesView(
            managedAccounts: students,
            selectedStudent: null,
            onBack: () {},
            onRecordAudit: ({
              required String action,
              required String description,
              required String module,
              Map<String, dynamic>? metadata,
            }) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify both students are displayed
    expect(find.text('Andi Saputra'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);

    // Verify Koordinator Perlengkapan appears in the custom chip and dropdown
    expect(find.text('Koordinator Perlengkapan'), findsWidgets);
    expect(find.text('Ketua Kelas'), findsWidgets);
  });
}
