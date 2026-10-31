import '../../../application/reminders/reminder_coordinator.dart';
import '../../../domain/models/model_reminder_rule.dart';
import '../../../domain/repositories/reminder_rule_repository.dart';
import '../../../domain/repositories/time_interval_repository.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_guard.dart';
import '../tool_result.dart';

/// Loads the upcoming-reminders read model (Phase R). Production passes
/// `ReminderCoordinator.upcoming`; tests pass a closure.
typedef UpcomingRemindersLoader = Future<List<UpcomingReminder>> Function();

/// `"value"` of a string argument for confirmation summaries, or `?`.
String _q(Map<String, dynamic> a, String key) {
  final v = a[key];
  return v is String && v.isNotEmpty ? '"$v"' : '?';
}

class ListUpcomingRemindersTool extends Tool {
  ListUpcomingRemindersTool(this.upcoming, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;
  final UpcomingRemindersLoader upcoming;
  final DateTime Function() _clock;

  static const _defaultLimit = 20;
  static const _maxLimit = 50;

  @override
  String get name => 'list_upcoming_reminders';
  @override
  String get description =>
      'List upcoming reminders (planned notifications) sorted by fire time, '
      'in local time. Optionally limit the count or only the next N days.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'limit': {
            'type': 'integer',
            'description': 'Max results (default 20, max 50).'
          },
          'withinDays': {
            'type': 'integer',
            'description': 'Only reminders firing within this many days.'
          },
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) =>
      guardToolCall(a, (args) async {
        final limit =
            (args.optInt('limit') ?? _defaultLimit).clamp(1, _maxLimit);
        final withinDays = args.optInt('withinDays');
        if (withinDays != null && withinDays < 1) {
          throw const ToolArgumentError('"withinDays" must be at least 1.');
        }
        var items = await upcoming();
        if (withinDays != null) {
          final until = _clock().add(Duration(days: withinDays));
          items = items.where((u) => u.fireAtLocal.isBefore(until)).toList();
        }
        final shown = items.take(limit).toList();
        return ToolResult.ok({
          'count': shown.length,
          'reminders': [
            for (final u in shown)
              {
                'entityType': u.planned.entityType,
                'entityId': u.planned.entityId,
                'title': u.planned.title,
                'fireAt': u.fireAtLocal.toIso8601String(),
                if (u.planned.offsetMinutes != null)
                  'offsetMinutes': u.planned.offsetMinutes,
                'source': u.planned.source.name,
                'scheduled': u.scheduled,
                if (u.planned.shiftedByQuietHours) 'shiftedByQuietHours': true,
              },
          ],
        });
      });
}

class AddIntervalReminderTool extends Tool implements ConfirmationDescriber {
  const AddIntervalReminderTool(this.rules, this.timeIntervals);
  final ReminderRuleRepository rules;
  final TimeIntervalRepository timeIntervals;

  /// One week.
  static const _maxMinutes = 10080;

  @override
  String get name => 'add_interval_reminder';
  @override
  String get description =>
      'Add a reminder N minutes before a planned time interval starts '
      '(0–10080). Adding the same offset again is a no-op.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'timeIntervalId': {'type': 'string'},
          'minutesBefore': {'type': 'integer'},
          'priority': {
            'type': 'string',
            'enum': ['normal', 'high'],
          },
        },
        'required': ['timeIntervalId', 'minutesBefore'],
      };
  @override
  String confirmationSummary(Map<String, dynamic> a) =>
      'Remind ${a['minutesBefore'] is num ? a['minutesBefore'] : '?'} '
      'minute(s) before time interval ${_q(a, 'timeIntervalId')}'
      '${a['priority'] == 'high' ? ' (high priority)' : ''}.';
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) =>
      guardToolCall(a, (args) async {
        final id = args.requireString('timeIntervalId');
        final minutes = args.optInt('minutesBefore');
        if (minutes == null) {
          throw const ToolArgumentError(
              '"minutesBefore" is required and must be an integer.');
        }
        if (minutes < 0 || minutes > _maxMinutes) {
          throw const ToolArgumentError(
              '"minutesBefore" must be between 0 and $_maxMinutes.');
        }
        final priority = args.optEnum('priority', ReminderPriority.values) ??
            ReminderPriority.normal;
        try {
          await timeIntervals.getTimeInterval(id);
        } catch (_) {
          return ToolResult.failure(
              ToolResult.codeNotFound, 'No time interval with id "$id".');
        }
        final existing =
            await rules.getRulesFor(ReminderEntityType.timeInterval, id);
        for (final r in existing) {
          if (r.enabled &&
              r.kind == ReminderRuleKind.offset &&
              r.offsetMinutes == minutes) {
            return ToolResult.ok({
              'ruleId': r.id,
              'timeIntervalId': id,
              'minutesBefore': minutes,
              'alreadyExists': true,
            });
          }
        }
        // Rule path (Phase R): the repository triggers reconciliation, so no
        // scheduling happens here.
        final rule = ReminderRule.offset(
          entityType: ReminderEntityType.timeInterval,
          entityId: id,
          minutes: minutes,
          priority: priority,
        );
        await rules.saveRule(rule);
        return ToolResult.ok({
          'ruleId': rule.id,
          'timeIntervalId': id,
          'minutesBefore': minutes,
          'priority': priority.name,
        });
      });
}

/// Build the reminder tools whose dependencies are present.
List<Tool> reminderTools({
  UpcomingRemindersLoader? upcoming,
  ReminderRuleRepository? rules,
  required TimeIntervalRepository timeIntervals,
}) =>
    [
      if (upcoming != null) ListUpcomingRemindersTool(upcoming),
      if (rules != null) AddIntervalReminderTool(rules, timeIntervals),
    ];
