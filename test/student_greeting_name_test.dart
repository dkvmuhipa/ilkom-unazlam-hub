import 'package:flutter_test/flutter_test.dart';
import 'package:class_manager/models/models.dart';

void main() {
  group('StudentProfile Greeting Name Tests', () {
    final baseStudent = StudentProfile(
      id: '1',
      nim: '210101001',
      nama: 'Budi Santoso Nugroho',
      email: 'budi@stiencas.ac.id',
      noWa: '081234567890',
      kelas: 'IK-2A',
      semester: 4,
      role: 'MAHASISWA',
    );

    test('Defaults to first name when namaPanggilan is null', () {
      expect(baseStudent.namaPanggilan, isNull);
      expect(baseStudent.greetingName, equals('Budi'));
    });

    test('Defaults to first name when namaPanggilan is empty or whitespace', () {
      final studentWithEmpty = baseStudent.copyWith(namaPanggilan: '   ');
      expect(studentWithEmpty.greetingName, equals('Budi'));
    });

    test('Uses custom namaPanggilan when explicitly set', () {
      final studentWithNick = baseStudent.copyWith(namaPanggilan: 'Budianto');
      expect(studentWithNick.namaPanggilan, equals('Budianto'));
      expect(studentWithNick.greetingName, equals('Budianto'));
    });

    test('Handles last name as namaPanggilan correctly', () {
      final studentWithLastName = baseStudent.copyWith(namaPanggilan: 'Nugroho');
      expect(studentWithLastName.greetingName, equals('Nugroho'));
    });

    test('Handles single-word names and excess spacing properly', () {
      final singleWordStudent = StudentProfile(
        id: '2',
        nim: '210101002',
        nama: '  Siti  ',
        email: 'siti@stiencas.ac.id',
        noWa: '081234567891',
        kelas: 'IK-2A',
        semester: 4,
        role: 'MAHASISWA',
      );
      expect(singleWordStudent.greetingName, equals('Siti'));
    });

    test('copyWith preserves namaPanggilan when not provided', () {
      final studentWithNick = baseStudent.copyWith(namaPanggilan: 'Mas Budi');
      final updatedSemester = studentWithNick.copyWith(semester: 5);
      expect(updatedSemester.namaPanggilan, equals('Mas Budi'));
      expect(updatedSemester.greetingName, equals('Mas Budi'));
      expect(updatedSemester.semester, equals(5));
    });
  });
}
