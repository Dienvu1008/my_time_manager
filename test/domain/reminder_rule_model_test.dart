import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';

void main() {
  group('WallClock', () {
    test('storage format is zero-padded and round-trips', () {
      const w = WallClock(2026, 3, 4, 9, 5);
      expect(w.toStorage(), '2026-03-04T09:05');
      expect(WallClock.tryParse('2026-03-04T09:05'), w);
    });

    test('tryParse rejects invalid input', () {
      for (final s in [
        null,
        '',
        'garbage',
        '2026-3-4T9:5',
        '2026-13-01T00:00',
        '2026-02-30T00:00',
        '2026-01-01T24:00',
        '2026-01-01T10:60',
        '2026-01-01T10:00:00',
      ]) {
        expect(WallClock.tryParse(s), isNull, reason: '$s');
      }
    });

    test('fromDateTime uses local fields', () {
      final w = WallClock.fromDateTime(DateTime(2026, 12, 31, 23, 59, 30));
      expect(w, const WallClock(2026, 12, 31, 23, 59));
    });
  });

  group('ReminderRule', () {
    test('toMap/fromMap round trip (offset and absolute)', () {
      final off = ReminderRule.offset(
          entityType: ReminderEntityType.timeInterval,
          entityId: 'a',
          minutes: 15,
          priority: ReminderPriority.high);
      final abs = ReminderRule.absolute(
          entityType: ReminderEntityType.task,
          entityId: 'b',
          at: const WallClock(2026, 1, 2, 3, 4),
          enabled: false);

      final offMap = off.toMap();
      expect(offMap['kind'], 'offset');
      expect(offMap['enabled'], 1);
      expect(offMap['priority'], 1);
      expect(ReminderRule.fromMap(offMap), off);

      final absMap = abs.toMap();
      expect(absMap['kind'], 'absolute');
      expect(absMap['absoluteAt'], '2026-01-02T03:04');
      expect(absMap['enabled'], 0);
      expect(ReminderRule.fromMap(absMap), abs);
    });

    test('fromMap tolerates nulls, unknown kind and bad priority', () {
      final r = ReminderRule.fromMap({
        'id': 'x',
        'entityType': 'habit',
        'entityId': 'h1',
        'kind': 'weird',
        'offsetMinutes': null,
        'absoluteAt': 'not-a-date',
        'enabled': null,
        'priority': 7,
        'createdAt': null,
        'updateTimeStamp': null,
      });
      expect(r.id, 'x');
      expect(r.entityType, 'habit');
      expect(r.kind, ReminderRuleKind.offset);
      expect(r.offsetMinutes, isNull);
      expect(r.absoluteAt, isNull);
      expect(r.enabled, isTrue);
      expect(r.priority, ReminderPriority.normal);

      expect(ReminderPriority.fromValue(-1), ReminderPriority.normal);
      expect(ReminderPriority.fromValue(1), ReminderPriority.high);
      expect(ReminderRuleKind.fromName(null), ReminderRuleKind.offset);
      expect(ReminderRuleKind.fromName('absolute'), ReminderRuleKind.absolute);
    });

    test('constructor generates id and timestamps; copyWith keeps id', () {
      final r = ReminderRule.offset(
          entityType: ReminderEntityType.task, entityId: 't', minutes: 1);
      expect(r.id, isNotEmpty);
      final c = r.copyWith(offsetMinutes: 2);
      expect(c.id, r.id);
      expect(c.createdAt, r.createdAt);
      expect(c.offsetMinutes, 2);
    });
  });
}
