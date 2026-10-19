import 'package:class_manager/features/dashboard/student_home_screen.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  final student = StudentProfile(
    id: 'ilkom-1',
    nim: '220101001',
    nama: 'Danang Gellona',
    email: 'danang@unazlam.ac.id',
    noWa: '08123456789',
    role: 'STUDENT',
    semester: 3,
  );

  for (final width in [320.0, 360.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Studio Deck renders without overflow at width $width text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1800);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        int? selectedTab;

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: StudentHomeScreen(
                student: student,
                onNavigateTab: (idx) => selectedTab = idx,
              ),
            ),
          ),
        );

        // Let async loading reject gracefully into error banner & full UI render
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // 1. Digital Press Pass & Broadcast Header Verification
        expect(find.text('PRESS PASS // S1 ILKOM'), findsOneWidget);
        expect(find.textContaining('Crew • Smt 3'), findsOneWidget);
        expect(find.textContaining('Danang 🎙️'), findsOneWidget);

        // 2. Studio Clearance & Academic Deck Verification
        expect(find.text('STUDIO CLEARANCE // AKADEMIK'), findsOneWidget);
        expect(find.text('Presensi'), findsOneWidget);
        expect(find.text('Kas'), findsOneWidget);
        expect(find.text('KHS'), findsOneWidget);
        expect(find.text('Izin'), findsOneWidget);

        // 3. Segmented Studio Control Dock Verification
        expect(find.text('KONSOL MODUL ILKOM'), findsOneWidget);
        expect(find.text('CHANNEL A // PRODUKSI & KULIAH'), findsOneWidget);
        expect(find.text('CHANNEL B // REDAKSI & BIRO KELAS'), findsOneWidget);
        expect(find.text('Materi'), findsOneWidget);
        expect(find.text('Agenda'), findsOneWidget);
        expect(find.text('Kelompok'), findsOneWidget);
        expect(find.text('Voting'), findsOneWidget);
        expect(find.text('Warta'), findsOneWidget);
        expect(find.text('Surat Izin'), findsOneWidget);
        expect(find.text('Audit Log'), findsOneWidget);
        expect(find.text('Lainnya'), findsOneWidget);

        // 4. Tab Navigation Verification: tap KHS button navigates to tab 15
        await tester.tap(find.text('KHS'));
        expect(selectedTab, 15);

        // 5. Zero unhandled layout exceptions
        final err = tester.takeException();
        if (err != null) {
          debugPrint('Layout exception: $err');
        }
        expect(err, isNull);
      });
    }
  }
}
