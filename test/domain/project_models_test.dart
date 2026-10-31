import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';

/// Model tests for Core Track C6 (Project / ProjectItem).
void main() {
  group('Project', () {
    test('map round-trip keeps all fields', () {
      final p = Project(
        title: 'Website',
        description: 'Relaunch',
        color: const Color(0xFF112233),
        status: ProjectStatus.onHold,
        startDate: DateTime(2026, 2, 1),
        targetDate: DateTime(2026, 6, 30),
        createdAt: DateTime(2026, 1, 1),
        updateTimeStamp: DateTime(2026, 1, 2),
      );
      final map = p.toMap();
      expect(map['status'], 'onHold');
      expect(map.containsKey('isDeleted'), isFalse);
      expect(map.containsKey('isArchived'), isFalse);
      expect(map.containsKey('deviceId'), isFalse);
      expect(Project.fromMap(map), p);
    });

    test('unknown / null status → active', () {
      expect(ProjectStatus.parse('weird'), ProjectStatus.active);
      expect(ProjectStatus.parse(null), ProjectStatus.active);
      final p = Project.fromMap({'id': 'x', 'title': 'T', 'status': 'nope'});
      expect(p.status, ProjectStatus.active);
    });

    test('null dates stay null; trash/archive flags read from DB', () {
      final p = Project.fromMap({
        'id': 'x',
        'title': null,
        'startDate': null,
        'targetDate': null,
        'isDeleted': 1,
        'deletedAt': '2026-03-01T00:00:00.000',
        'isArchived': 0,
      });
      expect(p.title, '');
      expect(p.startDate, isNull);
      expect(p.targetDate, isNull);
      expect(p.isDeleted, isTrue);
      expect(p.deletedAt, DateTime(2026, 3, 1));
      expect(p.isArchived, isFalse);
    });

    test('copyWith clear flags', () {
      final p = Project(
          title: 'P',
          startDate: DateTime(2026, 1, 1),
          targetDate: DateTime(2026, 2, 1));
      final c = p.copyWith(clearStartDate: true, clearTargetDate: true);
      expect(c.startDate, isNull);
      expect(c.targetDate, isNull);
      expect(c.id, p.id);
      final s = p.copyWith(status: ProjectStatus.cancelled, title: 'Q');
      expect(s.status, ProjectStatus.cancelled);
      expect(s.title, 'Q');
      expect(s.startDate, p.startDate);
    });
  });

  group('ProjectItem', () {
    test('map round-trip', () {
      final i = ProjectItem(
        projectId: 'p1',
        entityType: ProjectEntityType.note,
        entityId: 'n1',
        sortOrder: 3,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(ProjectItem.fromMap(i.toMap()), i);
    });

    test('unknown entityType survives fromMap; sortOrder defaults to 0', () {
      final i = ProjectItem.fromMap({
        'id': 'i1',
        'projectId': 'p1',
        'entityType': 'document',
        'entityId': 'h1',
        'sortOrder': null,
        'createdAt': null,
      });
      expect(i.entityType, 'document');
      expect(i.sortOrder, 0);
      expect(ProjectEntityType.supported, isNot(contains('document')));
      // H3: 'habit' is now supported.
      expect(ProjectEntityType.supported, contains('habit'));
    });
  });
}
