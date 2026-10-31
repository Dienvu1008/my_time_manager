import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/repositories/habit_repository.dart';
import 'package:my_time_manager/domain/services/habit_statistics_service.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';

/// Pure tests for [HabitStatisticsService] (Phase H1): streak policy H-a,
/// derivation of unrecorded days, completion rate, determinism.
void main() {
  const service = HabitStatisticsService();
  // "Now" = Jan 20 2026, 15:00 local (a Tuesday).
  final now = DateTime(2026, 1, 20, 15);

  Habit daily({bool partialCounts = false, DateTime? start}) => Habit(
        id: 'h',
        title: 'Daily',
        startDate: start ?? DateTime(2026, 1, 16),
        partialCountsTowardStreak: partialCounts,
      );

  HabitOccurrence rec(int day, HabitOutcome o, {String habitId = 'h'}) =>
      HabitOccurrence(
          habitId: habitId, localDate: DateTime(2026, 1, day), outcome: o);

  /// Daily habit Jan 16..20 (today) with the given outcomes for 16..19.
  List<HabitOccurrence> days16to19(List<HabitOutcome> outcomes) => [
        for (var i = 0; i < outcomes.length; i++) rec(16 + i, outcomes[i]),
      ];

  const c = HabitOutcome.completed;
  const p = HabitOutcome.partial;
  const s = HabitOutcome.skipped;
  const m = HabitOutcome.missed;

  group('streak policy', () {
    test('completed adds; today pending does not break', () {
      final h = daily();
      final occ = days16to19([c, c, c, c]);
      expect(service.currentStreak(h, occ, now), 4);
      expect(service.bestStreak(h, occ, now), 4);
      // Completing today adds one.
      expect(service.currentStreak(h, [...occ, rec(20, c)], now), 5);
    });

    test('skipped pauses (no add, no break)', () {
      final h = daily();
      final occ = days16to19([c, s, c, s]);
      expect(service.currentStreak(h, occ, now), 2);
      expect(service.bestStreak(h, occ, now), 2);
    });

    test('missed breaks', () {
      final h = daily();
      final occ = days16to19([c, c, m, c]);
      expect(service.currentStreak(h, occ, now), 1);
      expect(service.bestStreak(h, occ, now), 2);
    });

    test('partial adds iff partialCountsTowardStreak, otherwise pauses', () {
      final occ = days16to19([c, p, p, c]);
      expect(service.currentStreak(daily(partialCounts: true), occ, now), 4);
      expect(service.currentStreak(daily(partialCounts: false), occ, now), 2);
      expect(HabitStatisticsService.effectOf(daily(), p), StreakEffect.pause);
      expect(HabitStatisticsService.effectOf(daily(partialCounts: true), p),
          StreakEffect.add);
    });

    test('non-scheduled days are ignored', () {
      // Mon/Wed/Fri habit from Mon Jan 12. Scheduled ≤ today: 12, 14, 16, 19.
      final h = Habit(
        id: 'h',
        title: 'MWF',
        startDate: DateTime(2026, 1, 12),
        recurrence: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {1, 3, 5}),
      );
      final occ = [rec(12, c), rec(14, c), rec(16, c), rec(19, c)];
      // Unrecorded 13, 15, 17, 18 are not scheduled → no derived missed.
      expect(service.currentStreak(h, occ, now), 4);
      final days = service.resolveDays(h, occ,
          from: DateTime(2026, 1, 12), to: now, now: now);
      expect(days.map((d) => d.day.day), [12, 14, 16, 19]);
    });

    test('unrecorded past scheduled day is derived missed and breaks', () {
      final h = daily();
      // 18 unrecorded → missed.
      final occ = [rec(16, c), rec(17, c), rec(19, c)];
      expect(service.currentStreak(h, occ, now), 1);
      final days =
          service.resolveDays(h, occ, from: h.startDate, to: now, now: now);
      final d18 = days.firstWhere((d) => d.day.day == 18);
      expect(d18.outcome, HabitOutcome.missed);
      expect(d18.isRecorded, isFalse);
      final d20 = days.last;
      expect(d20.day, DateTime(2026, 1, 20));
      expect(d20.outcome, HabitOutcome.pending);
    });

    test('yesterday missed + today pending → current streak 0', () {
      final h = daily();
      expect(service.currentStreak(h, days16to19([c, c, c, m]), now), 0);
    });
  });

  group('derivation', () {
    test('long offline: every unrecorded past day becomes missed', () {
      final h = daily(start: DateTime(2025, 1, 1));
      final occ = [
        HabitOccurrence(
            habitId: 'h', localDate: DateTime(2025, 1, 1), outcome: c),
      ];
      final stats = service.compute(h, occ, now: now);
      // 2025-01-01 .. 2026-01-19 = 384 past days, 1 completed; today pending.
      expect(stats.counts[HabitOutcome.completed], 1);
      expect(stats.counts[HabitOutcome.missed], 383);
      expect(stats.counts[HabitOutcome.pending], 1);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 1);
      expect(stats.completionRate, closeTo(1 / 384, 1e-12));
    });

    test('future days are pending and never affect rate/streak', () {
      final h = daily();
      final occ = days16to19([c, c, c, c]);
      final stats = service.compute(h, occ,
          now: now, from: DateTime(2026, 1, 16), to: DateTime(2026, 1, 25));
      expect(stats.days, hasLength(10));
      expect(stats.counts[HabitOutcome.pending], 6); // 20..25
      expect(stats.completionRate, 1.0);
      expect(stats.currentStreak, 4);
    });

    test('recorded pending / unknown outcome resolve like unrecorded', () {
      final h = daily();
      final occ = [
        rec(16, HabitOutcome.pending),
        HabitOccurrence.fromMap(const {
          'id': 'x',
          'habitId': 'h',
          'localDate': '2026-01-17',
          'outcome': 'from_the_future',
        }),
      ];
      final days =
          service.resolveDays(h, occ, from: h.startDate, to: now, now: now);
      expect(days[0].outcome, HabitOutcome.missed);
      expect(days[1].outcome, HabitOutcome.missed);
    });

    test('rule change does not rewrite recorded outcomes', () {
      // Recorded under a daily rule on Jan 13 (Tue) and Jan 14 (Wed).
      final before = daily(start: DateTime(2026, 1, 12));
      final occ = [rec(13, c), rec(14, s)];
      // New rule: Mondays only.
      final after = Habit(
        id: 'h',
        title: 'Daily',
        startDate: DateTime(2026, 1, 12),
        recurrence: const RepeatRule(
            frequency: RepeatFrequency.weekly, weekdays: {1}),
      );
      final daysBefore =
          service.resolveDays(before, occ, from: before.startDate, to: now, now: now);
      final daysAfter =
          service.resolveDays(after, occ, from: after.startDate, to: now, now: now);

      HabitOutcome at(List<ResolvedHabitDay> ds, int day) =>
          ds.firstWhere((d) => d.day.day == day).outcome;
      // Recorded rows keep their outcome under both rules.
      for (final ds in [daysBefore, daysAfter]) {
        expect(at(ds, 13), c);
        expect(at(ds, 14), s);
      }
      final r13 = daysAfter.firstWhere((d) => d.day.day == 13);
      expect(r13.isRecorded, isTrue);
      expect(r13.isScheduled, isFalse);
      // Derived days follow the CURRENT rule: only Mondays 12 and 19 remain
      // (both unrecorded past → missed); 15..18 are no longer derived.
      expect(daysAfter.map((d) => d.day.day), [12, 13, 14, 19]);
      expect(at(daysAfter, 12), m);
      expect(at(daysAfter, 19), m);
      // Inputs are not mutated.
      expect(occ.map((o) => o.outcome), [c, s]);
    });

    test('archived habit: no derived days after the archive day', () {
      final h = Habit.fromMap({
        'id': 'h',
        'title': 'A',
        'startDate': '2026-01-16',
        'isArchived': 1,
        'archivedAt': '2026-01-17T10:00:00.000',
      });
      final stats = service.compute(h, [rec(16, c), rec(17, c)], now: now);
      expect(stats.counts[HabitOutcome.missed], 0);
      expect(stats.currentStreak, 2);
    });

    test('occurrences of other habits are ignored', () {
      final h = daily();
      final occ = [
        ...days16to19([c, c, c, c]),
        rec(18, m, habitId: 'other'),
      ];
      expect(service.currentStreak(h, occ, now), 4);
    });
  });

  group('completion rate', () {
    test('(completed + partial if flag) / resolved, skipped excluded', () {
      final occ = days16to19([c, p, s, m]);
      // Without flag: 1 success / (c + p + m = 3).
      expect(service.completionRate(daily(), occ, now: now),
          closeTo(1 / 3, 1e-12));
      // With flag: 2 / 3.
      expect(service.completionRate(daily(partialCounts: true), occ, now: now),
          closeTo(2 / 3, 1e-12));
    });

    test('window and empty cases', () {
      final h = daily();
      final occ = days16to19([m, m, c, c]);
      expect(
          service.completionRate(h, occ,
              now: now, from: DateTime(2026, 1, 18), to: DateTime(2026, 1, 19)),
          1.0);
      // Only skipped / today pending → 0 resolved → 0.
      expect(
          service.completionRate(h, [rec(16, s)],
              now: now, from: DateTime(2026, 1, 16), to: DateTime(2026, 1, 16)),
          0.0);
      expect(
          service.completionRate(daily(start: DateTime(2026, 1, 20)), const [],
              now: now),
          0.0);
    });

    test('compute: counts per outcome include all five keys', () {
      final stats =
          service.compute(daily(), days16to19([c, p, s, m]), now: now);
      expect(stats.counts.keys, HabitOutcome.values);
      expect(stats.counts, {
        c: 1,
        p: 1,
        s: 1,
        m: 1,
        HabitOutcome.pending: 1,
      });
      expect(stats.scheduledDayCount, 5);
      expect(stats.from, DateTime(2026, 1, 16));
      expect(stats.to, DateTime(2026, 1, 20));
      expect(stats.today, DateTime(2026, 1, 20));
    });
  });

  test('deterministic: same rows + rule + now → same result', () {
    final h = daily(partialCounts: true, start: DateTime(2025, 12, 1));
    final occ = [
      rec(3, c),
      rec(5, p),
      rec(6, s),
      rec(10, m),
      rec(11, c),
      rec(12, c),
    ];
    final a = service.compute(h, occ, now: now);
    final b = service.compute(h, occ.reversed.toList(), now: now);
    expect(a.currentStreak, b.currentStreak);
    expect(a.bestStreak, b.bestStreak);
    expect(a.completionRate, b.completionRate);
    expect(a.counts, b.counts);
    expect(a.days.map((d) => (d.day, d.outcome)).toList(),
        b.days.map((d) => (d.day, d.outcome)).toList());
    // Same "now" at a different time of day → same local day → same result.
    final c2 = service.compute(h, occ, now: DateTime(2026, 1, 20, 0, 1));
    expect(c2.counts, a.counts);
  });

  test('statisticsFor loads through the repository', () async {
    final h = daily();
    final repo = _FakeRepo(h, days16to19([c, c, c, c]));
    final stats = await HabitStatisticsService(repository: repo)
        .statisticsFor('h', now: now);
    expect(stats!.currentStreak, 4);
    expect(
        await HabitStatisticsService(repository: repo)
            .statisticsFor('missing', now: now),
        isNull);
    expect(() => service.statisticsFor('h'), throwsStateError);
  });
}

class _FakeRepo implements HabitRepository {
  _FakeRepo(this.habit, this.occurrences);
  final Habit habit;
  final List<HabitOccurrence> occurrences;

  @override
  Future<Habit?> getHabit(String id) async => id == habit.id ? habit : null;

  @override
  Future<List<HabitOccurrence>> occurrencesOf(String habitId,
          {DateTime? from, DateTime? to}) async =>
      occurrences.where((o) => o.habitId == habitId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
