import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/quiet_hours.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  const night = QuietHours(enabled: true, startMinutes: 1320, endMinutes: 420);

  test('22:00-07:00: 23:30 shifts to next day 07:00', () {
    expect(night.adjust(DateTime.utc(2026, 5, 1, 23, 30), tz.UTC),
        DateTime.utc(2026, 5, 2, 7, 0));
  });

  test('22:00-07:00: 06:59 shifts to 07:00 same day', () {
    expect(night.adjust(DateTime.utc(2026, 5, 2, 6, 59), tz.UTC),
        DateTime.utc(2026, 5, 2, 7, 0));
  });

  test('22:00-07:00: 07:00 and 21:59 unchanged', () {
    final a = DateTime.utc(2026, 5, 2, 7, 0);
    final b = DateTime.utc(2026, 5, 2, 21, 59);
    expect(night.adjust(a, tz.UTC), a);
    expect(night.adjust(b, tz.UTC), b);
    expect(night.contains(22 * 60), isTrue);
  });

  test('daytime window 12:00-14:00', () {
    const noon = QuietHours(enabled: true, startMinutes: 720, endMinutes: 840);
    expect(noon.adjust(DateTime.utc(2026, 5, 1, 13, 0), tz.UTC),
        DateTime.utc(2026, 5, 1, 14, 0));
    final outside = DateTime.utc(2026, 5, 1, 14, 0);
    expect(noon.adjust(outside, tz.UTC), outside);
    expect(noon.contains(11 * 60 + 59), isFalse);
  });

  test('start == end and disabled are inactive', () {
    const same = QuietHours(enabled: true, startMinutes: 600, endMinutes: 600);
    final t = DateTime.utc(2026, 5, 1, 10, 0);
    expect(same.isActive, isFalse);
    expect(same.adjust(t, tz.UTC), t);
    expect(QuietHours.off.isActive, isFalse);
    expect(QuietHours.off.adjust(DateTime.utc(2026, 5, 1, 23), tz.UTC),
        DateTime.utc(2026, 5, 1, 23));
  });

  test('DST day: end inside the gap resolves via the resolver', () {
    final berlin = tz.getLocation('Europe/Berlin');
    const q = QuietHours(enabled: true, startMinutes: 60, endMinutes: 150);
    // 01:30 CET = 00:30Z; end 02:30 does not exist → 03:00 CEST = 01:00Z.
    expect(q.adjust(DateTime.utc(2026, 3, 29, 0, 30), berlin),
        DateTime.utc(2026, 3, 29, 1, 0));
  });

  test('wall-clock in Berlin: 23:30 local shifts to 07:00 local', () {
    final berlin = tz.getLocation('Europe/Berlin');
    // 2026-07-01 23:30 CEST = 21:30Z → 2026-07-02 07:00 CEST = 05:00Z.
    expect(night.adjust(DateTime.utc(2026, 7, 1, 21, 30), berlin),
        DateTime.utc(2026, 7, 2, 5, 0));
  });
}
