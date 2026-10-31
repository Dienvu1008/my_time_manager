import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_habit.dart';
import 'package:my_time_manager/domain/models/model_habit_occurrence.dart';
import 'package:my_time_manager/domain/repositories/habit_repository.dart';
import 'package:my_time_manager/domain/services/habit_statistics_service.dart';
import 'package:my_time_manager/domain/services/repeat_rule.dart';
import 'package:my_time_manager/screen_habits/habit_detail_screen.dart';
import 'package:my_time_manager/screen_habits/habit_form_screen.dart';
import 'package:my_time_manager/screen_habits/habits_list_screen.dart';

import '../shared/fake_repositories.dart';
import '../shared/test_harness.dart';

/// [FakeHabitRepository] whose habit creation throws.
class _FailingHabitRepository extends FakeHabitRepository {
  @override
  Future<void> createHabit(Habit habit) async => throw Exception('boom');
}

/// Fixed clock: Tuesday 10 March 2026, 09:00.
DateTime _now() => DateTime(2026, 3, 10, 9);

void main() {
  late FakeHabitRepository habits;

  setUp(() => habits = FakeHabitRepository());

  Widget app(Widget home) => testApp([
        RepositoryProvider<HabitRepository>.value(value: habits),
        RepositoryProvider<HabitStatisticsService>.value(
            value: HabitStatisticsService(repository: habits)),
      ], home);

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Habit seed(String title,
      {DateTime? start, DateTime? end, RepeatRule? rule}) {
    final h = Habit(
      title: title,
      startDate: start ?? DateTime(2026, 3, 1),
      endDate: end,
      recurrence: rule,
    );
    habits.habits[h.id] = h;
    return h;
  }

  void record(Habit h, DateTime day, HabitOutcome o) {
    final occ = HabitOccurrence(habitId: h.id, localDate: day, outcome: o);
    habits.occurrences[occ.id] = occ;
  }

  group('HabitsListScreen', () {
    testWidgets('empty state, then create via FAB', (tester) async {
      await pump(tester, const HabitsListScreen(now: _now));
      expect(find.text('No habits yet'), findsOneWidget);
      expect(find.text('Create a habit'), findsOneWidget);

      await tester.tap(find.byTooltip('New habit'));
      await tester.pumpAndSettle();
      expect(find.text('New habit'), findsWidgets);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Read');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      final created = habits.habits.values.single;
      expect(created.title, 'Read');
      expect(created.startDate, DateTime(2026, 3, 10));
      expect(created.recurrence, Habit.defaultRecurrence);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Today: Pending'), findsOneWidget);
      expect(find.text('Streak 0'), findsOneWidget);
    });

    testWidgets('quick Complete records today and updates the streak chip',
        (tester) async {
      final h = seed('Run', start: DateTime(2026, 3, 8));
      record(h, DateTime(2026, 3, 8), HabitOutcome.completed);
      record(h, DateTime(2026, 3, 9), HabitOutcome.completed);
      await pump(tester, const HabitsListScreen(now: _now));
      expect(find.text('Streak 2'), findsOneWidget);
      expect(find.text('Today: Pending'), findsOneWidget);
      expect(find.byTooltip("Undo today's record"), findsNothing);

      await tester.tap(find.byTooltip('Mark completed today'));
      await tester.pumpAndSettle();

      expect(habits.calls, contains('record:${h.id}:2026-03-10:completed'));
      expect(find.text('Streak 3'), findsOneWidget);
      expect(find.text('Today: Completed'), findsOneWidget);
    });

    testWidgets('Skip then Undo clears today', (tester) async {
      final h = seed('Meditate');
      await pump(tester, const HabitsListScreen(now: _now));

      await tester.tap(find.byTooltip('Skip today'));
      await tester.pumpAndSettle();
      expect(find.text('Today: Skipped'), findsOneWidget);
      expect(
          await habits.getOccurrence(h.id, DateTime(2026, 3, 10)), isNotNull);

      await tester.tap(find.byTooltip("Undo today's record"));
      await tester.pumpAndSettle();
      expect(habits.calls, contains('clear:${h.id}:2026-03-10'));
      expect(await habits.getOccurrence(h.id, DateTime(2026, 3, 10)), isNull);
      expect(find.text('Today: Pending'), findsOneWidget);
      expect(find.byTooltip("Undo today's record"), findsNothing);
    });

    testWidgets('not scheduled today shows no quick actions', (tester) async {
      // Weekly on Mondays; the clock is a Tuesday.
      seed('Weekly review',
          start: DateTime(2026, 3, 2),
          rule: const RepeatRule(
              frequency: RepeatFrequency.weekly,
              weekdays: {DateTime.monday}));
      await pump(tester, const HabitsListScreen(now: _now));
      expect(find.text('Not scheduled today'), findsOneWidget);
      expect(find.byTooltip('Mark completed today'), findsNothing);
      expect(find.byTooltip('Mark partial today'), findsNothing);
      expect(find.byTooltip('Skip today'), findsNothing);
    });
  });

  group('HabitFormScreen', () {
    testWidgets('empty title shows validation and creates nothing',
        (tester) async {
      await pump(tester, launcher(const HabitFormScreen(now: _now)));
      await open(tester);
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsOneWidget);
      expect(habits.habits, isEmpty);
    });

    testWidgets('end date before start date is rejected', (tester) async {
      final h = seed('Run',
          start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 5));
      await pump(tester, launcher(HabitFormScreen(habit: h, now: _now)));
      await open(tester);
      expect(find.text('Edit habit'), findsOneWidget);
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('End date must be on or after the start date'),
          findsOneWidget);
      expect(habits.calls, isEmpty);
      expect(find.text('result: true'), findsNothing);

      // Clearing the end date fixes it.
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(habits.habits[h.id]!.endDate, isNull);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('save failure shows an error SnackBar and re-enables Save',
        (tester) async {
      habits = _FailingHabitRepository();
      await pump(tester, launcher(const HabitFormScreen(now: _now)));
      await open(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Read');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: boom'), findsOneWidget);
      expect(find.text('New habit'), findsOneWidget);
      expect(find.text('result: true'), findsNothing);
      final save = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.check));
      expect(save.onPressed, isNotNull);
    });

    testWidgets('reused recurrence editor, target, partial flag are saved',
        (tester) async {
      await pump(tester, launcher(const HabitFormScreen(now: _now)));
      await open(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Read');
      // Existing RepeatListTile (Vietnamese labels); "no repeat" is hidden.
      await tester.tap(find.text('Lặp lại?'));
      await tester.pumpAndSettle();
      expect(find.text('Không lặp lại'), findsNothing);
      await tester.tap(find.text('Hằng tuần'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Target amount (optional)'), '10');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Unit'), 'pages');
      await tester.tap(find.text('Partial counts toward streak'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      final h = habits.habits.values.single;
      expect(h.recurrence,
          const RepeatRule(frequency: RepeatFrequency.weekly));
      expect(h.targetAmount, 10);
      expect(h.unit, 'pages');
      expect(h.partialCountsTowardStreak, isTrue);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('edit pre-fills a custom rule in the recurrence editor',
        (tester) async {
      final h = seed('Gym',
          rule: const RepeatRule(
              frequency: RepeatFrequency.weekly,
              interval: 2,
              weekdays: {DateTime.monday, DateTime.friday}));
      await pump(tester, launcher(HabitFormScreen(habit: h, now: _now)));
      await open(tester);
      expect(find.text('Tùy chỉnh'), findsOneWidget); // subtitle
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(habits.habits[h.id]!.recurrence, h.recurrence);
    });
  });

  group('HabitDetailScreen', () {
    Habit seedHistory() {
      final h = seed('Run', start: DateTime(2026, 3, 1));
      record(h, DateTime(2026, 3, 7), HabitOutcome.skipped);
      record(h, DateTime(2026, 3, 8), HabitOutcome.completed);
      record(h, DateTime(2026, 3, 9), HabitOutcome.completed);
      return h;
    }

    testWidgets('shows statistics and history', (tester) async {
      seedHistory();
      await pump(tester, HabitDetailScreen(
          habitId: habits.habits.keys.single, now: _now));
      // 03-01..03-06 derived missed; 07 skipped; 08/09 completed; 10 pending.
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Completed: 2'), findsOneWidget);
      expect(find.text('Missed: 6'), findsOneWidget);
      expect(find.text('Skipped: 1'), findsOneWidget);
      expect(find.text('Pending: 1'), findsOneWidget);
      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Best streak'), findsOneWidget);
      // Derived days are marked "not recorded".
      expect(find.text('Missed · not recorded'), findsNWidgets(6));
      expect(find.text('10/03/2026 · Today'), findsOneWidget);
    });

    testWidgets('editing a past day asks confirm then records it',
        (tester) async {
      final h = seedHistory();
      await pump(tester, HabitDetailScreen(habitId: h.id, now: _now));

      Future<void> editMarch5() async {
        await tester.tap(find.byKey(const ValueKey('day-2026-03-05')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
        expect(find.text('Change the record for 05/03/2026?'), findsOneWidget);
      }

      // Cancel → nothing written.
      await editMarch5();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(habits.calls, isEmpty);

      // Confirm → recorded.
      await editMarch5();
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(habits.calls, ['record:${h.id}:2026-03-05:completed']);
      expect(find.text('Completed: 3'), findsOneWidget);
      expect(find.text('Missed: 5'), findsOneWidget);
    });

    testWidgets('editing today needs no confirm; clear removes a record',
        (tester) async {
      final h = seedHistory();
      await pump(tester, HabitDetailScreen(habitId: h.id, now: _now));
      await tester.tap(find.byKey(const ValueKey('day-2026-03-10')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Partial'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(habits.calls, ['record:${h.id}:2026-03-10:partial']);

      await tester.tap(find.byKey(const ValueKey('day-2026-03-10')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear record'));
      await tester.pumpAndSettle();
      expect(habits.calls.last, 'clear:${h.id}:2026-03-10');
    });

    testWidgets('archive with confirm pops true', (tester) async {
      final h = seedHistory();
      await pump(tester, launcher(HabitDetailScreen(habitId: h.id, now: _now)));
      await open(tester);
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.textContaining('history is kept'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();
      expect(habits.habits[h.id]!.isArchived, isTrue);
      expect(habits.occurrences, hasLength(3));
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('permanent delete with strong confirm pops true',
        (tester) async {
      final h = seedHistory();
      await pump(tester, launcher(HabitDetailScreen(habitId: h.id, now: _now)));
      await open(tester);
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(find.textContaining('entire history'), findsOneWidget);

      // Cancel keeps everything.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(habits.habits, contains(h.id));

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete permanently'));
      await tester.pumpAndSettle();
      expect(habits.habits, isEmpty);
      expect(habits.occurrences, isEmpty);
      expect(find.text('result: true'), findsOneWidget);
    });
  });
}
