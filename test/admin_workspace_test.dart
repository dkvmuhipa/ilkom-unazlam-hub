import 'dart:convert';

import 'package:class_manager/features/admin/widgets/admin_broadcast_hub_modal.dart';
import 'package:class_manager/features/admin/widgets/admin_bulk_csv_modal.dart';
import 'package:class_manager/features/admin/widgets/admin_waha_gateway_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _message(String message, {bool isError = false}) {}
void _record({
  required String action,
  required String module,
  required String description,
  Map<String, dynamic>? metadata,
}) {}

void main() {
  final pages = <String, void Function(BuildContext)>{
    'WhatsApp': (context) {
      AdminWahaGatewayModal.show(context: context, onShowMessage: _message);
    },
    'Pengumuman': (context) {
      AdminBroadcastHubModal.show(
        context: context,
        classes: const [],
        onRefresh: () async {},
        onShowMessage: _message,
        onRecordAudit: _record,
      );
    },
    'Impor': (context) {
      AdminBulkCsvModal.show(
        context,
        onReload: () async {},
        onShowMessage: _message,
        onRecordAudit: _record,
      );
    },
  };
  for (final page in pages.entries) {
    testWidgets(
      '${page.key} opens as a full page with working back navigation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = MockClient(
          (request) async => http.Response(
            jsonEncode({'name': 'default', 'status': 'STOPPED'}),
            200,
          ),
        );
        await http.runWithClient(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => page.value(context),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          for (var index = 0; index < 15; index++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          if (page.key == 'WhatsApp')
            expect(
              tester
                  .widget<AdminWahaGatewayModal>(
                    find.byType(AdminWahaGatewayModal),
                  )
                  .fullPage,
              isTrue,
            );
          if (page.key == 'Pengumuman')
            expect(
              tester
                  .widget<AdminBroadcastHubModal>(
                    find.byType(AdminBroadcastHubModal),
                  )
                  .fullPage,
              isTrue,
            );
          if (page.key == 'Impor')
            expect(
              tester
                  .widget<AdminBulkCsvModal>(find.byType(AdminBulkCsvModal))
                  .fullPage,
              isTrue,
            );
          expect(tester.takeException(), isNull);
          tester.state<NavigatorState>(find.byType(Navigator)).pop();
          await tester.pumpAndSettle();
          expect(find.text('Open'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
        }, () => client);
        client.close();
      },
    );
  }
}
