// Dữ liệu đầu vào của planner (Phase R, plan item 2).
import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_reminder_rule.dart';
import '../../domain/models/model_task.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/reminder_rule_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/time_interval_repository.dart';

/// Ảnh chụp mọi thực thể liên quan tới nhắc nhở.
class ReminderInputs {
  final List<TimeInterval> intervals;

  /// Sự kiện đang hiển thị (đã loại thùng rác / lưu trữ).
  final List<CalendarEvent> events;

  /// Task đang hiển thị (đã loại thùng rác / lưu trữ).
  final List<Task> tasks;
  final List<ReminderRule> rules;

  const ReminderInputs({
    this.intervals = const [],
    this.events = const [],
    this.tasks = const [],
    this.rules = const [],
  });
}

/// Nguồn nạp [ReminderInputs].
abstract class ReminderInputSource {
  Future<ReminderInputs> load();
}

/// Nạp từ các repository.
class RepositoryReminderInputSource implements ReminderInputSource {
  final TimeIntervalRepository timeIntervals;
  final CalendarRepository calendar;
  final TaskRepository tasks;
  final ReminderRuleRepository rules;

  const RepositoryReminderInputSource({
    required this.timeIntervals,
    required this.calendar,
    required this.tasks,
    required this.rules,
  });

  @override
  Future<ReminderInputs> load() async {
    final results = await Future.wait<List<Object>>([
      timeIntervals.getTimeIntervals(),
      calendar.getCalendarEvents(),
      tasks.getTasks(),
      rules.getAllRules(),
    ]);
    return ReminderInputs(
      intervals: results[0].cast<TimeInterval>(),
      events: results[1].cast<CalendarEvent>(),
      tasks: results[2].cast<Task>(),
      rules: results[3].cast<ReminderRule>(),
    );
  }
}
