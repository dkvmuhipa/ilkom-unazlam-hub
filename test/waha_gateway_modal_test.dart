import 'dart:convert';

import 'package:class_manager/features/admin/widgets/admin_waha_gateway_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Connected WAHA details fit width $width with enlarged text', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final client = MockClient((request) async => http.Response(jsonEncode({
        'name': 'default', 'status': 'WORKING', 'engine': {'engine': 'NOWEB'},
        'me': {'id': '628123456789@c.us', 'pushName': 'Admin'},
      }), 200));
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(body: AdminWahaGatewayModal(onShowMessage: (message, {isError = false}) {})),
        ));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('TERHUBUNG (ONLINE)'), findsOneWidget);
        expect(find.text('750ms Throttle'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);
      client.close();
    });
  }
  testWidgets('WAHA keeps polling through startup and shows notices in dialog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var status = 'SCAN_QR_CODE';
    var parentNotices = 0;
    var reminderRequests = 0;
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions/default') {
        return http.Response(jsonEncode({
          'name': 'default', 'status': status,
          if (status == 'WORKING') 'me': {'id': '628123456789@c.us', 'pushName': 'Admin'},
        }), 200);
      }
      if (request.url.path == '/api/auto-reminder/config') {
        reminderRequests++;
        return http.Response('{"config":{}}', 200);
      }
      return http.Response('', 404);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdminWahaGatewayModal(
        onShowMessage: (message, {isError = false}) => parentNotices++,
      ))));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('MENUNGGU SCAN QR CODE'), findsOneWidget);
      status = 'STARTING';
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('MEMULAI ENGINE...'), findsOneWidget);
      status = 'WORKING';
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('TERHUBUNG (ONLINE)'), findsOneWidget);
      expect(find.text('WhatsApp berhasil ditautkan ke akun kampus!'), findsOneWidget);
      expect(parentNotices, 0);
      expect(reminderRequests, 0, reason: 'WAHA Core has no auto-reminder endpoint');
      expect(tester.takeException(), isNull);
      // Continue monitoring a later disconnect rather than leaving a stale green badge.
      status = 'STOPPED';
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(find.text('SESI DIMATIKAN'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
    client.close();
  });
}
