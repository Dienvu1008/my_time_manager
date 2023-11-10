import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';

typedef EventTileBuilder<T extends Object?> = Widget Function(
  DateTime date,
  List<TimeInterval> events,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
);

typedef FullDayEventBuilder<T> = Widget Function(
    List<TimeInterval> events, DateTime date);

typedef CellBuilder<T extends Object?> = Widget Function(
  DateTime date,
  //List<CalendarEventData<T>> event,
  List<TimeInterval> event,
  bool isToday,
  bool isInMonth,
);

typedef WeekDayBuilder = Widget Function(
  int day,
);

typedef DateWidgetBuilder = Widget Function(
  DateTime date,
);

typedef WeekPageHeaderBuilder = Widget Function(
    DateTime startDate, DateTime endDate);

typedef DetectorBuilder<T extends Object?> = Widget Function({
  required DateTime date,
  required double height,
  required double width,
  required double heightPerMinute,
  required MinuteSlotSize minuteSlotSize,
});

typedef TimeIntervalTileBuilder<T extends Object?> = Widget Function(
  DateTime date,
  //List<CalendarEventData<T>> events,
  List<TimeInterval> timeIntervals,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
);


/// Defines different minute slot sizes.
enum MinuteSlotSize {
  /// Slot size: 15 minutes
  minutes15,

  /// Slot size: 30 minutes
  minutes30,

  /// Slot size: 60 minutes
  minutes60,
}

typedef StringProvider = String Function(DateTime date,
    {DateTime? secondaryDate});




typedef CalendarPageChangeCallBack = void Function(DateTime date, int page);


enum LineStyle {
  /// Solid line
  solid,

  /// Dashed line
  dashed,
}

typedef EventFilter<T extends Object?> = List<TimeInterval> Function(
    DateTime date, List<TimeInterval> events);

typedef WeekNumberBuilder = Widget? Function(
  DateTime firstDayOfWeek,
);
typedef CellTapCallback<T extends Object?> = void Function(
    List<TimeInterval> events, DateTime date);

enum WeekDays {
  /// Monday: 0
  monday,

  /// Tuesday: 1
  tuesday,

  /// Wednesday: 2
  wednesday,

  /// Thursday: 3
  thursday,

  /// Friday: 4
  friday,

  /// Saturday: 5
  saturday,

  /// Sunday: 6
  sunday,
}

typedef DatePressCallback = void Function(DateTime date);
typedef DateTapCallback = void Function(DateTime date);



typedef TileTapCallback<T extends Object?> = void Function(
    TimeInterval event, DateTime date);
