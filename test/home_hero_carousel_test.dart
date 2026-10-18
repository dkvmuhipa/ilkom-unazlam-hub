import 'package:class_manager/features/dashboard/widgets/home_banner_carousel.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  for (final width in [320.0, 768.0]) {
    testWidgets('Hero can be swiped manually at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      int? destination;
      Widget buildHero({bool hasTask = true}) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: HomeBannerCarousel(
            todayCourses: const [],
            upcomingCourses: const [],
            nextAssignment: hasTask
                ? Assignment(
                    id: 'task',
                    courseId: 'course',
                    courseName: 'Metode Penelitian Ilmu Komunikasi',
                    judul: 'Laporan penelitian komunikasi masyarakat dan media digital',
                    deskripsi: '',
                    kategori: 'Individu',
                    deadline: DateTime.now().add(const Duration(days: 2)),
                  )
                : null,
            latestAnnouncement: null,
            hasLoadError: false,
            onNavigateTab: (value) => destination = value,
          ),
        ),
      );
      await tester.pumpWidget(buildHero());
      await tester.pumpAndSettle();
      expect(find.text('RINGKASAN HARI INI'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width >= 600) {
        await tester.tap(find.byTooltip('Informasi berikutnya'));
      } else {
        await tester.drag(find.byType(PageView), Offset(-width, 0));
      }
      await tester.pumpAndSettle();
      expect(find.text('TUGAS TERDEKAT'), findsOneWidget);
      await tester.tap(find.text('Lihat tugas'));
      expect(destination, 2);
      expect(tester.takeException(), isNull);
      // Refreshing data while a removed slide is selected must reset safely.
      await tester.pumpWidget(buildHero(hasTask: false));
      await tester.pumpAndSettle();
      expect(find.text('RINGKASAN HARI INI'), findsOneWidget);
      expect(find.byTooltip('Informasi 2 dari 2'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
