import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/reminders/wall_clock_resolver.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location berlin;
  late tz.Location newYork;

  setUpAll(() {
    tzdata.initializeTimeZones();
    berlin = tz.getLocation('Europe/Berlin');
    newYork = tz.getLocation('America/New_York');
  });

  DateTime utc(int y, int m, int d, int h, int min) =>
      DateTime.utc(y, m, d, h, min);

  group('Europe/Berlin', () {
    test('spring-forward gap resolves to the transition instant', () {
      expect(resolveWallClock(berlin, const WallClock(2026, 3, 29, 2, 30)),
          utc(2026, 3, 29, 1, 0));
    });
    test('after the gap uses the summer offset', () {
      expect(resolveWallClock(berlin, const WallClock(2026, 3, 29, 3, 30)),
          utc(2026, 3, 29, 1, 30));
    });
    test('fall-back overlap takes the first occurrence', () {
      expect(resolveWallClock(berlin, const WallClock(2026, 10, 25, 2, 30)),
          utc(2026, 10, 25, 0, 30));
    });
    test('after the overlap uses the winter offset', () {
      expect(resolveWallClock(berlin, const WallClock(2026, 10, 25, 3, 30)),
          utc(2026, 10, 25, 2, 30));
    });
  });

  group('America/New_York', () {
    test('gap', () {
      expect(resolveWallClock(newYork, const WallClock(2026, 3, 8, 2, 30)),
          utc(2026, 3, 8, 7, 0));
    });
    test('overlap', () {
      expect(resolveWallClock(newYork, const WallClock(2026, 11, 1, 1, 30)),
          utc(2026, 11, 1, 5, 30));
    });
  });

  test('UTC location is identity and result is UTC', () {
    final r = resolveWallClock(tz.UTC, const WallClock(2026, 5, 1, 9, 0));
    expect(r, utc(2026, 5, 1, 9, 0));
    expect(r.isUtc, isTrue);
  });

  test('wallClockOf round-trips a normal time', () {
    const wc = WallClock(2026, 7, 1, 12, 15);
    expect(wallClockOf(resolveWallClock(berlin, wc), berlin), wc);
  });
}
