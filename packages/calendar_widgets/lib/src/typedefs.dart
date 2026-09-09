import 'package:flutter/material.dart';

import '../calendar_widgets.dart';
import 'calendar_time_interval_data.dart';

typedef CellBuilder<T extends Object?> = Widget Function(
  DateTime date,
  List<CalendarTimeIntervalData<T>> timeInterval,
  bool isToday,
  bool isInMonth,
);

typedef TimeIntervalTileBuilder<T extends Object?> = Widget Function(
  DateTime date,
  List<CalendarTimeIntervalData<T>> timeIntervals,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
);

typedef DetectorBuilder<T extends Object?> = Widget Function({
  required DateTime date,
  required double height,
  required double width,
  required double heightPerMinute,
  required MinuteSlotSize minuteSlotSize,
});

typedef WeekDayBuilder = Widget Function(
  int day,
);

typedef DateWidgetBuilder = Widget Function(DateTime date);

typedef HeaderTitleCallback = Future<void> Function(DateTime date);

typedef WeekNumberBuilder = Widget? Function(
  DateTime firstDayOfWeek,
);

typedef FullDayTimeIntervalBuilder<T> = Widget Function(
    List<CalendarTimeIntervalData<T>> timeIntervals, DateTime date);

typedef CalendarPageChangeCallBack = void Function(DateTime date, int page);

typedef PageChangeCallback = void Function(
  DateTime date,
  CalendarTimeIntervalData event,
);

typedef DateTimeStringProvider = String Function(DateTime date, Locale locale,
    {DateTime? secondaryDate});

typedef WeekPageHeaderBuilder = Widget Function(
  DateTime startDate,
  DateTime endDate,
);

typedef TileTapCallback<T extends Object?> = void Function(
    CalendarTimeIntervalData<T> timeInterval, DateTime date);

typedef CellTapCallback<T extends Object?> = void Function(
    List<CalendarTimeIntervalData<T>> timeIntervals, DateTime date);

typedef DatePressCallback = void Function(DateTime date);

typedef DateTapCallback = void Function(DateTime date);

typedef TimeIntervalFilter<T extends Object?> = List<CalendarTimeIntervalData<T>> Function(
    DateTime date, List<CalendarTimeIntervalData<T>> timeIntervals);

typedef CustomHourLinePainter = CustomPainter Function(
  Color lineColor,
  double lineHeight,
  double offset,
  double minuteHeight,
  bool showVerticalLine,
  double verticalLineOffset,
  LineStyle lineStyle,
  double dashWidth,
  double dashSpaceWidth,
  double emulateVerticalOffsetBy,
);

typedef TestPredicate<T> = bool Function(T element);
