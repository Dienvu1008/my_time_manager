// Cầu nối C3 ReminderScheduler ↔ ReminderCoordinator + cờ tính năng
// (Phase R, plan D11).
import 'package:flutter/foundation.dart';

import '../../domain/models/model_time_interval.dart';
import '../reminder_scheduler.dart';
import 'reminder_coordinator.dart';
import 'reminder_ids.dart';
import 'reminder_reconcile_trigger.dart';
import 'reminder_settings.dart';

/// - Chế độ coordinator (`coordinatorEnabled`): mọi hook → reconcile.
///   Khi nhắc bị tắt, hook là no-op.
/// - Chế độ legacy: ủy thác cho [ReminderScheduler] cũ (tự kiểm tra cờ bật
///   của NotificationService); trigger là no-op (legacy không đặt nhắc cho
///   sự kiện / task).
class ReminderBridge
    implements ReminderScheduler, ReminderReconcileTrigger, ReminderControl {
  final ReminderCoordinator coordinator;
  final ReminderScheduler legacy;
  final void Function(bool enabled) legacyToggle;
  final Future<List<TimeInterval>> Function() loadIntervals;

  ReminderBridge({
    required this.coordinator,
    required this.legacy,
    required this.legacyToggle,
    required this.loadIntervals,
  });

  ReminderSettings _settings = const ReminderSettings();
  ReminderSettings get settings => _settings;

  bool get _legacyMode => !_settings.coordinatorEnabled;
  bool get _coordinatorActive =>
      _settings.coordinatorEnabled && _settings.enabled;

  @override
  Future<void> schedule(TimeInterval interval) async {
    if (_legacyMode) return legacy.schedule(interval);
    if (_coordinatorActive) await coordinator.reconcile();
  }

  /// Một lần reconcile cho cả lô (tránh O(n·N) khi tạo chuỗi lặp lại).
  @override
  Future<void> scheduleAll(List<TimeInterval> intervals) async {
    if (_legacyMode) return legacy.scheduleAll(intervals);
    if (_coordinatorActive && intervals.isNotEmpty) {
      await coordinator.reconcile();
    }
  }

  @override
  Future<void> cancel(TimeInterval interval) async {
    if (_legacyMode) return legacy.cancel(interval);
    if (_coordinatorActive) {
      await coordinator.reconcile(alsoCancel: legacyCandidateIds(interval));
    }
  }

  @override
  Future<void> rescheduleAll(List<TimeInterval> intervals) async {
    if (_legacyMode) return legacy.rescheduleAll(intervals);
    if (_coordinatorActive) await coordinator.reconcileAll(reset: true);
  }

  @override
  Future<void> requestReconcile({Iterable<int> alsoCancel = const []}) async {
    if (_coordinatorActive) {
      await coordinator.reconcile(alsoCancel: alsoCancel);
    }
  }

  @override
  Future<void> apply(ReminderSettings settings) async {
    _settings = settings;
    legacyToggle(settings.enabled);
    if (!settings.enabled) {
      await coordinator.disable();
      return;
    }
    if (settings.coordinatorEnabled) {
      coordinator.quietHours = settings.quietHours;
      await coordinator.reconcileAll(reset: true);
      return;
    }
    await coordinator.deactivate();
    try {
      await legacy.rescheduleAll(await loadIntervals());
    } catch (e) {
      debugPrint('ReminderBridge legacy rescheduleAll lỗi: $e');
    }
  }
}
