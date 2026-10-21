import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/features/attendance/models/attendance_models.dart';
import 'package:class_manager/features/attendance/services/dynamic_attendance_service.dart';

void main() {
  group('DynamicAttendanceService Tests', () {
    late ActiveAttendanceSession session;

    setUp(() {
      session = ActiveAttendanceSession(
        id: 'session-uuid-1234',
        courseName: 'Komunikasi Visual',
        pertemuanKe: 3,
        token: 'VISUAL3',
        pinCode: '7890',
        startTime: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );
    });

    test('generates 4-digit PIN and 6-char token for current window', () {
      final token = DynamicAttendanceService.generate(session);
      expect(token.dynamicPin.length, 4);
      expect(RegExp(r'^\d{4}$').hasMatch(token.dynamicPin), isTrue);
      expect(token.dynamicToken.length, 6);
      expect(token.qrPayload.contains('"v":2'), isTrue);
      expect(token.qrPayload.contains(token.dynamicToken), isTrue);
      expect(token.qrPayload.contains(token.dynamicPin), isTrue);
    });

    test('verifies JSON QR dynamic payload successfully for current window', () {
      final token = DynamicAttendanceService.generate(session);
      final result = DynamicAttendanceService.verify(
        input: token.qrPayload,
        session: session,
      );

      expect(result.isValid, isTrue);
      expect(result.isDynamic, isTrue);
      expect(result.isExpiredDynamic, isFalse);
    });

    test('verifies dynamic 4-digit PIN successfully for current window', () {
      final token = DynamicAttendanceService.generate(session);
      final result = DynamicAttendanceService.verify(
        input: token.dynamicPin,
        session: session,
      );

      expect(result.isValid, isTrue);
      expect(result.isDynamic, isTrue);
    });

    test('verifies dynamic 6-char token successfully for current window', () {
      final token = DynamicAttendanceService.generate(session);
      final result = DynamicAttendanceService.verify(
        input: token.dynamicToken,
        session: session,
      );

      expect(result.isValid, isTrue);
      expect(result.isDynamic, isTrue);
    });

    test('accepts window -1 as grace period', () {
      final pastWindow = DynamicAttendanceService.currentWindow - 1;
      final pastToken = DynamicAttendanceService.generate(session, customWindow: pastWindow);

      final result = DynamicAttendanceService.verify(
        input: pastToken.qrPayload,
        session: session,
      );

      expect(result.isValid, isTrue);
      expect(result.isDynamic, isTrue);
    });

    test('rejects expired dynamic QR from 3 windows ago (>60s) as expiredDynamic', () {
      final oldWindow = DynamicAttendanceService.currentWindow - 3;
      final oldToken = DynamicAttendanceService.generate(session, customWindow: oldWindow);

      final result = DynamicAttendanceService.verify(
        input: oldToken.qrPayload,
        session: session,
      );

      expect(result.isValid, isFalse);
      expect(result.isExpiredDynamic, isTrue);
      expect(result.message.contains('kedaluwarsa'), isTrue);
    });

    test('accepts fallback static pinCode and token', () {
      final pinResult = DynamicAttendanceService.verify(
        input: '7890',
        session: session,
      );
      expect(pinResult.isValid, isTrue);
      expect(pinResult.isDynamic, isFalse);

      final tokenResult = DynamicAttendanceService.verify(
        input: 'VISUAL3',
        session: session,
      );
      expect(tokenResult.isValid, isTrue);
      expect(tokenResult.isDynamic, isFalse);
    });

    test('rejects invalid inputs', () {
      final result = DynamicAttendanceService.verify(
        input: 'WRONG_CODE_999',
        session: session,
      );
      expect(result.isValid, isFalse);
    });
  });
}
