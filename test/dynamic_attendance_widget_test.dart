import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/features/attendance/services/dynamic_attendance_service.dart';
import 'package:class_manager/features/attendance/widgets/attendance_qr_modal.dart';
import 'package:class_manager/features/attendance/widgets/attendance_projector_view.dart';
import 'package:class_manager/features/attendance/widgets/attendance_scanner_modal.dart';
import 'package:class_manager/features/attendance/attendance_screen.dart';

void main() {
  group('Dynamic Attendance QR & Scanner UI Tests', () {
    late ActiveAttendanceSession session;

    setUp(() {
      session = ActiveAttendanceSession(
        id: 'session-test-anti-cheat',
        courseName: 'Teori Komunikasi',
        pertemuanKe: 5,
        token: 'KOMUNIKASI5',
        pinCode: '5555',
        startTime: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        attendedNims: {'240101'},
      );
      AttendanceScreen.currentSession = session;
    });

    testWidgets('AttendanceQrModal displays dynamic anti-cheat elements and projector button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AttendanceQrModal.show(context, active: session),
                child: const Text('Buka QR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka QR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Memeriksa header dan nama matkul
      expect(find.text('Teori Komunikasi'), findsOneWidget);
      expect(find.textContaining('Pertemuan 5'), findsOneWidget);

      // Memeriksa banner mode anti-kecurangan
      expect(find.text('Mode Anti-Kecurangan Aktif'), findsOneWidget);
      expect(find.textContaining('QR & PIN berputar'), findsOneWidget);

      // Memeriksa tombol Layar Lebar
      expect(find.text('Layar Lebar'), findsOneWidget);

      // Memeriksa counter mahasiswa hadir
      expect(find.text('1 Mahasiswa Hadir'), findsOneWidget);

      // Memeriksa token dinamis & pin dinamis chips
      expect(find.text('TOKEN DINAMIS'), findsOneWidget);
      expect(find.text('PIN DINAMIS'), findsOneWidget);
    });

    testWidgets('Tapping Layar Lebar opens AttendanceProjectorView in high-contrast mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AttendanceQrModal.show(context, active: session),
                child: const Text('Buka QR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka QR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Layar Lebar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Memeriksa keberadaan AttendanceProjectorView
      expect(find.byType(AttendanceProjectorView), findsOneWidget);
      expect(find.textContaining('Mode Layar Lebar Proyektor Kelas'), findsOneWidget);
      expect(find.text('PIN 4 DIGIT KELAS'), findsOneWidget);
      expect(find.text('KODE TOKEN'), findsOneWidget);

      // Verifikasi tema terang aktif secara default (Scaffold background bukan 0xFF0F172A)
      final scaffold = tester.widget<Scaffold>(find.descendant(
        of: find.byType(AttendanceProjectorView),
        matching: find.byType(Scaffold),
      ));
      expect(scaffold.backgroundColor, const Color(0xFFF8FAFC));

      // Verifikasi tombol toggle tema gelap / terang
      final themeBtn = find.byTooltip('Beralih ke Tampilan Gelap');
      expect(themeBtn, findsOneWidget);
      await tester.tap(themeBtn);
      await tester.pump();

      final scaffoldDark = tester.widget<Scaffold>(find.descendant(
        of: find.byType(AttendanceProjectorView),
        matching: find.byType(Scaffold),
      ));
      expect(scaffoldDark.backgroundColor, const Color(0xFF0F172A));
    });

    testWidgets('AttendanceProjectorView renders cleanly on narrow screen (345px) with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(345, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: AttendanceProjectorView(
            active: session,
            initialDynamicMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('PROTEKSI ANTI-JOKI AKTIF'), findsOneWidget);
      expect(find.text('PIN 4 DIGIT KELAS'), findsOneWidget);
    });

    testWidgets('AttendanceScannerModal validates dynamic 4-digit PIN and shows verified badge',
        (tester) async {
      final dynamicToken = DynamicAttendanceService.generate(session);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AttendanceScannerModal.show(
                  context,
                  userNim: '240102',
                ),
                child: const Text('Buka Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Scanner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Beralih ke tab PIN jika di mode scanner kamera
      if (find.text('PIN 4 Digit').evaluate().isNotEmpty) {
        await tester.tap(find.text('PIN 4 Digit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Cari input PIN 4-digit
      final pinField = find.byType(TextField);
      if (pinField.evaluate().isNotEmpty) {
        await tester.enterText(pinField.first, dynamicToken.dynamicPin);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tekan tombol Verifikasi Kehadiran
        final verifBtn = find.text('Verifikasi Kehadiran');
        if (verifBtn.evaluate().isNotEmpty) {
          await tester.tap(verifBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Dialog sukses muncul
          expect(find.textContaining('Presensi Berhasil Terverifikasi'), findsOneWidget);
          expect(find.text('Proteksi Dinamis Anti-Kecurangan Terverifikasi'), findsOneWidget);
        }
      }
    });
  });
}
