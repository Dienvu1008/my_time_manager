// Chọn mốc nhắc trong giới hạn nền tảng (Phase R, plan D6 / R-a).
import 'planned_reminder.dart';

class ReminderSelection {
  /// Được lên lịch (tối đa `limit`).
  final List<PlannedReminder> selected;

  /// Vượt giới hạn; sẽ được lên lịch ở các lần reconcile sau.
  final List<PlannedReminder> deferred;

  const ReminderSelection({required this.selected, required this.deferred});
}

int _compare(PlannedReminder a, PlannedReminder b) {
  final byTime = a.fireAt.compareTo(b.fireAt);
  if (byTime != 0) return byTime;
  final byPriority = b.priority.index.compareTo(a.priority.index);
  if (byPriority != 0) return byPriority;
  return a.id.compareTo(b.id);
}

/// Sắp theo fireAt tăng, rồi priority giảm, rồi id tăng; lấy [limit] đầu.
ReminderSelection selectWithinLimit(
    List<PlannedReminder> reminders, int limit) {
  final sorted = [...reminders]..sort(_compare);
  final cut = limit < 0 ? 0 : (limit > sorted.length ? sorted.length : limit);
  return ReminderSelection(
    selected: sorted.sublist(0, cut),
    deferred: sorted.sublist(cut),
  );
}
