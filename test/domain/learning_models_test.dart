import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';

void main() {
  group('Course', () {
    test('map round-trip; toMap omits trash/archive columns', () {
      final c = Course(
        title: 'C',
        description: 'd',
        color: const Color(0xFF00FF00),
        source: CourseSource.aiGenerated,
        status: CourseStatus.paused,
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      final map = c.toMap();
      expect(map.containsKey('isDeleted'), isFalse);
      expect(map.containsKey('isArchived'), isFalse);
      expect(map['source'], 'aiGenerated');
      expect(map['status'], 'paused');
      expect(Course.fromMap(map), c);
    });

    test('unknown enum strings fall back to defaults', () {
      expect(CourseStatus.parse('completed'), CourseStatus.active);
      expect(CourseStatus.parse(null), CourseStatus.active);
      expect(CourseSource.parse('imported'), CourseSource.manual);
      final c = Course.fromMap({'id': 'x', 'status': '??', 'source': 1});
      expect(c.status, CourseStatus.active);
      expect(c.source, CourseSource.manual);
      expect(c.title, '');
    });
  });

  group('CourseModule', () {
    test('map round-trip', () {
      final m = CourseModule(
        courseId: 'c',
        title: 'M',
        description: 'd',
        sortOrder: 4,
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      expect(CourseModule.fromMap(m.toMap()), m);
    });
  });

  group('Lesson', () {
    test('map round-trip with links and noteIds', () {
      final l = Lesson(
        moduleId: 'm',
        title: 'L',
        contentJson: '{"document":{}}',
        links: const [
          LessonLink(title: 'A', url: 'https://a.example'),
          LessonLink(title: '', url: 'http://b.example'),
        ],
        noteIds: const ['n1'],
        sortOrder: 1,
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      expect(Lesson.fromMap(l.toMap()), l);
    });

    test('corrupt / NULL JSON columns decode to []', () {
      final l = Lesson.fromMap({
        'id': 'x',
        'moduleId': 'm',
        'links': 'not json',
        'noteIds': null,
        'contentJson': null,
      });
      expect(l.links, isEmpty);
      expect(l.noteIds, isEmpty);
      expect(l.contentJson, '');
      expect(Lesson.decodeLinks('{"a":1}'), isEmpty);
      expect(Lesson.decodeLinks('[{"title":"t"},{"url":"https://x.y"}, 3]'),
          [const LessonLink(title: '', url: 'https://x.y')]);
      expect(Lesson.decodeNoteIds('["a", 1, ""]'), ['a']);
    });
  });

  group('LessonProgress', () {
    test('toMap id == lessonId; round-trip', () {
      final p = LessonProgress(
        lessonId: 'l1',
        status: LessonStatus.completed,
        startedAt: DateTime(2026, 1, 1),
        completedAt: DateTime(2026, 1, 3),
        lastOpenedAt: DateTime(2026, 1, 2),
        updateTimeStamp: DateTime(2026, 1, 3),
      );
      expect(p.toMap()['id'], 'l1');
      expect(LessonProgress.fromMap(p.toMap()), p);
    });

    test('unknown status → notStarted; notStarted factory', () {
      expect(LessonStatus.parse('done'), LessonStatus.notStarted);
      final p = LessonProgress.notStarted('l');
      expect(p.status, LessonStatus.notStarted);
      expect(p.startedAt, isNull);
    });
  });
}
