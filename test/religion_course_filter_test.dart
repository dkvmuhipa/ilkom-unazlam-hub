import 'package:class_manager/core/services/course_schedule_service.dart';
import 'package:class_manager/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final coursePancasila = Course(
    id: 'c1',
    kode: '2 PK 100',
    nama: 'Pendidikan Pancasila',
    sks: 2,
    semester: 1,
    dosen: 'Drs. H. M. Rusli, M.Si',
    hari: 'Senin',
    jamMulai: '15:30',
    jamSelesai: '17:00',
    ruangan: 'Ruang A2',
  );

  final courseIslam = Course(
    id: 'c3',
    kode: '3 PK 101A',
    nama: 'Pendidikan Agama Islam *',
    sks: 3,
    semester: 1,
    dosen: 'Dr. H. Lukman Hakim, M.Ag',
    hari: 'Selasa',
    jamMulai: '15:30',
    jamSelesai: '17:45',
    ruangan: 'Ruang A1',
  );

  final courseKristen = Course(
    id: 'c4',
    kode: '3 PK 101B',
    nama: 'Pendidikan Agama Kristen *',
    sks: 3,
    semester: 1,
    dosen: 'Pdt. Dr. Markus Somba, M.Th',
    hari: 'Selasa',
    jamMulai: '15:30',
    jamSelesai: '17:45',
    ruangan: 'Ruang B1',
  );

  final allCourses = [coursePancasila, courseIslam, courseKristen];

  group('CourseScheduleService Religion Detection', () {
    test('isReligionCourse correctly detects religion courses', () {
      expect(CourseScheduleService.isReligionCourse(courseIslam), isTrue);
      expect(CourseScheduleService.isReligionCourse(courseKristen), isTrue);
      expect(CourseScheduleService.isReligionCourse(coursePancasila), isFalse);
    });

    test('detectCourseReligion returns correct religion identifiers', () {
      expect(CourseScheduleService.detectCourseReligion(courseIslam), equals('Islam'));
      expect(CourseScheduleService.detectCourseReligion(courseKristen), equals('Kristen'));
      expect(CourseScheduleService.detectCourseReligion(coursePancasila), isNull);
    });
  });

  group('CourseScheduleService Religion Matching & Filtering', () {
    test('Muslim student matches Islam and Pancasila, excludes Kristen', () {
      expect(CourseScheduleService.matchesStudentReligion(courseIslam, 'Islam'), isTrue);
      expect(CourseScheduleService.matchesStudentReligion(courseKristen, 'Islam'), isFalse);
      expect(CourseScheduleService.matchesStudentReligion(coursePancasila, 'Islam'), isTrue);

      final filtered = CourseScheduleService.filterCoursesByReligion(allCourses, 'Islam');
      expect(filtered.length, equals(2));
      expect(filtered.map((c) => c.kode), containsAll(['2 PK 100', '3 PK 101A']));
      expect(filtered.map((c) => c.kode), isNot(contains('3 PK 101B')));
    });

    test('Christian student matches Kristen and Pancasila, excludes Islam', () {
      expect(CourseScheduleService.matchesStudentReligion(courseKristen, 'Kristen Protestan'), isTrue);
      expect(CourseScheduleService.matchesStudentReligion(courseIslam, 'Kristen Protestan'), isFalse);
      expect(CourseScheduleService.matchesStudentReligion(coursePancasila, 'Kristen Protestan'), isTrue);

      final filtered = CourseScheduleService.filterCoursesByReligion(allCourses, 'Kristen Protestan');
      expect(filtered.length, equals(2));
      expect(filtered.map((c) => c.kode), containsAll(['2 PK 100', '3 PK 101B']));
      expect(filtered.map((c) => c.kode), isNot(contains('3 PK 101A')));
    });

    test('Student with null or empty religion defaults to Islam safely without double class', () {
      expect(CourseScheduleService.matchesStudentReligion(courseIslam, null), isTrue);
      expect(CourseScheduleService.matchesStudentReligion(courseKristen, null), isFalse);

      final filtered = CourseScheduleService.filterCoursesByReligion(allCourses, null);
      expect(filtered.length, equals(2));
      expect(filtered.map((c) => c.kode), contains('3 PK 101A'));
      expect(filtered.map((c) => c.kode), isNot(contains('3 PK 101B')));
    });
  });

  group('StudentProfile effectiveAgama', () {
    test('returns Islam by default when agama is null or empty', () {
      final p1 = StudentProfile(
        id: '1',
        nim: '123',
        nama: 'Danang',
        email: 'danang@example.com',
        noWa: '081',
      );
      expect(p1.effectiveAgama, equals('Islam'));

      final p2 = p1.copyWith(agama: 'Kristen Protestan');
      expect(p2.effectiveAgama, equals('Kristen Protestan'));
    });
  });
}
