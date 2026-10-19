import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:class_manager/features/admin/models/admin_models.dart';
import 'package:class_manager/features/admin/admin_shell_screen.dart';
import 'package:class_manager/features/admin/widgets/admin_detail_page.dart';
import 'package:class_manager/features/admin/create_student_account_dialog.dart';
import 'package:class_manager/features/admin/edit_student_account_dialog.dart';
import 'package:class_manager/features/admin/views/admin_academic_year_view.dart';
import 'package:class_manager/features/admin/views/admin_account_management_view.dart';
import 'package:class_manager/features/admin/views/admin_attendance_matrix_view.dart';
import 'package:class_manager/features/admin/views/admin_classes_view.dart';
import 'package:class_manager/features/admin/views/admin_courses_view.dart';
import 'package:class_manager/features/admin/views/admin_lecturers_view.dart';
import 'package:class_manager/features/admin/views/admin_reports_view.dart';
import 'package:class_manager/features/admin/views/admin_roles_view.dart';
import 'package:class_manager/features/admin/views/admin_students_view.dart';
import 'package:class_manager/features/admin/views/admin_system_settings_view.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void _back() {}
Future<void> _reload() async {}
void _message(String message, {bool isError = false}) {}
void _navigate(String view, {StudentProfile? student}) {}
void _record({
  required String action,
  required String module,
  required String description,
  Map<String, dynamic>? metadata,
}) {}
Future<bool> _confirm(String prompt) async => false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Poppins');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  GoogleFonts.config.allowRuntimeFetching = false;
  final student = StudentProfile(
    id: '1',
    nim: '202610180001',
    nama: 'Mahasiswa Dengan Nama Sangat Panjang',
    email: 'mahasiswa@example.com',
    noWa: '628123456789',
    jabatan: 'Ketua Kelas',
  );
  final students = [student];
  final years = [AcademicYearItem(tahun: '2026/2027', isAktif: true)];
  final classes = [
    ClassItem(nama: 'Ilmu Komunikasi', semester: 1, jumlahMahasiswa: 1),
  ];
  final courses = [
    Course.fromMap({
      'id': 'course',
      'kode_mk': 'ILK101',
      'nama_mk': 'Pengantar Komunikasi dan Media',
      'dosen': 'Dosen Dengan Nama Panjang',
      'hari': 'Senin',
      'jam_mulai': '08:00',
      'jam_selesai': '10:00',
    }),
  ];
  Widget studentPage(bool detail) => AdminStudentsView(
    isDetailMode: detail,
    selectedStudent: student,
    managedAccounts: students,
    courses: courses,
    onBack: _back,
    onNavigate: _navigate,
    onReload: _reload,
    onShowMessage: _message,
    onEditAccount: (_) async {},
    onSetActive: (_, _) async {},
    onDeleteAccount: (_) async {},
    onCreateAccount: _back,
  );
  final pages = <String, Widget Function()>{
    'dashboard': () =>
        AdminShellScreen(onLogout: _back, onSwitchToStudentView: _back),
    'students': () => studentPage(false),
    'student detail': () => studentPage(true),
    'classes': () => AdminClassesView(
      classes: classes,
      academicYears: years,
      courses: courses,
      managedAccounts: students,
      isLoading: false,
      loadError: null,
      onBack: _back,
      onNavigate: _navigate,
      onReload: _reload,
      onShowMessage: _message,
      onRecordAudit: _record,
      onConfirmDelete: _confirm,
    ),
    'courses': () => AdminCoursesView(
      courses: courses,
      isLoading: false,
      loadError: null,
      onBack: _back,
      onReload: _reload,
      onShowMessage: _message,
      onRecordAudit: _record,
      onConfirmDelete: _confirm,
    ),
    'lecturers': () => AdminLecturersView(
      lecturers: [
        LecturerItem(
          id: '1',
          nama: 'Dosen Dengan Nama Sangat Panjang',
          mataKuliah: courses.first.nama,
          email: 'dosen@example.com',
        ),
      ],
      courses: courses,
      isLoading: false,
      loadError: null,
      onBack: _back,
      onReload: _reload,
      onShowMessage: _message,
      onRecordAudit: _record,
      onConfirmDelete: _confirm,
    ),
    'years': () => AdminAcademicYearView(
      academicYears: years,
      isLoading: false,
      loadError: null,
      onBack: _back,
      onReload: _reload,
      onShowMessage: _message,
      onRecordAudit: _record,
      onConfirmDelete: _confirm,
    ),
    'accounts': () => AdminAccountManagementView(
      managedAccounts: students,
      isLoading: false,
      loadError: null,
      onBack: _back,
      onReload: _reload,
      onShowMessage: _message,
      onRecordAudit: _record,
      onConfirmDelete: _confirm,
    ),
    'roles': () => AdminRolesView(
      managedAccounts: students,
      selectedStudent: student,
      onBack: _back,
      onRecordAudit: _record,
    ),
    'reports': () => AdminReportsView(
      reportFuture: Future.value({
        'attendance': 'Kehadiran tercatat: 100%',
        'treasury': 'Saldo Rp 100.000',
      }),
      managedAccounts: students,
      onRefresh: _back,
      onBack: _back,
      onNavigate: _navigate,
    ),
    'settings': () => AdminSystemSettingsView(
      onBack: _back,
      onLogout: _back,
      onNavigate: _navigate,
      onBroadcastAnnouncement: _back,
      registeredTokensCount: 10,
      academicYears: years,
      classes: classes,
      lecturers: const [],
      courses: courses,
      onShowMessage: _message,
      onRecordAudit: _record,
    ),
    'attendance': () => AdminAttendanceMatrixView(
      courses: const [],
      classes: classes,
      managedAccounts: students,
      onBack: _back,
      onShowMessage: _message,
      onRecordAudit: _record,
    ),
  };
  final dialogs = <String, Widget Function()>{
    'create account': () => const CreateStudentAccountDialog(),
    'edit account': () => EditStudentAccountDialog(account: student),
  };
  for (final detail in {
    'classes': 'Ilmu Komunikasi',
    'courses': courses.first.nama,
    'lecturers': 'Dosen Dengan Nama Sangat Panjang',
  }.entries) {
    testWidgets('${detail.key} detail page fits small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Poppins'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: pages[detail.key]!()),
          ),
        ),
      );
      await tester.tap(find.text(detail.value).first);
      await tester.pumpAndSettle();
      expect(find.byType(AdminDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      const previewDir = String.fromEnvironment('ADMIN_PREVIEW_DIR');
      if (previewDir.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ImageByteFormat.png);
          await Directory(previewDir).create(recursive: true);
          await File('$previewDir/${detail.key}-detail.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      final tabs = tester
          .widgetList<Tab>(find.byType(Tab))
          .map((tab) => tab.text!)
          .toList();
      for (final tab in tabs) {
        await tester.ensureVisible(find.widgetWithText(Tab, tab)); await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(Tab, tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final scrolls = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (scrolls.evaluate().isNotEmpty) {
        await tester.drag(scrolls.last, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDetailPage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final dialog in dialogs.entries) {
    testWidgets('${dialog.key} fits small screen with keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
              viewInsets: const EdgeInsets.only(bottom: 240),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => dialog.value(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final label in [
    'Profil Aplikasi',
    'Notifikasi',
    'Tentang Aplikasi',
    'Backup Data',
  ]) {
    testWidgets('$label dialog fits narrow landscape screen', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(body: pages['settings']!()),
        ),
      );
      await tester.scrollUntilVisible(
        find.text(label),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.byType(label == 'Backup Data' ? AlertDialog : AdminDetailPage),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final page in pages.entries) {
      testWidgets('${page.key} fits $width with enlarged text', (tester) async {
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details, forceReport: true);
          previousErrorHandler?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousErrorHandler);
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: page.value()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .hitTestable();
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
