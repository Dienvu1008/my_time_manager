@TestOn('vm')
library;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_reminder_rule_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_time_interval_repository.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for [SqliteReminderRuleRepository] (Phase R, schema v16)
/// against an in-memory sqflite (FFI) database.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  final repo = SqliteReminderRuleRepository();
  const task = ReminderEntityType.task;

  test('offset and absolute rules round-trip', () async {
    final off = ReminderRule.offset(
        entityType: ReminderEntityType.timeInterval,
        entityId: 'ti1',
        minutes: 15,
        priority: ReminderPriority.high);
    final abs = ReminderRule.absolute(
        entityType: task,
        entityId: 't1',
        at: const WallClock(2026, 3, 4, 9, 5),
        enabled: false);
    await repo.saveRule(off);
    await repo.saveRule(abs);

    final o = await repo.getRule(off.id);
    expect(o, isNotNull);
    expect(o!.kind, ReminderRuleKind.offset);
    expect(o.offsetMinutes, 15);
    expect(o.priority, ReminderPriority.high);
    expect(o.enabled, isTrue);
    expect(o.entityType, ReminderEntityType.timeInterval);

    final a = await repo.getRule(abs.id);
    expect(a!.kind, ReminderRuleKind.absolute);
    expect(a.absoluteAt, const WallClock(2026, 3, 4, 9, 5));
    expect(a.enabled, isFalse);
    expect(a.priority, ReminderPriority.normal);

    expect(await repo.getRule('missing'), isNull);
    expect(await repo.getAllRules(), hasLength(2));
  });

  test('saveRule twice updates in place (no duplicate)', () async {
    final r = ReminderRule.offset(entityType: task, entityId: 't1', minutes: 5);
    await repo.saveRule(r);
    await repo.saveRule(r.copyWith(offsetMinutes: 30));

    final all = await repo.getAllRules();
    expect(all, hasLength(1));
    expect(all.single.offsetMinutes, 30);
  });

  test('getRulesFor filters by entity; deleteRule removes', () async {
    final a = ReminderRule.offset(entityType: task, entityId: 't1', minutes: 5);
    final b =
        ReminderRule.offset(entityType: task, entityId: 't2', minutes: 10);
    final c = ReminderRule.offset(
        entityType: ReminderEntityType.calendarEvent,
        entityId: 't1',
        minutes: 10);
    for (final r in [a, b, c]) {
      await repo.saveRule(r);
    }

    expect((await repo.getRulesFor(task, 't1')).map((r) => r.id), [a.id]);
    await repo.deleteRule(a.id);
    expect(await repo.getRulesFor(task, 't1'), isEmpty);
    expect(await repo.getAllRules(), hasLength(2));
  });

  test('replaceRulesFor replaces only the given kind', () async {
    final keepAbs = ReminderRule.absolute(
        entityType: task,
        entityId: 't1',
        at: const WallClock(2026, 1, 1, 8, 0));
    final oldOff =
        ReminderRule.offset(entityType: task, entityId: 't1', minutes: 5);
    final otherEntity =
        ReminderRule.offset(entityType: task, entityId: 't2', minutes: 5);
    for (final r in [keepAbs, oldOff, otherEntity]) {
      await repo.saveRule(r);
    }

    final n1 =
        ReminderRule.offset(entityType: task, entityId: 't1', minutes: 15);
    final n2 =
        ReminderRule.offset(entityType: task, entityId: 't1', minutes: 60);
    await repo.replaceRulesFor(task, 't1', [n1, n2],
        kind: ReminderRuleKind.offset);

    final ids = (await repo.getRulesFor(task, 't1')).map((r) => r.id).toSet();
    expect(ids, {keepAbs.id, n1.id, n2.id});
    expect(await repo.getRule(otherEntity.id), isNotNull);

    // Empty list clears that kind only.
    await repo.replaceRulesFor(task, 't1', const [],
        kind: ReminderRuleKind.offset);
    expect((await repo.getRulesFor(task, 't1')).map((r) => r.id),
        [keepAbs.id]);
  });

  test('ArgumentError cases', () async {
    expect(
        () => repo.saveRule(
            ReminderRule.offset(entityType: '', entityId: 'x', minutes: 1)),
        throwsArgumentError);
    expect(
        () => repo.saveRule(
            ReminderRule.offset(entityType: task, entityId: ' ', minutes: 1)),
        throwsArgumentError);
    expect(
        () => repo.saveRule(
            ReminderRule.offset(entityType: task, entityId: 'x', minutes: -1)),
        throwsArgumentError);
    expect(
        () => repo.saveRule(ReminderRule(
            entityType: task, entityId: 'x', kind: ReminderRuleKind.offset)),
        throwsArgumentError);
    expect(
        () => repo.saveRule(ReminderRule(
            entityType: task,
            entityId: 'x',
            kind: ReminderRuleKind.absolute,
            offsetMinutes: 5)),
        throwsArgumentError);
    expect(
        () => repo.replaceRulesFor('', 'x', const [],
            kind: ReminderRuleKind.offset),
        throwsArgumentError);
    // Kind mismatch.
    expect(
        () => repo.replaceRulesFor(
            task,
            'x',
            [ReminderRule.offset(entityType: task, entityId: 'x', minutes: 1)],
            kind: ReminderRuleKind.absolute),
        throwsArgumentError);
    // Entity mismatch.
    expect(
        () => repo.replaceRulesFor(
            task,
            'x',
            [ReminderRule.offset(entityType: task, entityId: 'y', minutes: 1)],
            kind: ReminderRuleKind.offset),
        throwsArgumentError);
    expect(await repo.getAllRules(), isEmpty);
  });

  test('hard-deleting entities removes their rules only', () async {
    final tasks = SqliteTaskRepository();
    final intervals = SqliteTimeIntervalRepository();
    final calendar = SqliteCalendarRepository();

    final owner = Task(title: 'Owner');
    await tasks.createTask(owner);
    final other = Task(title: 'Other');
    await tasks.createTask(other);
    final ti = TimeInterval(
      taskId: other.id,
      title: 'Block',
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2026, 1, 10),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );
    await intervals.createTimeInterval(ti);
    final ev = CalendarEvent(
      title: 'Meeting',
      start: EventDateTime(dateTime: DateTime(2026, 1, 1, 9)),
      end: EventDateTime(dateTime: DateTime(2026, 1, 1, 10)),
    );
    await calendar.createCalendarEvent(ev);
    final ev2 = CalendarEvent(
      title: 'Other meeting',
      start: EventDateTime(dateTime: DateTime(2026, 1, 2, 9)),
      end: EventDateTime(dateTime: DateTime(2026, 1, 2, 10)),
    );
    await calendar.createCalendarEvent(ev2);

    final rTi = ReminderRule.offset(
        entityType: ReminderEntityType.timeInterval,
        entityId: ti.id,
        minutes: 10);
    final rEv = ReminderRule.offset(
        entityType: ReminderEntityType.calendarEvent,
        entityId: ev.id,
        minutes: 10);
    final rEv2 = ReminderRule.offset(
        entityType: ReminderEntityType.calendarEvent,
        entityId: ev2.id,
        minutes: 10);
    final rTask = ReminderRule.absolute(
        entityType: task,
        entityId: owner.id,
        at: const WallClock(2026, 1, 1, 8, 0));
    final rOther = ReminderRule.absolute(
        entityType: task,
        entityId: other.id,
        at: const WallClock(2026, 1, 1, 8, 0));
    for (final r in [rTi, rEv, rEv2, rTask, rOther]) {
      await repo.saveRule(r);
    }

    await intervals.deleteTimeInterval(ti.id);
    expect(await repo.getRule(rTi.id), isNull);
    expect(await repo.getAllRules(), hasLength(4));

    await calendar.deleteCalendarEvent(ev.id);
    expect(await repo.getRule(rEv.id), isNull);
    expect(await repo.getRule(rEv2.id), isNotNull);

    await tasks.deleteTask(owner.id);
    expect(await repo.getRule(rTask.id), isNull);
    expect((await repo.getAllRules()).map((r) => r.id).toSet(),
        {rEv2.id, rOther.id});
  });
}
