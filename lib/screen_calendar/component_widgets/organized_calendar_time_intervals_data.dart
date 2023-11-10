import 'package:my_time_manager/data/models/model_time_interval.dart';

class OrganizedCalendarTimeIntervalsData<T extends Object?> {
  /// Top position from where event tile will start.
  final double top;

  /// End position from where event tile will end.
  final double bottom;

  /// Left position from where event tile will start.
  final double left;

  /// Right position where event tile will end.
  final double right;

  /// List of events to display in given tile.
  //final List<CalendarEventData<T>> events;

  final List<TimeInterval> events;

  /// Start duration of event/event list.
  final DateTime startDuration;

  /// End duration of event/event list.
  final DateTime endDuration;

  /// Provides event data with its [left], [right], [top], and [bottom]
  /// boundary.
  OrganizedCalendarTimeIntervalsData({
    required this.startDuration,
    required this.endDuration,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.events,
  });

  OrganizedCalendarTimeIntervalsData.empty()
      : startDuration = DateTime.now(),
        endDuration = DateTime.now(),
        right = 0,
        left = 0,
        events = const [],
        top = 0,
        bottom = 0;

  OrganizedCalendarTimeIntervalsData<T> getWithUpdatedRight(double right) =>
      OrganizedCalendarTimeIntervalsData<T>(
        top: top,
        bottom: bottom,
        endDuration: endDuration,
        events: events,
        left: left,
        right: right,
        startDuration: startDuration,
      );
}
