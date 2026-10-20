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

  testWidgets('Hero displays multi-domain Kas and Presensi slides with 1-tap navigation', (tester) async {
    int? destination;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBannerCarousel(
            todayCourses: const [],
            upcomingCourses: const [],
            nextAssignment: null,
            latestAnnouncement: null,
            hasLoadError: false,
            isKasLunas: false,
            kasNominal: 20000,
            currentPeriodLabel: 'Oktober 2026',
            attendancePercent: 70,
            onNavigateTab: (value) => destination = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 0: Ringkasan Hari Ini
    expect(find.text('RINGKASAN HARI INI'), findsOneWidget);
    // Tap anywhere on slide 0 navigates to Schedule (tab 1)
    await tester.tap(find.text('Hari Bebas Kuliah ✨'));
    expect(destination, 1);

    // Swipe to Slide 1: Kas Kelas (Belum Bayar)
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('KAS KELAS'), findsOneWidget);
    expect(find.text('BELUM BAYAR'), findsOneWidget);
    expect(find.text('Tagihan Kas Rp 20.000'), findsOneWidget);
    // Tap card body navigates directly to Kas (tab 8)
    await tester.tap(find.text('KAS KELAS'));
    expect(destination, 8);

    // Swipe to Slide 2: Presensi Kuliah (Warning < 75%)
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('KEHADIRAN MAHASISWA'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('Perhatian: Kehadiran 70% ⚠️'), findsOneWidget);
    // Tap action button navigates to Presensi (tab 5)
    await tester.tap(find.text('Lihat presensi'));
    expect(destination, 5);
    expect(tester.takeException(), isNull);
  });
}

