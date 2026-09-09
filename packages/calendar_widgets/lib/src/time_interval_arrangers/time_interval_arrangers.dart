import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import '../calendar_time_interval_data.dart';
import '../constants.dart';
import '../extensions.dart';

part 'merge_time_interval_arranger.dart';

part 'side_time_interval_arranger.dart';

/// {@template event_arranger_arrange_method_doc}
/// This method will arrange all the events in and return List of
/// [OrganizedCalendarTimeIntervalData].
///
/// {@endtemplate}

abstract class TimeIntervalArranger<T extends Object?> {
  /// [TimeIntervalArranger] defines how simultaneous events will be arranged.
  /// Implement [arrange] method to define how events will be arranged.
  ///
  /// There are three predefined class that implements of [TimeIntervalArranger].
  ///
  /// [_StackEventArranger], [SideTimeIntervalArranger] and [MergeTimeIntervalArranger].
  ///
  const TimeIntervalArranger();

  /// {@macro event_arranger_arrange_method_doc}
  List<OrganizedCalendarTimeIntervalData<T>> arrange({
    required List<CalendarTimeIntervalData<T>> timeIntervals,
    required double height,
    required double width,
    required double heightPerMinute,
  });
}

/// Provides event data with its [left], [right], [top], and [bottom] boundary.
class OrganizedCalendarTimeIntervalData<T extends Object?> {
  /// Top position from where event tile will start.
  final double top;

  /// End position from where event tile will end.
  final double bottom;

  /// Left position from where event tile will start.
  final double left;

  /// Right position where event tile will end.
  final double right;

  /// List of events to display in given tile.
  final List<CalendarTimeIntervalData<T>> timeIntervals;

  /// Start duration of event/event list.
  final DateTime startDuration;

  /// End duration of event/event list.
  final DateTime endDuration;

  /// Provides event data with its [left], [right], [top], and [bottom]
  /// boundary.
  OrganizedCalendarTimeIntervalData({
    required this.startDuration,
    required this.endDuration,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.timeIntervals,
  });

  OrganizedCalendarTimeIntervalData.empty()
      : startDuration = DateTime.now(),
        endDuration = DateTime.now(),
        right = 0,
        left = 0,
        timeIntervals = const [],
        top = 0,
        bottom = 0;

  OrganizedCalendarTimeIntervalData<T> getWithUpdatedRight(double right) =>
      OrganizedCalendarTimeIntervalData<T>(
        top: top,
        bottom: bottom,
        endDuration: endDuration,
        timeIntervals: timeIntervals,
        left: left,
        right: right,
        startDuration: startDuration,
      );
}
