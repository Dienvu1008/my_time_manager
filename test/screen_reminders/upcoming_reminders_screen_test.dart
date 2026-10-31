import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app.dart' show AppBloc;
import 'package:my_time_manager/application/reminders/notification_scheduler.dart';
import 'package:my_time_manager/application/reminders/reminder_coordinator.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/screen_reminders/upcoming_reminders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/fake_notification_scheduler.dart';
import '../shared/test_harness.dart';

TimeInterval ti(String id, int hour, String title) => TimeInterval(
      id: id,
      title: title,
      startDate: DateTime(2026, 5, 1),
      startTime: TimeOfDay(hour: hour, minute: 0),
      isEndDateUndefined: true,
      reminderMinutesBefore: const [15],
    );

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late FakeNotificationScheduler scheduler;
  late FakeReminderInputSource source;

  ReminderCoordinator build({int maxPending = 64}) => ReminderCoordinator(
        inputs: source,
        scheduler: scheduler,
        location: () => tz.UTC,
        now: () => DateTime.utc(2026, 4, 30, 12),
        config: ReminderCoordinatorConfig(maxPending: maxPending),
      );

  setUp(() {
    scheduler = FakeNotificationScheduler();
    source = FakeReminderInputSource();
  });

  Future<void> open(WidgetTester tester, ReminderCoordinator c) async {
    await tester.pumpWidget(testApp(
      [RepositoryProvider<ReminderCoordinator>.value(value: c)],
      launcher(const UpcomingRemindersScreen()),
    ));
    await tester.pumpAndSettle(); // AppLocalizations nạp bất đồng bộ
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists upcoming reminders sorted by fire time', (tester) async {
    source.inputs = ReminderInputs(
        intervals: [ti('a', 10, 'Alpha'), ti('b', 9, 'Beta')]);
    await open(tester, build());

    expect(find.text('Upcoming reminders'), findsOneWidget);
    final beta = tester.getTopLeft(find.text('Beta'));
    final alpha = tester.getTopLeft(find.text('Alpha'));
    expect(beta.dy, lessThan(alpha.dy));
    expect(find.textContaining('15 minutes before'), findsNWidgets(2));
    expect(find.text('Deferred'), findsNothing);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('empty state', (tester) async {
    await open(tester, build());
    expect(find.text('No upcoming reminders'), findsOneWidget);
    expect(find.text('Add reminders to time intervals or calendar events.'),
        findsOneWidget);
  });

  testWidgets('denied permission shows a banner; Allow requests permission',
      (tester) async {
    scheduler.permission = ReminderPermission.denied;
    source.inputs = ReminderInputs(intervals: [ti('a', 10, 'Alpha')]);
    await open(tester, build());

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget); // không chặn danh sách
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(scheduler.requestPermissionCalls, 1);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  testWidgets('exact alarms not allowed shows a banner; Allow requests',
      (tester) async {
    scheduler.exactAllowed = false;
    source.inputs = ReminderInputs(intervals: [ti('a', 10, 'Alpha')]);
    await open(tester, build());

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.textContaining('Exact alarms are not allowed'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(scheduler.requestPermissionCalls, 1);
    expect(find.byType(MaterialBanner), findsNothing);
  });

  Future<void> openWithSettings(
      WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final bloc = AppBloc();
    addTearDown(bloc.close);
    source.inputs = ReminderInputs(intervals: [ti('a', 10, 'Alpha')]);
    await tester.pumpWidget(BlocProvider<AppBloc>.value(
      value: bloc,
      child: testApp(
        [RepositoryProvider<ReminderCoordinator>.value(value: build())],
        launcher(const UpcomingRemindersScreen()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('reminders off → notice instead of the list', (tester) async {
    await openWithSettings(tester, {AppBloc.remindersEnabledKey: false});
    expect(find.text('Reminders are turned off in Settings.'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('legacy engine → classic-mode notice instead of the list',
      (tester) async {
    await openWithSettings(
        tester, {AppBloc.reminderCoordinatorEnabledKey: false});
    expect(find.textContaining('Classic mode'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('coordinator active with AppBloc → list shown', (tester) async {
    await openWithSettings(tester, {});
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('maxPending 1 marks the later reminder as deferred',
      (tester) async {
    source.inputs = ReminderInputs(
        intervals: [ti('a', 10, 'Alpha'), ti('b', 9, 'Beta')]);
    await open(tester, build(maxPending: 1));

    expect(find.text('Deferred'), findsOneWidget);
    final deferredTile = find.ancestor(
        of: find.text('Deferred'), matching: find.byType(ListTile));
    expect(
        find.descendant(of: deferredTile, matching: find.text('Alpha')),
        findsOneWidget);
  });
}
