import 'package:class_manager/features/admin/widgets/admin_common_widgets.dart';
import 'package:class_manager/features/admin/views/admin_classes_view.dart';
import 'package:class_manager/features/admin/models/admin_models.dart';
import 'package:class_manager/features/admin/widgets/admin_student_summary.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('New class uses configured year and preserves typed name on rebuild', (tester) async {
    Widget screen() => MaterialApp(home: Scaffold(body: AdminClassesView(
      isAddMode: true, classes: const [],
      academicYears: [AcademicYearItem(tahun: '2028/2029', isAktif: true)],
      courses: const [], managedAccounts: const [], isLoading: false, loadError: null,
      onBack: () {}, onNavigate: (view, {student}) {}, onReload: () async {},
      onShowMessage: (message, {isError = false}) {},
      onRecordAudit: ({required action, required module, required description, metadata}) {},
      onConfirmDelete: (prompt) async => false,
    )));
    await tester.pumpWidget(screen());
    expect(find.text('2028/2029'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Kelas A');
    await tester.pumpWidget(screen());
    expect(find.text('Kelas A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Admin header has no inert search action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: AdminAppBar(title: 'Admin'),
    )));
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });

  testWidgets('Unavailable student data shows errors rather than fake results', (tester) async {
    final messages = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: AdminStudentSummary(
        student: StudentProfile(id: 'test', nim: '123', nama: 'Mahasiswa', email: '', noWa: ''),
        onShowMessage: (message, {isError = false}) => messages.add(message),
      ),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Kehadiran gagal dimuat. Coba muat ulang.'), findsOneWidget);
    expect(find.text('Status kas gagal dimuat. Coba muat ulang.'), findsOneWidget);
    expect(find.textContaining('92%'), findsNothing);
    expect(find.textContaining(': Lunas'), findsNothing);
    await tester.tap(find.text('Ekspor Kartu Hasil Studi (KHS)'));
    await tester.pumpAndSettle();
    expect(messages.single, startsWith('Ekspor gagal:'));
    expect(tester.takeException(), isNull);
  });
}
