// Availability model for Daily Review (Phase DR1).
//
// "An empty slot is not automatically free": a time range is FREE only if it
// is inside the working hours of its weekday AND not blocked by an opaque
// (busy) calendar event AND not overlapping another scheduled incomplete time
// interval. Pure Dart — no Flutter UI, no sqflite, no notification plugins.
import '../../domain/models/model_calendar_event.dart';
import '../../domain/models/model_time_interval.dart';

/// Expands a recurring [CalendarEvent] into the START times of its occurrences
/// in `[from, to]`. Structurally identical to the Phase R
/// `CalendarOccurrenceExpander`, so the app can pass the same closure
/// (`expandRecurringEvent(...).map((o) => o.start.effective)`).
typedef EventOccurrenceExpander = List<DateTime> Function(
    CalendarEvent event, DateTime from, DateTime to);

/// Working hours of one weekday as minutes since local midnight,
/// `[startMinute, endMinute)`.
class WorkingHours {
  const WorkingHours(this.startMinute, this.endMinute)
      : assert(startMinute >= 0 && startMinute <= 24 * 60),
        assert(endMinute >= 0 && endMinute <= 24 * 60);

  /// Convenience: `WorkingHours.hm(9, 0, 18, 0)`.
  const WorkingHours.hm(int startHour, int startMin, int endHour, int endMin)
      : this(startHour * 60 + startMin, endHour * 60 + endMin);

  final int startMinute;
  final int endMinute;

  bool get isEmpty => endMinute <= startMinute;

  @override
  bool operator ==(Object other) =>
      other is WorkingHours &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);

  @override
  String toString() => 'WorkingHours($startMinute-$endMinute)';
}

/// Value object describing when work may be scheduled.
///
/// - [workingHours]: per ISO weekday (`DateTime.monday` = 1 … `sunday` = 7);
///   a missing / empty entry = no working time that day.
/// - [minSlot]: the smallest free gap considered usable (a placement needs a
///   gap ≥ max(duration, minSlot)).
/// - [buffer]: kept free on both sides of every busy block.
/// - [granularityMinutes]: proposed starts are rounded UP to this grid.
/// - [horizonDays]: how many days (incl. the start day) a "reschedule" may
///   search for a slot.
class Availability {
  const Availability({
    this.workingHours = defaultWorkingHours,
    this.minSlot = const Duration(minutes: 15),
    this.buffer = Duration.zero,
    this.granularityMinutes = 5,
    this.horizonDays = 7,
  })  : assert(granularityMinutes > 0),
        assert(horizonDays > 0);

  /// Default: 09:00–18:00 Monday–Friday.
  static const Map<int, WorkingHours> defaultWorkingHours = {
    DateTime.monday: WorkingHours.hm(9, 0, 18, 0),
    DateTime.tuesday: WorkingHours.hm(9, 0, 18, 0),
    DateTime.wednesday: WorkingHours.hm(9, 0, 18, 0),
    DateTime.thursday: WorkingHours.hm(9, 0, 18, 0),
    DateTime.friday: WorkingHours.hm(9, 0, 18, 0),
  };

  final Map<int, WorkingHours> workingHours;
  final Duration minSlot;
  final Duration buffer;
  final int granularityMinutes;
  final int horizonDays;

  Availability copyWith({
    Map<int, WorkingHours>? workingHours,
    Duration? minSlot,
    Duration? buffer,
    int? granularityMinutes,
    int? horizonDays,
  }) =>
      Availability(
        workingHours: workingHours ?? this.workingHours,
        minSlot: minSlot ?? this.minSlot,
        buffer: buffer ?? this.buffer,
        granularityMinutes: granularityMinutes ?? this.granularityMinutes,
        horizonDays: horizonDays ?? this.horizonDays,
      );

  /// The working window of [day]'s local date, or null when not a working day.
  TimeRange? workingWindowOn(DateTime day) {
    final wh = workingHours[day.weekday];
    if (wh == null || wh.isEmpty) return null;
    final midnight = DateTime(day.year, day.month, day.day);
    return TimeRange(midnight.add(Duration(minutes: wh.startMinute)),
        midnight.add(Duration(minutes: wh.endMinute)));
  }

  /// True iff `[range]` lies entirely within ONE working window.
  bool isWithinWorkingHours(TimeRange range) {
    final w = workingWindowOn(range.start);
    return w != null && !range.start.isBefore(w.start) && !range.end.isAfter(w.end);
  }
}

/// Half-open time range `[start, end)`.
class TimeRange {
  TimeRange(this.start, this.end)
      : assert(!end.isBefore(start), 'end must not be before start');

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  bool overlaps(TimeRange other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimeRange($start → $end)';
}

/// Where a busy block comes from.
enum BusySource { calendarEvent, timeInterval, proposal }

/// A blocked range with its origin (for conflict reporting).
class BusyBlock {
  const BusyBlock(this.range, this.source, this.refId);

  final TimeRange range;
  final BusySource source;

  /// Calendar event id / time interval id / proposal item id.
  final String refId;

  @override
  String toString() => 'BusyBlock(${source.name}:$refId $range)';
}

/// The concrete start/end of a time interval when BOTH a date and a time are
/// known for start and end; null otherwise (unknown duration, Q-DR3).
TimeRange? timedRangeOf(TimeInterval i) {
  if (i.isStartDateUndefined ||
      i.isEndDateUndefined ||
      i.isStartTimeUndefined ||
      i.isEndTimeUndefined) {
    return null;
  }
  final s = i.calendarStartDateTime;
  final e = i.calendarEndDateTime;
  if (s == null || e == null || e.isBefore(s)) return null;
  return TimeRange(s, e);
}

/// Computes busy blocks and free slots. Pure: all inputs are passed in.
///
/// Blocking rules (DR-b):
/// - calendar events block iff `transparency != transparent` AND
///   `status != cancelled`; recurring events are expanded with [expander]
///   (without one only the base occurrence blocks); all-day events block
///   their whole day(s).
/// - time intervals block iff incomplete and with a fully known start/end
///   (date AND time); ids in `excludeIntervalIds` (the items being moved)
///   don't block.
class AvailabilityCalculator {
  AvailabilityCalculator(this.availability, {this.expander});

  final Availability availability;
  final EventOccurrenceExpander? expander;

  /// Busy blocks overlapping `[window]`, sorted by start then refId.
  List<BusyBlock> busyBlocks({
    required TimeRange window,
    required Iterable<CalendarEvent> events,
    required Iterable<TimeInterval> intervals,
    Set<String> excludeIntervalIds = const {},
    Iterable<BusyBlock> extra = const [],
  }) {
    final blocks = <BusyBlock>[];
    for (final ev in events) {
      if (!blocksAvailability(ev)) continue;
      for (final r in eventRanges(ev, window)) {
        if (r.overlaps(window)) {
          blocks.add(BusyBlock(r, BusySource.calendarEvent, ev.id));
        }
      }
    }
    for (final i in intervals) {
      if (i.isCompleted || excludeIntervalIds.contains(i.id)) continue;
      final r = timedRangeOf(i);
      if (r != null && r.overlaps(window)) {
        blocks.add(BusyBlock(r, BusySource.timeInterval, i.id));
      }
    }
    for (final b in extra) {
      if (b.range.overlaps(window)) blocks.add(b);
    }
    blocks.sort((a, b) {
      final c = a.range.start.compareTo(b.range.start);
      return c != 0 ? c : a.refId.compareTo(b.refId);
    });
    return blocks;
  }

  /// DR-b: opaque and not cancelled.
  static bool blocksAvailability(CalendarEvent ev) =>
      ev.transparency != EventTransparency.transparent &&
      ev.status != EventStatus.cancelled;

  /// Concrete occurrence ranges of [ev] relevant to [window].
  List<TimeRange> eventRanges(CalendarEvent ev, TimeRange window) {
    final baseStart = ev.start.effective;
    var baseEnd = ev.end.effective;
    if (ev.isAllDay && !baseEnd.isAfter(baseStart)) {
      baseEnd = baseStart.add(const Duration(days: 1));
    }
    if (baseEnd.isBefore(baseStart)) baseEnd = baseStart;
    final length = baseEnd.difference(baseStart);
    final exp = expander;
    if (ev.isRecurring && exp != null) {
      // Look back by the event length so an occurrence that started before
      // the window but still overlaps it is included.
      final starts = exp(ev, window.start.subtract(length), window.end);
      return [for (final s in starts) TimeRange(s, s.add(length))];
    }
    return [TimeRange(baseStart, baseEnd)];
  }

  /// Earliest placement of [duration] in `[from, until)` that lies within
  /// working hours and keeps [Availability.buffer] away from every block.
  /// The usable gap must be ≥ max(duration, minSlot). Null when none fits.
  TimeRange? findSlot({
    required DateTime from,
    required DateTime until,
    required Duration duration,
    required List<BusyBlock> busy,
  }) {
    if (duration <= Duration.zero || !until.isAfter(from)) return null;
    final need = duration > availability.minSlot ? duration : availability.minSlot;
    final buffer = availability.buffer;
    var day = DateTime(from.year, from.month, from.day);
    while (day.isBefore(until)) {
      final w = availability.workingWindowOn(day);
      if (w != null) {
        var gapStart = w.start.isBefore(from) ? from : w.start;
        final windowEnd = w.end.isAfter(until) ? until : w.end;
        // Blocks sorted by start; walk gaps between buffered blocks.
        final dayBlocks = [
          for (final b in busy)
            TimeRange(b.range.start.subtract(buffer), b.range.end.add(buffer))
        ]..sort((a, b) => a.start.compareTo(b.start));
        for (final b in [...dayBlocks, TimeRange(windowEnd, windowEnd)]) {
          if (!gapStart.isBefore(windowEnd)) break;
          final gapEnd = b.start.isBefore(windowEnd) ? b.start : windowEnd;
          final start = _roundUp(gapStart);
          if (!gapEnd.isBefore(start) && gapEnd.difference(start) >= need) {
            return TimeRange(start, start.add(duration));
          }
          if (b.end.isAfter(gapStart)) gapStart = b.end;
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return null;
  }

  /// Blocks overlapping [range] (raw overlap, no buffer).
  List<BusyBlock> conflictsWith(TimeRange range, List<BusyBlock> busy) =>
      [for (final b in busy) if (b.range.overlaps(range)) b];

  /// Free working minutes in `[from, until)` (no buffer applied).
  Duration freeTimeBetween(
      DateTime from, DateTime until, List<BusyBlock> busy) {
    var total = Duration.zero;
    var day = DateTime(from.year, from.month, from.day);
    while (day.isBefore(until)) {
      final w = availability.workingWindowOn(day);
      if (w != null) {
        final s = w.start.isBefore(from) ? from : w.start;
        final e = w.end.isAfter(until) ? until : w.end;
        if (e.isAfter(s)) {
          var cursor = s;
          var free = Duration.zero;
          final sorted = [for (final b in busy) b.range]
            ..sort((a, b) => a.start.compareTo(b.start));
          for (final r in sorted) {
            if (!r.end.isAfter(cursor)) continue;
            if (!r.start.isBefore(e)) break;
            if (r.start.isAfter(cursor)) free += r.start.difference(cursor);
            if (r.end.isAfter(cursor)) cursor = r.end;
          }
          if (e.isAfter(cursor)) free += e.difference(cursor);
          total += free;
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return total;
  }

  DateTime _roundUp(DateTime t) {
    final g = availability.granularityMinutes;
    var r = DateTime(t.year, t.month, t.day, t.hour, t.minute);
    if (r.isBefore(t)) r = r.add(const Duration(minutes: 1));
    final rem = (r.hour * 60 + r.minute) % g;
    return rem == 0 ? r : r.add(Duration(minutes: g - rem));
  }
}
