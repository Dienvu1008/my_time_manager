// Model Habit (Phase H1 — Habit data layer)
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/repeat_rule.dart';

/// Local-day helpers for habits. A habit "day" is a wall-clock calendar day
/// stored as `yyyy-MM-dd` (no time zone): changing the device time zone never
/// moves a recorded outcome to another day.
class HabitDay {
  HabitDay._();

  /// Date-only (local midnight) copy of [d]. UTC inputs are converted to local
  /// first.
  static DateTime of(DateTime d) {
    final l = d.isUtc ? d.toLocal() : d;
    return DateTime(l.year, l.month, l.day);
  }

  /// `yyyy-MM-dd` for the local day of [d].
  static String format(DateTime d) {
    final l = of(d);
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  /// Parse `yyyy-MM-dd` (or any ISO string — only the date part is kept).
  /// Null / invalid → null.
  static DateTime? tryParse(Object? raw) {
    if (raw == null) return null;
    final s = raw.toString();
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m == null) return null;
    return DateTime(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  /// `HH:mm` validation for [Habit.reminderTime]. Invalid → null.
  static String? normalizeTime(Object? raw) {
    if (raw == null) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.toString().trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }
}

/// A recurring habit (Phase H1).
///
/// - [recurrence] reuses [RepeatRule] (JSON in the `recurrence` column),
///   anchored at [startDate] (a local day). Default: daily.
/// - Optional target: [targetAmount] + [unit].
/// - [partialCountsTowardStreak]: a `partial` outcome adds to the streak iff
///   true, otherwise it pauses the streak.
/// - [reminderTime] `HH:mm` is stored now and used by Phase H3.
/// - No trash: archive is the default removal; hard delete is an explicit
///   repository operation. `isArchived/archivedAt` are only read from the DB;
///   [toMap] does NOT write them (the DAO's archive methods own them).
///   `deviceId` is attached by the DAO on insert.
class Habit extends Equatable {
  final String id;
  final String title;
  final String description;
  final Color color;
  final RepeatRule recurrence;
  final double? targetAmount;
  final String? unit;
  final bool partialCountsTowardStreak;

  /// Local day (date-only) the recurrence is anchored at.
  final DateTime startDate;

  /// Optional last local day (inclusive).
  final DateTime? endDate;

  /// `HH:mm` or null.
  final String? reminderTime;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updateTimeStamp;
  final String? deviceId;

  static const RepeatRule defaultRecurrence =
      RepeatRule(frequency: RepeatFrequency.daily);

  Habit({
    String? id,
    required this.title,
    String? description,
    Color? color,
    RepeatRule? recurrence,
    this.targetAmount,
    this.unit,
    this.partialCountsTowardStreak = false,
    DateTime? startDate,
    DateTime? endDate,
    String? reminderTime,
    this.isArchived = false,
    this.archivedAt,
    DateTime? createdAt,
    DateTime? updateTimeStamp,
    this.deviceId,
  })  : id = id ?? const Uuid().v4(),
        description = description ?? '',
        color = color ?? Colors.white,
        recurrence = recurrence ?? defaultRecurrence,
        startDate = HabitDay.of(startDate ?? DateTime.now()),
        endDate = endDate == null ? null : HabitDay.of(endDate),
        reminderTime = HabitDay.normalizeTime(reminderTime),
        createdAt = createdAt ?? DateTime.now(),
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  bool get hasTarget => targetAmount != null;

  /// Last local day on which the habit can be scheduled, or null if open
  /// ended: min(endDate, local day of archivedAt when archived). Archiving
  /// stops future scheduling but keeps history.
  DateTime? get effectiveEndDate {
    final archivedDay =
        isArchived && archivedAt != null ? HabitDay.of(archivedAt!) : null;
    if (endDate == null) return archivedDay;
    if (archivedDay == null) return endDate;
    return archivedDay.isBefore(endDate!) ? archivedDay : endDate;
  }

  /// Scheduled local days in `[from, to]` (inclusive) under the CURRENT rule,
  /// bounded by [startDate] and [effectiveEndDate].
  List<DateTime> scheduledDaysBetween(DateTime from, DateTime to) {
    var last = HabitDay.of(to);
    final end = effectiveEndDate;
    if (end != null && end.isBefore(last)) last = end;
    var first = HabitDay.of(from);
    if (first.isBefore(startDate)) first = startDate;
    if (last.isBefore(first)) return const [];
    return recurrence.occurrencesBetween(startDate, first, last);
  }

  /// True if [day] is a scheduled day under the current rule.
  bool isScheduledOn(DateTime day) =>
      scheduledDaysBetween(day, day).isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color.toARGB32(),
      'recurrence': recurrence.toJson(),
      'targetAmount': targetAmount,
      'unit': unit,
      'partialCountsTowardStreak': partialCountsTowardStreak ? 1 : 0,
      'startDate': HabitDay.format(startDate),
      'endDate': endDate == null ? null : HabitDay.format(endDate!),
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    final createdAt = _parseDate(map['createdAt']) ?? now;
    return Habit(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      recurrence: map['recurrence'] == null
          ? null
          : RepeatRule.fromJson(map['recurrence'] as String?),
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      partialCountsTowardStreak:
          (map['partialCountsTowardStreak'] as int? ?? 0) == 1,
      startDate: HabitDay.tryParse(map['startDate']) ?? HabitDay.of(createdAt),
      endDate: HabitDay.tryParse(map['endDate']),
      reminderTime: map['reminderTime'] as String?,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      archivedAt: _parseDate(map['archivedAt']),
      createdAt: createdAt,
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? now,
      deviceId: map['deviceId'] as String?,
    );
  }

  Habit copyWith({
    String? title,
    String? description,
    Color? color,
    RepeatRule? recurrence,
    double? targetAmount,
    bool clearTarget = false,
    String? unit,
    bool? partialCountsTowardStreak,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? reminderTime,
    bool clearReminderTime = false,
    DateTime? updateTimeStamp,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      recurrence: recurrence ?? this.recurrence,
      targetAmount: clearTarget ? null : (targetAmount ?? this.targetAmount),
      unit: clearTarget ? null : (unit ?? this.unit),
      partialCountsTowardStreak:
          partialCountsTowardStreak ?? this.partialCountsTowardStreak,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      isArchived: isArchived,
      archivedAt: archivedAt,
      createdAt: createdAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
      deviceId: deviceId,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() => 'Habit(id: $id, title: $title, '
      'start: ${HabitDay.format(startDate)}, rule: $recurrence)';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        color,
        recurrence,
        targetAmount,
        unit,
        partialCountsTowardStreak,
        startDate,
        endDate,
        reminderTime,
        isArchived,
        archivedAt,
        createdAt,
        updateTimeStamp,
        // deviceId is provenance metadata, not content: excluded on purpose.
      ];
}
