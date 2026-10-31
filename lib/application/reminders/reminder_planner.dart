// Planner thuần (không I/O): thực thể + rule → mốc nhắc mong muốn
// (Phase R, plan D2 / D3 / D5 / D7 / D8).
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_habit.dart';
import '../../domain/models/model_habit_occurrence.dart';
import '../../domain/models/model_reminder_rule.dart';
import '../../domain/models/model_task.dart';
import '../../domain/models/model_time_interval.dart';
import 'planned_reminder.dart';
import 'quiet_hours.dart';
import 'reminder_ids.dart';
import 'reminder_inputs.dart';
import 'reminder_text.dart';
import 'wall_clock_resolver.dart';

/// Khai triển sự kiện lặp thành thời điểm bắt đầu các lần xuất hiện trong
/// `[from, to]`.
typedef CalendarOccurrenceExpander = List<DateTime> Function(
    CalendarEvent event, DateTime from, DateTime to);

/// Mốc của một lần xuất hiện thực thể.
class _Anchor {
  final DateTime utc;
  final WallClock wall;

  /// Wall-clock dùng làm hậu tố id (chỉ với lần lặp được khai triển).
  final WallClock? occurrence;
  const _Anchor(this.utc, this.wall, this.occurrence);
}

class ReminderPlanner {
  final tz.Location location;
  final CalendarOccurrenceExpander? expandOccurrences;

  /// Nội dung thông báo nhắc thói quen (đã bản địa hóa ở tầng app).
  final String habitReminderBody;

  ReminderPlanner({
    required this.location,
    this.expandOccurrences,
    this.habitReminderBody = ReminderText.habitBody,
  });

  /// Sinh mọi mốc nhắc có `fireAt > now`, sắp theo fireAt (rồi id).
  ///
  /// [horizon] giới hạn cửa sổ khai triển sự kiện lặp (now → now + horizon);
  /// mốc không lặp không bị cắt theo horizon (giữ hành vi legacy).
  List<PlannedReminder> plan(
    ReminderInputs inputs, {
    required DateTime now,
    QuietHours quietHours = QuietHours.off,
    Duration horizon = const Duration(days: 30),
  }) {
    final nowUtc = now.toUtc();
    final rulesByEntity = <String, List<ReminderRule>>{};
    for (final r in inputs.rules) {
      if (!r.enabled) continue;
      rulesByEntity.putIfAbsent('${r.entityType}:${r.entityId}', () => []).add(r);
    }
    List<ReminderRule> rulesOf(String type, String id) =>
        rulesByEntity['$type:$id'] ?? const [];

    // Nhóm theo lần xuất hiện thực thể để khử trùng fireAt (D2).
    final groups = <String, List<PlannedReminder>>{};
    void add(String group, PlannedReminder p) =>
        groups.putIfAbsent(group, () => []).add(p);

    // --- TimeInterval ---
    for (final ti in inputs.intervals) {
      if (ti.isCompleted) continue;
      final rules = rulesOf(ReminderEntityType.timeInterval, ti.id);
      final anchor = _intervalAnchor(ti);
      final title = ReminderText.titleOr(ti.title);
      final group = '${ReminderEntityType.timeInterval}:${ti.id}';
      if (anchor != null) {
        for (final m in ti.reminderMinutesBefore.toSet()) {
          if (m < 0) continue;
          add(
            group,
            _offset(
              id: legacyIntervalReminderId(ti.id, m),
              key: legacyIntervalKey(ti.id, m),
              entityType: ReminderEntityType.timeInterval,
              entityId: ti.id,
              anchor: anchor,
              minutes: m,
              priority:
                  ti.isImportant ? ReminderPriority.high : ReminderPriority.normal,
              title: title,
              source: ReminderSource.legacy,
            ),
          );
        }
      }
      for (final r in rules) {
        final p = _fromRule(r, anchor, title, ReminderEntityType.timeInterval,
            ti.id);
        if (p != null) add(group, p);
      }
    }

    // --- CalendarEvent ---
    for (final ev in inputs.events) {
      if (ev.status == EventStatus.cancelled) continue;
      final popupMinutes = ev.reminders.useDefault
          ? const <int>{}
          : {
              for (final o in ev.reminders.overrides)
                if (o.method == ReminderMethod.popup && o.minutes >= 0)
                  o.minutes,
            };
      final rules = rulesOf(ReminderEntityType.calendarEvent, ev.id);
      if (popupMinutes.isEmpty && rules.isEmpty) continue;
      final title = ReminderText.titleOr(ev.title);
      final offsetRules =
          rules.where((r) => r.kind == ReminderRuleKind.offset).toList();
      final absoluteRules =
          rules.where((r) => r.kind == ReminderRuleKind.absolute).toList();

      if (popupMinutes.isNotEmpty || offsetRules.isNotEmpty) {
        for (final anchor in _eventAnchors(ev, now, horizon)) {
          final group = '${ReminderEntityType.calendarEvent}:${ev.id}'
              '${anchor.occurrence == null ? '' : '@${anchor.occurrence!.toStorage()}'}';
          for (final m in popupMinutes) {
            add(
              group,
              _offset(
                id: stableReminderId(calendarOverrideKey(ev.id, m,
                    occurrence: anchor.occurrence)),
                key: calendarOverrideKey(ev.id, m,
                    occurrence: anchor.occurrence),
                entityType: ReminderEntityType.calendarEvent,
                entityId: ev.id,
                anchor: anchor,
                minutes: m,
                priority: ReminderPriority.normal,
                title: title,
                source: ReminderSource.legacy,
              ),
            );
          }
          for (final r in offsetRules) {
            final p = _fromRule(r, anchor, title,
                ReminderEntityType.calendarEvent, ev.id);
            if (p != null) add(group, p);
          }
        }
      }
      for (final r in absoluteRules) {
        final p = _fromRule(
            r, null, title, ReminderEntityType.calendarEvent, ev.id);
        if (p != null) add('${ReminderEntityType.calendarEvent}:${ev.id}', p);
      }
    }

    // --- Task (chỉ rule tuyệt đối; task không có mốc thời gian) ---
    final tasksById = <String, Task>{for (final t in inputs.tasks) t.id: t};
    for (final r in inputs.rules) {
      if (!r.enabled || r.entityType != ReminderEntityType.task) continue;
      if (r.kind != ReminderRuleKind.absolute) continue;
      final task = tasksById[r.entityId];
      if (task == null || task.isCompleted) continue;
      final p = _fromRule(r, null, ReminderText.titleOr(task.title),
          ReminderEntityType.task, task.id);
      if (p != null) add('${ReminderEntityType.task}:${task.id}', p);
    }

    // --- Habit (Phase H3): reminderTime trên các ngày được lên lịch ---
    _planHabits(inputs, nowUtc, horizon, add);

    // Khử trùng cùng fireAt trong một lần xuất hiện, áp giờ yên lặng, lọc.
    final out = <PlannedReminder>[];
    for (final list in groups.values) {
      final byFire = <DateTime, PlannedReminder>{};
      for (final p in list) {
        final existing = byFire[p.fireAt];
        if (existing == null || _beats(p, existing)) byFire[p.fireAt] = p;
      }
      for (final p in byFire.values) {
        var result = p;
        final shifted = quietHours.adjust(p.fireAt, location);
        if (shifted != p.fireAt) {
          if (p.anchorAt != null && shifted.isAfter(p.anchorAt!)) continue;
          result = p.copyWith(fireAt: shifted, shiftedByQuietHours: true);
        }
        if (!result.fireAt.isAfter(nowUtc)) continue;
        out.add(result);
      }
    }
    out.sort((a, b) {
      final c = a.fireAt.compareTo(b.fireAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return out;
  }

  /// Nhắc thói quen (Phase H3): mỗi ngày được lên lịch (theo rule HIỆN TẠI,
  /// giới hạn bởi startDate / endDate / ngày lưu trữ) trong
  /// `[hôm nay, hôm nay + horizon]` (ngày theo [location]) → một mốc nhắc lúc
  /// `reminderTime` (wall-clock, phân giải DST bằng [resolveWallClock]).
  /// Thói quen lưu trữ / không có giờ nhắc → không có. Ngày đã ghi nhận
  /// (completed / partial / skipped / missed) → bị bỏ. Giờ yên lặng, lọc
  /// quá khứ và giới hạn pending được áp chung ở [plan] / selection.
  void _planHabits(
    ReminderInputs inputs,
    DateTime nowUtc,
    Duration horizon,
    void Function(String group, PlannedReminder p) add,
  ) {
    if (inputs.habits.isEmpty) return;
    final recorded = <String>{
      for (final o in inputs.habitOccurrences)
        if (o.outcome != HabitOutcome.pending)
          '${o.habitId}@${HabitDay.format(o.localDate)}',
    };
    final todayWall = wallClockOf(nowUtc, location);
    final today = DateTime(todayWall.year, todayWall.month, todayWall.day);
    final last =
        DateTime(today.year, today.month, today.day + horizon.inDays);
    for (final h in inputs.habits) {
      if (h.isArchived) continue;
      final time = h.reminderTime;
      if (time == null) continue;
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final title = ReminderText.titleOr(h.title);
      for (final day in h.scheduledDaysBetween(today, last)) {
        final dayKey = HabitDay.format(day);
        if (recorded.contains('${h.id}@$dayKey')) continue;
        final wall = WallClock(day.year, day.month, day.day, hour, minute);
        final key = habitReminderKey(h.id, wall);
        add(
          '${ReminderEntityType.habit}:${h.id}@$dayKey',
          PlannedReminder(
            id: stableReminderId(key),
            key: key,
            entityType: ReminderEntityType.habit,
            entityId: h.id,
            fireAt: resolveWallClock(location, wall),
            title: title,
            body: habitReminderBody,
            source: ReminderSource.habit,
          ),
        );
      }
    }
  }

  /// [candidate] thắng [existing] khi ưu tiên cao hơn; hòa → legacy.
  static bool _beats(PlannedReminder candidate, PlannedReminder existing) {
    if (candidate.priority.index != existing.priority.index) {
      return candidate.priority.index > existing.priority.index;
    }
    return candidate.source == ReminderSource.legacy &&
        existing.source != ReminderSource.legacy;
  }

  _Anchor _fromWall(WallClock wall, {WallClock? occurrence}) =>
      _Anchor(resolveWallClock(location, wall), wall, occurrence);

  _Anchor? _intervalAnchor(TimeInterval ti) {
    final d = ti.startDate;
    if (ti.isStartDateUndefined || d == null) return null;
    final t = ti.isStartTimeUndefined ? null : ti.startTime;
    return _fromWall(
        WallClock(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0));
  }

  _Anchor _anchorOfDateTime(DateTime dt, bool allDay, {bool recurring = false}) {
    if (!allDay && dt.isUtc) {
      final utc = dt;
      final wall = wallClockOf(utc, location);
      return _Anchor(utc, wall, recurring ? wall : null);
    }
    final wall = allDay
        ? WallClock(dt.year, dt.month, dt.day)
        : WallClock(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    return _fromWall(wall, occurrence: recurring ? wall : null);
  }

  List<_Anchor> _eventAnchors(CalendarEvent ev, DateTime now, Duration horizon) {
    final expander = expandOccurrences;
    if (ev.isRecurring && expander != null) {
      final starts = expander(ev, now, now.add(horizon));
      return [
        for (final s in starts)
          _anchorOfDateTime(s, ev.isAllDay, recurring: true),
      ];
    }
    return [_anchorOfDateTime(ev.start.effective, ev.isAllDay)];
  }

  PlannedReminder _offset({
    required int id,
    required String key,
    required String entityType,
    required String entityId,
    required _Anchor anchor,
    required int minutes,
    required ReminderPriority priority,
    required String title,
    required ReminderSource source,
  }) {
    return PlannedReminder(
      id: id,
      key: key,
      entityType: entityType,
      entityId: entityId,
      fireAt: anchor.utc.subtract(Duration(minutes: minutes)),
      anchorAt: anchor.utc,
      offsetMinutes: minutes,
      priority: priority,
      title: title,
      body: ReminderText.offsetBody(minutes, anchor.wall.hour, anchor.wall.minute),
      source: source,
    );
  }

  /// Rule tường minh → mốc nhắc; null nếu bị loại (D8).
  PlannedReminder? _fromRule(ReminderRule r, _Anchor? anchor, String title,
      String entityType, String entityId) {
    if (!r.enabled) return null;
    switch (r.kind) {
      case ReminderRuleKind.offset:
        final m = r.offsetMinutes;
        if (anchor == null || m == null || m < 0) return null;
        final key = ruleKey(r.id, occurrence: anchor.occurrence);
        return _offset(
          id: stableReminderId(key),
          key: key,
          entityType: entityType,
          entityId: entityId,
          anchor: anchor,
          minutes: m,
          priority: r.priority,
          title: title,
          source: ReminderSource.rule,
        );
      case ReminderRuleKind.absolute:
        final at = r.absoluteAt;
        if (at == null) return null;
        final key = ruleKey(r.id);
        return PlannedReminder(
          id: stableReminderId(key),
          key: key,
          entityType: entityType,
          entityId: entityId,
          fireAt: resolveWallClock(location, at),
          priority: r.priority,
          title: title,
          body: ReminderText.absoluteBody(at.hour, at.minute),
          source: ReminderSource.rule,
        );
    }
  }
}
