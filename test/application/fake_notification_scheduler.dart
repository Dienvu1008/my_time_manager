import 'dart:async';

import 'package:my_time_manager/application/reminders/notification_scheduler.dart';
import 'package:my_time_manager/application/reminders/reminder_inputs.dart';

/// [NotificationScheduler] ghi lại mọi lời gọi, giữ tập `active` như OS.
class FakeNotificationScheduler implements NotificationScheduler {
  final List<ScheduledReminder> scheduleCalls = [];
  final List<int> cancelCalls = [];
  int cancelAllCount = 0;
  final Map<int, ScheduledReminder> active = {};
  ReminderPermission permission = ReminderPermission.granted;
  bool throwOnSchedule = false;
  int requestPermissionCalls = 0;

  int get callCount => scheduleCalls.length + cancelCalls.length + cancelAllCount;

  void clearCalls() {
    scheduleCalls.clear();
    cancelCalls.clear();
    cancelAllCount = 0;
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    if (throwOnSchedule) throw StateError('schedule failed');
    scheduleCalls.add(reminder);
    active[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls.add(id);
    active.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    active.clear();
  }

  @override
  Future<ReminderPermission> permissionStatus() async => permission;

  bool exactAllowed = true;

  @override
  Future<bool> exactAlarmsAllowed() async => exactAllowed;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    permission = ReminderPermission.granted;
    exactAllowed = true;
    return true;
  }
}

/// Nguồn đầu vào trong bộ nhớ, có thể sửa / làm lỗi / chặn.
class FakeReminderInputSource implements ReminderInputSource {
  ReminderInputs inputs;
  bool fail = false;
  int loads = 0;
  Completer<void>? gate;

  FakeReminderInputSource([this.inputs = const ReminderInputs()]);

  @override
  Future<ReminderInputs> load() async {
    loads++;
    final g = gate;
    if (g != null) await g.future;
    if (fail) throw StateError('load failed');
    return inputs;
  }
}
