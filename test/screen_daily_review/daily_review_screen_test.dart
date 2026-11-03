import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/application/daily_review/daily_review.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/habit_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/screen_daily_review/daily_review_screen.dart';
import 'package:my_time_manager/screen_settings/daily_review_settings_card.dart';

import '../application/daily_review/daily_review_fixtures.dart';
import '../shared/test_harness.dart';

void main() {
  late Env env;

  setUp(() => env = Env());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testApp([
      RepositoryProvider<TimeIntervalRepository>.value(value: env.intervals),
      RepositoryProvider<TaskRepository>.value(value: env.tasks),
      RepositoryProvider<CalendarRepository>.value(value: env.calendar),
      RepositoryProvider<HabitRepository>.value(value: env.habits),
    ], DailyReviewScreen(now: () => kNow)));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String id, String action) async {
    await tester.tap(find.byKey(ValueKey('dr-action-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  Future<void> previewAndApply(WidgetTester tester, {required bool approve}) async {
    await tester.tap(find.byKey(const ValueKey('dr-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dr-apply')));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    await tester.tap(find.descendant(
        of: dialog, matching: find.text(approve ? 'Apply' : 'Cancel')));
    await tester.pumpAndSettle();
  }

  testWidgets('nothing unresolved → positive empty state', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('dr-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('dr-preview')), findsNothing);
  });

  testWidgets('categories render with their items', (tester) async {
    env.intervals.put(timed('late', at(10, 9), at(10, 10)));
    env.intervals.put(timed('soon', at(11, 15), at(11, 16)));
    await pump(tester);
    expect(find.text('Overdue (1)'), findsOneWidget);
    expect(find.text('Due today (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey('dr-item-late')), findsOneWidget);
    expect(find.byKey(const ValueKey('dr-item-soon')), findsOneWidget);
    // DR1 rule: an incomplete interval ending on/before the review day is a
    // deadline — both the overdue one and the one ending today.
    expect(find.text('Deadline'), findsNWidgets(2));
  });

  testWidgets('Do now → preview → approve applies through the repository',
      (tester) async {
    env.intervals.put(timed('late', at(10, 9), at(10, 10)));
    await pump(tester);
    await choose(tester, 'late', 'Do now');
    await previewAndApply(tester, approve: true);

    expect(env.intervals.writes, ['update:late']);
    expect(timedRangeOf(env.intervals.store['late']!)!.start, at(11, 10));
    expect(find.text('Applied'), findsOneWidget);
  });

  testWidgets('declining the confirmation changes nothing', (tester) async {
    env.intervals.put(timed('late', at(10, 9), at(10, 10)));
    await pump(tester);
    await choose(tester, 'late', 'Do now');
    await previewAndApply(tester, approve: false);

    expect(env.intervals.writes, isEmpty);
    expect(find.text('Applied'), findsNothing);
  });

  testWidgets('unknown duration asks for minutes, then becomes applicable',
      (tester) async {
    env.intervals.put(untimed('open', at(11, 0)));
    await pump(tester);
    await choose(tester, 'open', 'Do now');
    expect(find.byKey(const ValueKey('dr-duration-open')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dr-preview')));
    await tester.pumpAndSettle();
    expect(find.text('Needs a duration'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('dr-duration-open')), '30');
    await tester.pumpAndSettle();
    await previewAndApply(tester, approve: true);
    expect(env.intervals.writes, ['update:open']);
    expect(timedRangeOf(env.intervals.store['open']!)!.duration,
        const Duration(minutes: 30));
  });

  testWidgets('cancel occurrence shows a destructive confirmation',
      (tester) async {
    env.intervals.put(timed('late', at(10, 9), at(10, 10)));
    await pump(tester);
    await choose(tester, 'late', 'Cancel this occurrence');
    await tester.tap(find.byKey(const ValueKey('dr-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dr-apply')));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(
        find.descendant(
            of: dialog,
            matching: find.textContaining('Only this occurrence will be deleted')),
        findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Apply')));
    await tester.pumpAndSettle();
    expect(env.intervals.writes, ['delete:late']);
  });

  testWidgets('item edited between preview and apply → reported as outdated',
      (tester) async {
    env.intervals.put(timed('late', at(10, 9), at(10, 10)));
    await pump(tester);
    await choose(tester, 'late', 'Do now');
    await tester.tap(find.byKey(const ValueKey('dr-preview')));
    await tester.pumpAndSettle();

    // Edited elsewhere after the preview (fingerprint changes).
    env.intervals.put(timed('late', at(10, 9), at(10, 10, 30)));

    await tester.tap(find.byKey(const ValueKey('dr-apply')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Apply')));
    await tester.pumpAndSettle();

    expect(env.intervals.writes, isEmpty);
    expect(find.text('Outdated — skipped'), findsOneWidget);
  });

  group('settings panel', () {
    const base = DailyReviewSettingsValue(
      enabled: true,
      reviewTimeMinutes: 1200,
      workStartMinutes: 540,
      workEndMinutes: 1080,
      workDayBits: 0x1F,
      bufferMinutes: 0,
    );

    Future<List<DailyReviewSettingsValue>> pumpPanel(
        WidgetTester tester, DailyReviewSettingsValue value) async {
      final changes = <DailyReviewSettingsValue>[];
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(testApp(
        const [],
        Scaffold(
          body: SingleChildScrollView(
            child: DailyReviewSettingsPanel(
                value: value, onChanged: changes.add),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return changes;
    }

    testWidgets('toggle and working-day chips emit updated settings',
        (tester) async {
      final changes = await pumpPanel(tester, base);
      await tester.tap(find.byKey(const ValueKey('dr-settings-enabled')));
      await tester.pump();
      expect(changes.last.enabled, isFalse);

      await tester.tap(find.byKey(const ValueKey('dr-settings-day-6'))); // Sat
      await tester.pump();
      expect(changes.last.workDayBits, 0x1F | (1 << 5));

      await tester.tap(find.byKey(const ValueKey('dr-settings-day-1'))); // Mon
      await tester.pump();
      expect(changes.last.workDayBits, 0x1F & ~1);
    });

    testWidgets('disabled settings lock the detail controls', (tester) async {
      final changes = await pumpPanel(tester, base.copyWith(enabled: false));
      await tester.tap(find.byKey(const ValueKey('dr-settings-day-6')));
      await tester.pump();
      expect(changes, isEmpty);
    });
  });

  test('availabilityFromSettings maps hours, day bits and buffer', () {
    final a = availabilityFromSettings(
        workStartMinutes: 480,
        workEndMinutes: 1020,
        workDayBits: 1 | (1 << 6), // Mon + Sun
        bufferMinutes: 10);
    expect(a.workingHours.keys.toSet(), {DateTime.monday, DateTime.sunday});
    expect(a.workingHours[DateTime.monday]!.startMinute, 480);
    expect(a.workingHours[DateTime.monday]!.endMinute, 1020);
    expect(a.buffer, const Duration(minutes: 10));
  });
}
