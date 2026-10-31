import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/planned_reminder.dart';
import 'package:my_time_manager/application/reminders/reminder_selection.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';

void main() {
  final base = DateTime.utc(2026, 5, 1, 8);

  PlannedReminder p(int id, int minutes,
          {ReminderPriority priority = ReminderPriority.normal}) =>
      PlannedReminder(
        id: id,
        key: 'k$id',
        entityType: ReminderEntityType.timeInterval,
        entityId: 'e$id',
        fireAt: base.add(Duration(minutes: minutes)),
        priority: priority,
        title: 't',
        body: 'b',
      );

  test('70 items with limit 64 keeps the nearest 64', () {
    final items = [for (var i = 0; i < 70; i++) p(1000 + i, i)];
    final s = selectWithinLimit(items.reversed.toList(), 64);
    expect(s.selected.length, 64);
    expect(s.deferred.length, 6);
    expect(s.selected.map((e) => e.id), [for (var i = 0; i < 64; i++) 1000 + i]);
    expect(s.deferred.map((e) => e.id), [for (var i = 64; i < 70; i++) 1000 + i]);
  });

  test('equal fireAt at the cut keeps high priority', () {
    final items = [
      for (var i = 0; i < 63; i++) p(1000 + i, i),
      p(1, 100), // normal, small id
      p(9999, 100, priority: ReminderPriority.high),
    ];
    final s = selectWithinLimit(items, 64);
    expect(s.selected.last.id, 9999);
    expect(s.deferred.single.id, 1);
  });

  test('deterministic order regardless of input order', () {
    final items = [p(3, 5), p(1, 5), p(2, 5), p(4, 1)];
    final a = selectWithinLimit(items, 10).selected.map((e) => e.id).toList();
    final b = selectWithinLimit(items.reversed.toList(), 10)
        .selected
        .map((e) => e.id)
        .toList();
    expect(a, [4, 1, 2, 3]);
    expect(b, a);
  });
}
