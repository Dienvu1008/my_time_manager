import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart' show Locale;
import 'package:timezone/timezone.dart' as tz;

import '../application/reminders/reminder_bridge.dart';
import '../application/reminders/reminder_coordinator.dart';
import '../application/reminders/reminder_inputs.dart';
import '../data/notifications/local_notification_scheduler.dart';
import '../data/notifications/notification_reminder_scheduler.dart';
import '../data/repositories/sqlite_calendar_repository.dart';
import '../data/repositories/sqlite_habit_repository.dart';
import '../data/repositories/sqlite_reminder_rule_repository.dart';
import '../data/repositories/sqlite_task_repository.dart';
import '../data/repositories/sqlite_time_interval_repository.dart';
import '../screen_calendar/recurrence_expander.dart';
import '../screen_focus_timer/data/notification_service.dart';
import 'app_localizations.dart';

/// Production wiring of the Phase R reminder engine (plan item 5, D11/D12).
///
/// The coordinator reads its inputs through hook-less repository instances
/// (no reminder trigger), so reconciling never re-triggers itself. The
/// [bridge] is injected into the app's repositories and into AppBloc.
///
/// Phase H3: habits (with a reminder time) are an input too; the habit
/// notification body is localized with the app's current [languageCode].
class ReminderModule {
  final ReminderCoordinator coordinator;
  final ReminderBridge bridge;

  ReminderModule({required this.coordinator, required this.bridge});

  String _languageCode = 'en';

  /// Language of the habit reminder body. Changing it requests an
  /// incremental reconcile (no-op in legacy mode / reminders off) so pending
  /// habit notifications get the new text.
  String get languageCode => _languageCode;
  set languageCode(String code) {
    if (code == _languageCode) return;
    _languageCode = code;
    unawaited(bridge.requestReconcile());
  }

  /// Localized body of a habit reminder for [languageCode].
  String habitReminderBody() =>
      AppLocalizations(Locale(_languageCode)).habitReminderBody;

  factory ReminderModule.production() {
    final intervals = SqliteTimeIntervalRepository();
    final inputs = RepositoryReminderInputSource(
      timeIntervals: intervals,
      calendar: SqliteCalendarRepository(),
      tasks: SqliteTaskRepository(),
      rules: SqliteReminderRuleRepository(),
      habits: SqliteHabitRepository(),
    );
    late final ReminderModule module;
    final coordinator = ReminderCoordinator(
      inputs: inputs,
      scheduler: const LocalNotificationScheduler(),
      location: () => tz.local,
      config: ReminderCoordinatorConfig(
          maxPending: pendingLimitFor(defaultTargetPlatform)),
      expandOccurrences: (event, from, to) => expandRecurringEvent(
              event, from, to)
          .map((o) => o.start.effective)
          .toList(),
      habitReminderBody: () => module.habitReminderBody(),
    );
    final bridge = ReminderBridge(
      coordinator: coordinator,
      legacy: const NotificationReminderScheduler(),
      legacyToggle: NotificationService.instance.setEnabled,
      loadIntervals: intervals.getTimeIntervals,
    );
    module = ReminderModule(coordinator: coordinator, bridge: bridge);
    return module;
  }
}
