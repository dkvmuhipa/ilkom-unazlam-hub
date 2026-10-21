import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/features/admin/views/admin_courses_view.dart';
import 'package:class_manager/features/admin/views/admin_academic_year_view.dart';
import 'package:class_manager/features/admin/models/admin_models.dart';
import 'package:class_manager/models/models.dart';

void main() {
  testWidgets('AdminCoursesView opens spacious course editor with all rich fields', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final courses = [
      Course(
        id: '1',
        kode: 'IK-101',
        nama: 'Pengantar Ilmu Komunikasi',
        sks: 3,
        semester: 1,
        dosen: 'Dr. Sarah Wijaya',
        dosenWa: '081234567890',
        hari: 'Senin',
        jamMulai: '08:00',
        jamSelesai: '10:30',
        ruangan: 'Ruang 301',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminCoursesView(
            courses: courses,
            isLoading: false,
            loadError: null,
            onBack: () {},
            onReload: () async {},
            onShowMessage: (msg, {isError = false}) {},
            onRecordAudit: ({
              required String action,
              required String description,
              required String module,
              Map<String, dynamic>? metadata,
            }) {},
            onConfirmDelete: (prompt) async => true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Tambah Matkul" button
    final addButton = find.text('Tambah Matkul');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify Spacious Modal Header & Rich Sections
    expect(find.text('Tambah Mata Kuliah Baru'), findsOneWidget);
    expect(find.text('IDENTITAS MATA KULIAH'), findsOneWidget);
    expect(find.text('DOSEN PENGAMPU & KONTAK'), findsOneWidget);
    expect(find.text('JADWAL & LOKASI PERKULIAHAN'), findsOneWidget);
    expect(find.text('BOBOT SKS'), findsOneWidget);
    expect(find.text('HARI KULIAH'), findsOneWidget);
    expect(find.text('JAM MULAI'), findsOneWidget);
    expect(find.text('JAM SELESAI'), findsOneWidget);

    // Verify SKS Chips
    expect(find.text('3 SKS'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });

  testWidgets('AdminAcademicYearView opens spacious academic year dialog with quick presets', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final years = [
      AcademicYearItem(id: '1', tahun: '2026/2027', isAktif: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminAcademicYearView(
            academicYears: years,
            isLoading: false,
            loadError: null,
            onBack: () {},
            onReload: () async {},
            onShowMessage: (msg, {isError = false}) {},
            onRecordAudit: ({
              required String action,
              required String description,
              required String module,
              Map<String, dynamic>? metadata,
            }) {},
            onConfirmDelete: (prompt) async => true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "+ Tambah Tahun Akademik"
    final addButton = find.text('+ Tambah Tahun Akademik');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify spacious modal & preset chips
    expect(find.text('Tambah Tahun Akademik'), findsOneWidget);
    expect(find.text('PERIODE TAHUN AJARAN'), findsOneWidget);
    expect(find.text('Pilihan Cepat:'), findsOneWidget);
    expect(find.text('2027/2028'), findsWidgets);

    // Close modal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });
}
