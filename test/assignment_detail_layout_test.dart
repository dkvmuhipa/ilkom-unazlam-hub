import 'package:class_manager/features/assignments/widgets/assignment_detail_sheet.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [320.0, 360.0, 768.0]) {
    testWidgets('Task details fit width $width with larger text', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: AssignmentDetailSheet(
              canManage: true,
              userNim: 'layout-test',
              assignment: Assignment(
                id: 'layout-test',
                courseId: 'course',
                courseName: 'Pengantar Metode Penelitian Ilmu Komunikasi',
                judul: 'Laporan observasi dan analisis komunikasi masyarakat',
                deskripsi: '',
                kategori: 'Proyek Praktikum',
                deadline: DateTime.now().add(const Duration(hours: 12)),
                linkPengumpulan: 'https://example.com/pengumpulan-tugas',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mata kuliah'), findsOneWidget);
      expect(find.text('Kurang dari 24 jam'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada pengumpulan'), findsOneWidget);
      expect(find.text('Kirim Tugas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
