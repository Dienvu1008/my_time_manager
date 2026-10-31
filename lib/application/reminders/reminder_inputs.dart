// Dữ liệu đầu vào của planner (Phase R, plan item 2; thói quen: Phase H3).
import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/models/model_reminder_rule.dart';
import '../../domain/models/model_task.dart';
import '../../domain/models/model_time_interval.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/habit_repository.dart';
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

  /// Thói quen đang hoạt động (Phase H3). Thói quen lưu trữ bị planner bỏ qua
  /// kể cả khi có mặt ở đây.
  final List<Habit> habits;

  /// Các ngày đã ghi nhận của [habits] (ít nhất từ hôm qua trở đi): một ngày
  /// đã ghi (completed / partial / skipped / missed) không còn được nhắc.
  final List<HabitOccurrence> habitOccurrences;

  const ReminderInputs({
    this.intervals = const [],
    this.events = const [],
    this.tasks = const [],
    this.rules = const [],
    this.habits = const [],
    this.habitOccurrences = const [],
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

  /// Null → không có nhắc thói quen.
  final HabitRepository? habits;

  /// Đồng hồ (test). Mặc định [DateTime.now].
  final DateTime Function()? now;

  const RepositoryReminderInputSource({
    required this.timeIntervals,
    required this.calendar,
    required this.tasks,
    required this.rules,
    this.habits,
    this.now,
  });

  @override
  Future<ReminderInputs> load() async {
    final results = await Future.wait<List<Object>>([
      timeIntervals.getTimeIntervals(),
      calendar.getCalendarEvents(),
      tasks.getTasks(),
      rules.getAllRules(),
    ]);
    final habitList = <Habit>[];
    final occurrences = <HabitOccurrence>[];
    final habitRepo = habits;
    if (habitRepo != null) {
      // Chỉ thói quen có giờ nhắc mới cần ngày đã ghi; từ hôm qua (biên an
      // toàn khi múi giờ thiết bị khác tz.local).
      final t = (now ?? DateTime.now)();
      final from = DateTime(t.year, t.month, t.day - 1);
      for (final h in await habitRepo.getHabits()) {
        if (h.isArchived || h.reminderTime == null) continue;
        habitList.add(h);
        occurrences.addAll(await habitRepo.occurrencesOf(h.id, from: from));
      }
    }
    return ReminderInputs(
      intervals: results[0].cast<TimeInterval>(),
      events: results[1].cast<CalendarEvent>(),
      tasks: results[2].cast<Task>(),
      rules: results[3].cast<ReminderRule>(),
      habits: habitList,
      habitOccurrences: occurrences,
    );
  }
}
