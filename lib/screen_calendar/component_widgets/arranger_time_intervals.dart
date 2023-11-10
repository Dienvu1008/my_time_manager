import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/organized_calendar_time_intervals_data.dart';

abstract class TimeIntervalsArranger<T extends Object?> {
  /// [TimeIntervalsArranger] defines how simultaneous time intervals items will be arranged.
  /// Implement [arrange] method to define how time intervals items will be arranged.
  ///
  /// There are three predefined class that implements of [TimeIntervalsArranger].
  ///
  /// [_StackEventArranger], [SideEventArranger] and [MergeEventArranger].
  ///
  const TimeIntervalsArranger();

  /// This method will arrange all the time intervals in and return List of
  /// [OrganizedCalendarTimeIntervalsData].
  ///
  List<OrganizedCalendarTimeIntervalsData<T>> arrange({
    required List<TimeInterval> timeIntervals,
    required double height,
    required double width,
    required double heightPerMinute,
  });
}