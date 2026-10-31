// Reconcile nhắc nhở không trạng thái bền (Phase R, plan item 3, D4 / D6 / D8).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/model_reminder_rule.dart';
import 'notification_scheduler.dart';
import 'planned_reminder.dart';
import 'quiet_hours.dart';
import 'reminder_inputs.dart';
import 'reminder_planner.dart';
import 'reminder_selection.dart';
import 'reminder_text.dart';
import 'wall_clock_resolver.dart';

/// Giới hạn số thông báo chờ trên iOS/macOS.
const int kPendingLimitIos = 64;

/// Giới hạn trên Android (chừa biên dưới trần ~500 alarm).
const int kPendingLimitAndroid = 400;

/// Giới hạn mặc định cho nền tảng khác.
const int kPendingLimitDefault = 64;

int pendingLimitFor(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return kPendingLimitIos;
    case TargetPlatform.android:
      return kPendingLimitAndroid;
    default:
      return kPendingLimitDefault;
  }
}

class ReminderCoordinatorConfig {
  final int maxPending;
  final Duration horizon;

  const ReminderCoordinatorConfig({
    this.maxPending = kPendingLimitDefault,
    this.horizon = const Duration(days: 30),
  });
}

/// Sức khỏe engine nhắc (UI hiển thị banner khi bị từ chối quyền).
class ReminderHealth {
  final ReminderPermission permission;

  /// false = Android 12+ chưa cho phép báo thức chính xác (nhắc có thể trễ).
  final bool exactAlarmsAllowed;
  final String? lastError;

  const ReminderHealth({
    this.permission = ReminderPermission.notApplicable,
    this.exactAlarmsAllowed = true,
    this.lastError,
  });

  ReminderHealth copyWith({
    ReminderPermission? permission,
    bool? exactAlarmsAllowed,
    String? lastError,
  }) =>
      ReminderHealth(
        permission: permission ?? this.permission,
        exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
        lastError: lastError ?? this.lastError,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderHealth &&
      other.permission == permission &&
      other.exactAlarmsAllowed == exactAlarmsAllowed &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(permission, exactAlarmsAllowed, lastError);

  @override
  String toString() =>
      'ReminderHealth($permission, exact: $exactAlarmsAllowed, $lastError)';
}

class ReconcileResult {
  final int scheduled;
  final int cancelled;
  final int deferred;
  final int errors;

  const ReconcileResult({
    this.scheduled = 0,
    this.cancelled = 0,
    this.deferred = 0,
    this.errors = 0,
  });

  @override
  String toString() => 'ReconcileResult(scheduled: $scheduled, '
      'cancelled: $cancelled, deferred: $deferred, errors: $errors)';
}

/// Một mốc nhắc sắp tới (cho màn "Upcoming reminders").
class UpcomingReminder {
  final PlannedReminder planned;

  /// Wall-clock cục bộ của fireAt (DateTime không gắn múi giờ).
  final DateTime fireAtLocal;

  /// false = bị hoãn do vượt giới hạn nền tảng.
  final bool scheduled;

  const UpcomingReminder({
    required this.planned,
    required this.fireAtLocal,
    required this.scheduled,
  });
}

class _PendingRun {
  bool reset;
  final Set<int> alsoCancel;
  final Completer<ReconcileResult> completer = Completer<ReconcileResult>();
  _PendingRun(this.reset, Iterable<int> alsoCancel)
      : alsoCancel = alsoCancel.toSet();
}

/// Tính tập mốc nhắc mong muốn và đồng bộ với [NotificationScheduler].
///
/// - Reset ([reconcileAll]): `cancelAll()` rồi đặt mọi id được chọn.
/// - Tăng dần ([reconcile]): hủy `(snapshot chưa bắn ∪ alsoCancel) − selected`,
///   đặt các id mới hoặc đổi payload. Mốc đã bắn bị bỏ khỏi snapshot mà không
///   hủy (giữ thông báo trên khay). Snapshot chỉ nằm trong bộ nhớ.
/// - Các lần chạy được tuần tự hóa và gộp: một lần đang chạy + tối đa một lần
///   chờ (alsoCancel được cộng dồn).
/// - Không bao giờ throw; lỗi được đếm trong [ReconcileResult.errors] và
///   [health].
class ReminderCoordinator {
  final ReminderInputSource _inputs;
  final NotificationScheduler _scheduler;
  final tz.Location Function() _location;
  final DateTime Function() _now;
  final ReminderCoordinatorConfig config;
  final CalendarOccurrenceExpander? _expandOccurrences;

  ReminderCoordinator({
    required ReminderInputSource inputs,
    required NotificationScheduler scheduler,
    required tz.Location Function() location,
    DateTime Function()? now,
    this.config = const ReminderCoordinatorConfig(),
    CalendarOccurrenceExpander? expandOccurrences,
    String Function()? habitReminderBody,
  })  : _inputs = inputs,
        _scheduler = scheduler,
        _location = location,
        _now = now ?? DateTime.now,
        _expandOccurrences = expandOccurrences,
        _habitReminderBody = habitReminderBody;

  /// Nội dung (đã bản địa hóa) của nhắc thói quen; đọc lại mỗi lần chạy.
  final String Function()? _habitReminderBody;

  final ValueNotifier<ReminderHealth> health =
      ValueNotifier(const ReminderHealth());

  QuietHours _quietHours = QuietHours.off;
  QuietHours get quietHours => _quietHours;
  set quietHours(QuietHours value) => _quietHours = value;

  /// id → payload đã đặt ở lần chạy trước (không lưu bền).
  Map<int, ScheduledReminder> _snapshot = {};

  _PendingRun? _pending;
  Future<void>? _pump;

  /// Reconcile tăng dần.
  Future<ReconcileResult> reconcile({Iterable<int> alsoCancel = const []}) =>
      _enqueue(false, alsoCancel);

  /// Reconcile toàn bộ; mặc định reset (`cancelAll` trước).
  Future<ReconcileResult> reconcileAll({bool reset = true}) =>
      _enqueue(reset, const []);

  /// Tắt nhắc: hủy tất cả và xóa snapshot.
  Future<void> disable() async {
    await _idle();
    try {
      await _scheduler.cancelAll();
    } catch (e) {
      _setError(e);
    }
    _snapshot = {};
  }

  /// Chuyển sang đường legacy: chỉ xóa snapshot (legacy tự cancelAll).
  Future<void> deactivate() async {
    await _idle();
    _snapshot = {};
  }

  /// Danh sách mốc sắp tới (đã chọn + bị hoãn), sắp theo fireAt.
  Future<List<UpcomingReminder>> upcoming() async {
    final ReminderInputs inputs;
    try {
      inputs = await _inputs.load();
    } catch (e) {
      _setError(e);
      return const [];
    }
    final loc = _location();
    final selection = _select(inputs, loc);
    UpcomingReminder toUpcoming(PlannedReminder p, bool scheduled) =>
        UpcomingReminder(
          planned: p,
          fireAtLocal: wallClockOf(p.fireAt, loc).toLocalDateTime(),
          scheduled: scheduled,
        );
    final list = [
      for (final p in selection.selected) toUpcoming(p, true),
      for (final p in selection.deferred) toUpcoming(p, false),
    ]..sort((a, b) {
        final c = a.planned.fireAt.compareTo(b.planned.fireAt);
        return c != 0 ? c : a.planned.id.compareTo(b.planned.id);
      });
    return list;
  }

  /// Đọc lại trạng thái quyền (thông báo + báo thức chính xác) vào [health].
  Future<ReminderPermission> refreshPermission() async {
    try {
      final p = await _scheduler.permissionStatus();
      final exact = await _scheduler.exactAlarmsAllowed();
      health.value = health.value.copyWith(
          permission: p, exactAlarmsAllowed: exact);
      return p;
    } catch (e) {
      _setError(e);
      return health.value.permission;
    }
  }

  /// Xin quyền (chỉ khi người dùng chủ động), rồi đọc lại trạng thái.
  Future<bool> requestPermission() async {
    var granted = false;
    try {
      granted = await _scheduler.requestPermission();
    } catch (e) {
      _setError(e);
    }
    await refreshPermission();
    return granted;
  }

  // ---------------------------------------------------------------------

  Future<void> _idle() async {
    while (_pump != null) {
      await _pump;
    }
  }

  Future<ReconcileResult> _enqueue(bool reset, Iterable<int> alsoCancel) {
    final pending = _pending;
    if (pending != null) {
      pending.reset = pending.reset || reset;
      pending.alsoCancel.addAll(alsoCancel);
      return pending.completer.future;
    }
    final run = _PendingRun(reset, alsoCancel);
    _pending = run;
    _pump ??= _drain();
    return run.completer.future;
  }

  Future<void> _drain() async {
    // Nhường một microtask để `_pump` được gán trước khi vòng lặp kết thúc.
    await Future<void>.value();
    try {
      while (_pending != null) {
        final run = _pending!;
        _pending = null;
        ReconcileResult result;
        try {
          result = await _run(run.reset, run.alsoCancel);
        } catch (e) {
          _setError(e);
          result = const ReconcileResult(errors: 1);
        }
        run.completer.complete(result);
      }
    } finally {
      _pump = null;
    }
  }

  ReminderSelection _select(ReminderInputs inputs, tz.Location loc) {
    final planner = ReminderPlanner(
      location: loc,
      expandOccurrences: _expandOccurrences,
      habitReminderBody: _habitReminderBody?.call() ?? ReminderText.habitBody,
    );
    final planned = planner.plan(inputs,
        now: _now(), quietHours: _quietHours, horizon: config.horizon);
    return selectWithinLimit(planned, config.maxPending);
  }

  Future<ReconcileResult> _run(bool reset, Set<int> alsoCancel) async {
    var errors = 0;
    Object? lastError;
    void fail(Object e) {
      errors++;
      lastError = e;
    }

    final ReminderInputs inputs;
    try {
      inputs = await _inputs.load();
    } catch (e) {
      // Giữ nguyên snapshot; lần sau thử lại.
      _setError(e);
      return const ReconcileResult(errors: 1);
    }

    var permission = health.value.permission;
    try {
      permission = await _scheduler.permissionStatus();
    } catch (e) {
      fail(e);
    }

    final selection = _select(inputs, _location());
    final desired = <int, ScheduledReminder>{
      for (final p in selection.selected)
        p.id: ScheduledReminder(
          id: p.id,
          fireAt: p.fireAt,
          title: p.title,
          body: p.body,
          important: p.priority == ReminderPriority.high,
        ),
    };

    var scheduled = 0;
    var cancelled = 0;
    final next = <int, ScheduledReminder>{};

    if (reset) {
      try {
        await _scheduler.cancelAll();
      } catch (e) {
        fail(e);
      }
      for (final r in desired.values) {
        try {
          await _scheduler.schedule(r);
          scheduled++;
          next[r.id] = r;
        } catch (e) {
          fail(e);
        }
      }
    } else {
      // Mốc đã tới giờ bắn: chỉ bỏ khỏi snapshot, KHÔNG hủy — cancel(id) trên
      // Android/iOS còn gỡ cả thông báo đang hiển thị trên khay.
      final fireCutoff = _now();
      final live = {
        for (final e in _snapshot.entries)
          if (e.value.fireAt.isAfter(fireCutoff)) e.key,
      };
      final toCancel = {...live, ...alsoCancel}..removeAll(desired.keys);
      for (final id in toCancel) {
        try {
          await _scheduler.cancel(id);
          cancelled++;
        } catch (e) {
          fail(e);
          // Còn trong snapshot để lần sau hủy lại.
          final old = _snapshot[id];
          if (old != null) next[id] = old;
        }
      }
      for (final r in desired.values) {
        final old = _snapshot[r.id];
        if (old == r) {
          next[r.id] = r;
          continue;
        }
        try {
          await _scheduler.schedule(r);
          scheduled++;
          next[r.id] = r;
        } catch (e) {
          fail(e);
          if (old != null) next[r.id] = old;
        }
      }
    }
    _snapshot = next;

    health.value = ReminderHealth(
      permission: permission,
      exactAlarmsAllowed: health.value.exactAlarmsAllowed,
      lastError: lastError?.toString(),
    );
    return ReconcileResult(
      scheduled: scheduled,
      cancelled: cancelled,
      deferred: selection.deferred.length,
      errors: errors,
    );
  }

  void _setError(Object e) {
    debugPrint('ReminderCoordinator lỗi: $e');
    health.value = health.value.copyWith(lastError: '$e');
  }
}
