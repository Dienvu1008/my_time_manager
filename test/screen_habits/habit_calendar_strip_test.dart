import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/repositories/habit_repository.dart';
import 'package:my_time_manager/domain/services/habit_statistics_service.dart';
import 'package:my_time_manager/screen_habits/habit_calendar_strip.dart';
import 'package:my_time_manager/screen_habits/habit_detail_screen.dart';

import '../shared/fake_repositories.dart';
import '../shared/test_harness.dart';

/// Phase H3: read-only habit markers on the calendar (day / week views use
/// [HabitCalendarStrip] as their header accessory).
void main() {
  late FakeHabitRepository habits;
  // Tue Mar 10 2026, 12:00 local.
  final now = DateTime(2026, 3, 10, 12);
  DateTime clock() => now;
  final today = DateTime(2026, 3, 10);

  setUp(() => habits = FakeHabitRepository());

  Widget app(Widget body, {bool withRepo = true}) => testApp([
        if (withRepo) RepositoryProvider<HabitRepository>.value(value: habits),
        if (withRepo)
          RepositoryProvider<HabitStatisticsService>.value(
              value: HabitStatisticsService(repository: habits)),
      ], Scaffold(body: Column(children: [body, const Text('timeline')])));

  Future<void> pump(WidgetTester tester, Widget body,
      {bool withRepo = true}) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(body, withRepo: withRepo));
    await tester.pumpAndSettle();
  }

  Habit seed(String id, String title, {String? time}) {
    final h = Habit(
        id: id,
        title: title,
        startDate: DateTime(2026, 3, 1),
        reminderTime: time,
        color: Colors.teal);
    habits.habits[h.id] = h;
    return h;
  }

  Finder marker(String habitId, DateTime day) => find.byKey(ValueKey(
      'habit-calendar-$habitId-${HabitDay.format(day)}'));

  testWidgets('day view: shows a marker per active habit, timed after all-day',
      (tester) async {
    seed('a', 'Run', time: '07:30');
    seed('b', 'Journal');
    final archived = seed('c', 'Old');
    habits.habits['c'] = Habit.fromMap({
      ...archived.toMap(),
      'isArchived': 1,
      'archivedAt': DateTime(2026, 3, 20).toIso8601String(),
    });
    await pump(tester,
        HabitCalendarStrip(from: today, to: today, now: clock));

    expect(marker('a', today), findsOneWidget);
    expect(marker('b', today), findsOneWidget);
    expect(marker('c', today), findsNothing);
    expect(find.text('07:30 · Run'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    // All-day (no reminder time) entry comes first.
    expect(tester.getTopLeft(marker('b', today)).dx,
        lessThan(tester.getTopLeft(marker('a', today)).dx));
    expect(
        find.bySemanticsLabel(RegExp(r'Habits: 07:30 · Run, Pending')),
        findsOneWidget);
    // The existing calendar content is still rendered.
    expect(find.text('timeline'), findsOneWidget);
  });

  testWidgets('tap → habit check-in (HabitDetailScreen) → outcome recorded',
      (tester) async {
    seed('a', 'Run', time: '07:30');
    await pump(tester,
        HabitCalendarStrip(from: today, to: today, now: clock));

    await tester.tap(marker('a', today));
    await tester.pumpAndSettle();
    expect(find.byType(HabitDetailScreen), findsOneWidget);

    // Record today through the habit workflow.
    await tester.tap(find.byKey(ValueKey('day-${HabitDay.format(today)}')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(habits.calls, contains('record:a:2026-03-10:completed'));

    await tester.pageBack();
    await tester.pumpAndSettle();
    // The strip reloads and shows the recorded outcome.
    expect(find.bySemanticsLabel(RegExp(r'Habits: 07:30 · Run, Completed$')),
        findsOneWidget);
  });

  testWidgets('week view: one marker per scheduled day with a date prefix',
      (tester) async {
    seed('a', 'Run');
    habits.occurrences['x'] = HabitOccurrence(
        id: 'x',
        habitId: 'a',
        localDate: DateTime(2026, 3, 9),
        outcome: HabitOutcome.skipped);
    await pump(
        tester,
        HabitCalendarStrip(
            from: DateTime(2026, 3, 9),
            to: DateTime(2026, 3, 15),
            showDate: true,
            now: clock));
    for (var d = 9; d <= 15; d++) {
      expect(marker('a', DateTime(2026, 3, d)), findsOneWidget);
    }
    expect(find.textContaining('3/9 · Run'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Run, Skipped$')), findsOneWidget);
  });

  testWidgets('nothing rendered without habits or without a repository',
      (tester) async {
    await pump(tester,
        HabitCalendarStrip(from: today, to: today, now: clock));
    expect(find.byType(ActionChip), findsNothing);

    await pump(tester, HabitCalendarStrip(from: today, to: today, now: clock),
        withRepo: false);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('timeline'), findsOneWidget);
  });
}
