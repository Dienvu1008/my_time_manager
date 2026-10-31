import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';

/// toMap → fromMap round-trips for the C5 goal models.
void main() {
  group('Goal', () {
    test('round-trips all persisted fields', () {
      final g = Goal(
        title: 'Run a marathon',
        description: 'Under 4h',
        color: const Color(0xFF123456),
        status: GoalStatus.paused,
        targetDate: DateTime(2027, 5, 1),
        createdAt: DateTime(2026, 1, 1, 8),
        updateTimeStamp: DateTime(2026, 1, 2, 9),
      );
      expect(Goal.fromMap(g.toMap()), g);
    });

    test('null targetDate round-trips; flags default when absent', () {
      final g = Goal(title: 'A');
      final back = Goal.fromMap(g.toMap());
      expect(back.targetDate, isNull);
      expect(back.isDeleted, isFalse);
      expect(back.isArchived, isFalse);
      expect(back.deletedAt, isNull);
      expect(back.archivedAt, isNull);
    });

    test('toMap does not write soft-delete/archive columns', () {
      final map = Goal(title: 'A').toMap();
      expect(map.containsKey('isDeleted'), isFalse);
      expect(map.containsKey('isArchived'), isFalse);
    });

    test('unknown or null status parses as active', () {
      final map = Goal(title: 'A').toMap();
      expect(Goal.fromMap({...map, 'status': 'weird'}).status,
          GoalStatus.active);
      expect(Goal.fromMap({...map, 'status': null}).status, GoalStatus.active);
    });

    test('reads isDeleted/isArchived from DB map', () {
      final map = {
        ...Goal(title: 'A').toMap(),
        'isDeleted': 1,
        'deletedAt': '2026-01-01T00:00:00.000',
        'isArchived': 1,
        'archivedAt': '2026-01-02T00:00:00.000',
      };
      final g = Goal.fromMap(map);
      expect(g.isDeleted, isTrue);
      expect(g.isArchived, isTrue);
      expect(g.deletedAt, DateTime(2026, 1, 1));
      expect(g.archivedAt, DateTime(2026, 1, 2));
    });

    test('copyWith clearTargetDate', () {
      final g = Goal(title: 'A', targetDate: DateTime(2027));
      expect(g.copyWith(clearTargetDate: true).targetDate, isNull);
      expect(g.copyWith(title: 'B').targetDate, DateTime(2027));
    });
  });

  group('Milestone', () {
    test('round-trips all fields', () {
      final m = Milestone(
        goalId: 'g1',
        title: 'Half',
        description: 'd',
        dueDate: DateTime(2026, 6, 1),
        isCompleted: true,
        completedAt: DateTime(2026, 5, 30),
        sortOrder: 3,
        updateTimeStamp: DateTime(2026, 5, 30, 10),
      );
      expect(Milestone.fromMap(m.toMap()), m);
    });

    test('null dueDate/completedAt round-trip', () {
      final m = Milestone(goalId: 'g1', title: 'X');
      final back = Milestone.fromMap(m.toMap());
      expect(back.dueDate, isNull);
      expect(back.completedAt, isNull);
      expect(back.isCompleted, isFalse);
      expect(back, m);
    });

    test('copyWith clearDueDate', () {
      final m = Milestone(goalId: 'g', title: 'X', dueDate: DateTime(2026));
      expect(m.copyWith(clearDueDate: true).dueDate, isNull);
    });
  });

  group('GoalLink', () {
    test('round-trips with and without milestoneId', () {
      final a = GoalLink(
        goalId: 'g',
        milestoneId: 'm',
        entityType: GoalEntityType.task,
        entityId: 't',
        createdAt: DateTime(2026, 1, 1),
      );
      final b = GoalLink(
          goalId: 'g', entityType: GoalEntityType.task, entityId: 't2');
      expect(GoalLink.fromMap(a.toMap()), a);
      expect(GoalLink.fromMap(b.toMap()), b);
      expect(GoalLink.fromMap(b.toMap()).milestoneId, isNull);
    });

    test('unknown entityType string is preserved', () {
      final l = GoalLink(goalId: 'g', entityType: 'habit', entityId: 'h');
      expect(GoalLink.fromMap(l.toMap()).entityType, 'habit');
    });
  });
}
