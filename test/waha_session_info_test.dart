import 'package:class_manager/core/services/waha_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Existing project cloud URL moves to reminder gateway while custom URLs stay intact', () async {
    SharedPreferences.setMockInitialValues({
      'waha_base_url': 'https://waha-production-717b.up.railway.app/',
      'waha_api_key': 'existing-key',
    });
    expect(await WahaService.getBaseUrl(), WahaService.defaultCloudUrl);
    expect(await WahaService.getApiKey(), 'existing-key');
    SharedPreferences.setMockInitialValues({'waha_base_url': 'https://custom.example'});
    expect(await WahaService.getBaseUrl(), 'https://custom.example');
  });

  test('WahaService saves settings locally and preserves them across reloads', () async {
    SharedPreferences.setMockInitialValues({});
    await WahaService.saveSettings(
      baseUrl: 'https://gateway.example.com/',
      apiKey: 'secret-key-123',
      sessionName: 'kampus',
      defaultGroupId: '123456@g.us',
      isCloudMode: true,
      syncToCloud: false,
    );

    expect(await WahaService.getBaseUrl(), 'https://gateway.example.com');
    expect(await WahaService.getApiKey(), 'secret-key-123');
    expect(await WahaService.getSessionName(), 'kampus');
    expect(await WahaService.getDefaultGroupId(), '123456@g.us');
    expect(await WahaService.isCloudMode(), isTrue);
  });

  for (final stopStatus in [200, 500]) {
    test('Failed session recovery stops engine first (stop HTTP $stopStatus)', () async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'GET') {
          return http.Response('{"status":"FAILED"}', 200);
        }
        if (request.url.path.endsWith('/stop')) return http.Response('{}', stopStatus);
        return http.Response('{}', 201);
      });
      final ok = await http.runWithClient(WahaService.startSession, () => client);
      expect(ok, stopStatus == 200);
      expect(calls, [
        'GET /api/sessions/default',
        'POST /api/sessions/default/stop',
        if (stopStatus == 200) 'POST /api/sessions/default/start',
      ]);
      client.close();
    });
  }

  test('Only gateways advertising reminder support enable reminder controls', () {
    expect(WahaSessionInfo.fromJson({
      'status': 'WORKING', 'engine': {'engine': 'WEBJS'},
    }).supportsAutoReminder, isFalse);
    expect(WahaSessionInfo.fromJson({
      'status': 'STOPPED', 'engine': 'BAILEYS_NATIVE',
    }).supportsAutoReminder, isTrue);
    expect(WahaSessionInfo.fromJson({
      'status': 'WORKING', 'capabilities': ['auto-reminder'],
    }).supportsAutoReminder, isTrue);
  });
}
