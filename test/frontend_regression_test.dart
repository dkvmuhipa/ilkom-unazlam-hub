import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/core/widgets/scale_button.dart';
import 'package:class_manager/features/dashboard/widgets/more_services_modal.dart';
import 'package:class_manager/features/notifications/notification_screen.dart';
import 'package:class_manager/models/models.dart';

void main() {
  Future<void> openServices(
    WidgetTester tester, {
    double width = 360,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => MoreServicesModal.show(
                context,
                isDark: false,
                student: StudentProfile(
                  id: 'audit',
                  nim: 'audit',
                  nama: 'Audit',
                  email: '',
                  noWa: '',
                  role: 'ADMIN',
                ),
                onNavigateTab: (_) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Clear search resets visible field and results', (tester) async {
    await openServices(tester);
    await tester.enterText(find.byType(TextField), 'Presensi');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(find.text('Jadwal Kuliah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 430.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Services fit width $width text $scale with keyboard', (
        tester,
      ) async {
        await openServices(tester, width: width, scale: scale);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ScaleButton activates once using keyboard and skips disabled', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const ScaleButton(child: Text('Disabled')),
              ScaleButton(onTap: () => count++, child: const Text('Action')),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(count, 1);
  });

  Course course({CourseScheduleOverride? override}) => Course(
    id: 'course',
    kode: 'C1',
    nama: 'Komunikasi',
    sks: 2,
    semester: 1,
    dosen: 'Dosen',
    hari: 'Senin',
    jamMulai: '08:00',
    jamSelesai: '10:00',
    ruangan: 'A',
    override: override,
  );

  test('Schedule notification identity belongs to meeting date', () {
    final first = buildScheduleNotificationItems(
      [course()],
      DateTime(2026, 10, 19),
      isToday: false,
    ).single;
    final same = buildScheduleNotificationItems(
      [course()],
      DateTime(2026, 10, 19),
      isToday: true,
    ).single;
    final next = buildScheduleNotificationItems(
      [course()],
      DateTime(2026, 10, 26),
      isToday: true,
    ).single;
    expect(first.id, same.id);
    expect(next.id, isNot(first.id));
  });

  test('Schedule notifications use effective hours and room', () {
    final updated = course(
      override: CourseScheduleOverride(
        id: 'override',
        courseId: 'course',
        overrideDate: DateTime(2026, 10, 19),
        status: 'RESCHEDULED',
        originalJamMulai: '08:00',
        newJamMulai: '13:00',
        newJamSelesai: '15:00',
        newRuangan: 'B',
      ),
    );
    final item = buildScheduleNotificationItems(
      [updated],
      DateTime(2026, 10, 19),
      isToday: true,
    ).single;
    expect(item.message, contains('13:00 - 15:00'));
    expect(item.message, contains('B'));
    expect(item.message, isNot(contains('08:00')));
  });

  test('Cancelled meeting produces cancellation notice', () {
    final cancelled = course(
      override: CourseScheduleOverride(
        id: 'override',
        courseId: 'course',
        overrideDate: DateTime(2026, 10, 19),
        status: 'CANCELLED',
        originalJamMulai: '08:00',
        alasan: 'Dosen berhalangan',
      ),
    );
    final item = buildScheduleNotificationItems(
      [cancelled],
      DateTime(2026, 10, 19),
      isToday: true,
    ).single;
    expect(item.title, contains('dibatalkan'));
    expect(item.message, 'Dosen berhalangan');
  });
}
