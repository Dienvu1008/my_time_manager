import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/reminder_rule_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_calendar_event.dart';

import '../shared/fake_repositories.dart';
import '../shared/test_harness.dart';

/// Records created / updated events.
class _RecordingCalendarRepository extends FakeCalendarRepository {
  final List<CalendarEvent> created = [];
  final List<CalendarEvent> updated = [];

  @override
  Future<void> createCalendarEvent(CalendarEvent event) async =>
      created.add(event);

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async =>
      updated.add(event);
}

/// In-memory rules; records replaceRulesFor calls; can fail on replace.
class _FakeRuleRepository implements ReminderRuleRepository {
  final List<ReminderRule> rules = [];
  final List<List<ReminderRule>> replaced = [];
  bool failReplace = false;

  @override
  Future<List<ReminderRule>> getRulesFor(
          String entityType, String entityId) async =>
      rules
          .where((r) => r.entityType == entityType && r.entityId == entityId)
          .toList();

  @override
  Future<void> replaceRulesFor(
    String entityType,
    String entityId,
    List<ReminderRule> rules, {
    required ReminderRuleKind kind,
  }) async {
    if (failReplace) throw StateError('db locked');
    expect(entityType, ReminderEntityType.calendarEvent);
    expect(kind, ReminderRuleKind.absolute);
    replaced.add(rules);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingCalendarRepository calendar;
  late _FakeRuleRepository ruleRepo;

  setUp(() {
    calendar = _RecordingCalendarRepository();
    ruleRepo = _FakeRuleRepository();
  });

  Future<void> open(WidgetTester tester, {CalendarEvent? event}) async {
    await tester.pumpWidget(testApp(
      [
        RepositoryProvider<CalendarRepository>.value(value: calendar),
        RepositoryProvider<TaskListRepository>.value(
            value: FakeTaskListRepository()),
        RepositoryProvider<ReminderRuleRepository>.value(value: ruleRepo),
      ],
      launcher(AddOrEditCalendarEventPage(event: event)),
    ));
    await tester.pumpAndSettle(); // AppLocalizations nạp bất đồng bộ
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
  }

  CalendarEvent existing() => CalendarEvent(
        id: 'ev1',
        title: 'Meeting',
        start: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
        end: EventDateTime(dateTime: DateTime(2026, 5, 1, 11)),
        reminders: const EventReminders(useDefault: false, overrides: [
          EventReminderOverride(method: ReminderMethod.popup, minutes: 30),
          EventReminderOverride(method: ReminderMethod.email, minutes: 60),
        ]),
      );

  testWidgets('new event saves popup 10 and writes absolute rules',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField).first, 'Standup');
    await save(tester);

    final event = calendar.created.single;
    expect(event.title, 'Standup');
    expect(event.reminders.useDefault, isFalse);
    expect(event.reminders.overrides, const [
      EventReminderOverride(method: ReminderMethod.popup, minutes: 10),
    ]);
    expect(ruleRepo.replaced, [isEmpty]);
    expect(find.textContaining('result: '), findsOneWidget);
    expect(find.byType(AddOrEditCalendarEventPage), findsNothing);
  });

  testWidgets(
      'existing event keeps non-popup overrides and unchanged absolute rule ids',
      (tester) async {
    final rule = ReminderRule.absolute(
      entityType: ReminderEntityType.calendarEvent,
      entityId: 'ev1',
      at: const WallClock(2026, 5, 1, 8, 0),
    );
    ruleRepo.rules.add(rule);
    await open(tester, event: existing());
    await save(tester);

    final event = calendar.updated.single;
    expect(event.reminders.useDefault, isFalse);
    expect(event.reminders.overrides, const [
      EventReminderOverride(method: ReminderMethod.popup, minutes: 30),
      EventReminderOverride(method: ReminderMethod.email, minutes: 60),
    ]);
    expect(ruleRepo.replaced.single.map((r) => r.id), [rule.id]);
  });

  testWidgets('calendar default switch saves useDefault', (tester) async {
    await open(tester, event: existing());
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(calendar.updated.single.reminders.useDefault, isTrue);
  });

  testWidgets('rule write failure shows an error and still closes the page',
      (tester) async {
    ruleRepo.failReplace = true;
    await open(tester, event: existing());
    await save(tester);

    expect(calendar.updated, hasLength(1));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('specific-time reminders could not be saved'),
        findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    expect(find.byType(AddOrEditCalendarEventPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
