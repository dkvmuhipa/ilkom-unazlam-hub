import 'dart:convert';

import 'package:class_manager/features/treasury/widgets/treasury_bulk_reminder_modal.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final sampleStudents = [
    StudentProfile(
      id: 's1',
      nim: '202401001',
      nama: 'Ahmad Fadhil',
      email: 'ahmad@unazlam.ac.id',
      noWa: '081234567890',
    ),
    StudentProfile(
      id: 's2',
      nim: '202401002',
      nama: 'Bunga Citra',
      email: 'bunga@unazlam.ac.id',
      noWa: '081234567891',
    ),
    StudentProfile(
      id: 's3',
      nim: '202401003',
      nama: 'Candra Wijaya',
      email: 'candra@unazlam.ac.id',
      noWa: '', // No WA kosong
    ),
  ];

  final iuranStatus = {
    '202401001': false, // Belum lunas
    '202401002': false, // Belum lunas
    '202401003': true,  // Lunas
  };

  final iuranNominal = {
    '202401001': 20000,
    '202401002': 20000,
    '202401003': 20000,
  };

  for (final width in [320.0, 390.0]) {
    testWidgets('TreasuryBulkReminderModal fits width $width without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final client = MockClient((request) async {
        if (request.url.path == '/api/sessions/default') {
          return http.Response(
            jsonEncode({
              'name': 'default',
              'status': 'WORKING',
              'me': {'id': '628123456789@c.us', 'pushName': 'Bendahara'},
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: TreasuryBulkReminderModal(
              students: sampleStudents,
              iuranStatus: iuranStatus,
              iuranNominal: iuranNominal,
              periodLabel: 'Oktober 2026',
            ),
          ),
        ));

        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.text('Tagih Kas Massal via WAHA'), findsOneWidget);
        expect(find.text('2 Belum Lunas'), findsOneWidget);
        expect(find.text('WAHA GATEWAY ONLINE'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);

      client.close();
    });
  }

  testWidgets('TreasuryBulkReminderModal toggles select all and triggers sending', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var sendTextMessageCount = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions/default') {
        return http.Response(
          jsonEncode({
            'name': 'default',
            'status': 'WORKING',
            'me': {'id': '628123456789@c.us', 'pushName': 'Bendahara'},
          }),
          200,
        );
      }
      if (request.url.path == '/api/sendText') {
        sendTextMessageCount++;
        return http.Response(
          jsonEncode({'id': 'msg_test_$sendTextMessageCount'}),
          200,
        );
      }
      return http.Response('', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TreasuryBulkReminderModal(
            students: sampleStudents,
            iuranStatus: iuranStatus,
            iuranNominal: iuranNominal,
            periodLabel: 'Oktober 2026',
          ),
        ),
      ));

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 2 students are unpaid, but both have noWa, so both are selected initially
      expect(find.textContaining('Kirim Tagihan ke 2 Mahasiswa'), findsOneWidget);

      // Tap Batal Semua
      await tester.tap(find.text('Batal Semua'));
      await tester.pump();
      expect(find.text('Pilih Semua'), findsOneWidget);
      expect(find.text('Pilih Mahasiswa Penerima'), findsOneWidget);

      // Tap Pilih Semua
      await tester.tap(find.text('Pilih Semua'));
      await tester.pump();
      expect(find.textContaining('Kirim Tagihan ke 2 Mahasiswa'), findsOneWidget);

      // Start sending
      await tester.tap(find.textContaining('Kirim Tagihan ke 2 Mahasiswa'));
      await tester.pump();

      // Pump timers for throttle delays
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(sendTextMessageCount, 2);
      expect(find.text('Semua Pesan Berhasil Terkirim! 🚀'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);

    client.close();
  });
}
