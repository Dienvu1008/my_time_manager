import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'dart:convert';

import '../database/database_manager.dart';

//part 'models.g.dart';






class Event extends Equatable {
  String id;
  final String taskListId;
  final String title;
  final String description;
  final String location;
  final Color color;
  final DateTime startTimeStamp;
  final DateTime endTimeStamp;
  final List<String> tags;
  final List<String> dataFiles;
  final DateTime updateTimeStamp;

  Event({
    String? id,
    required this.taskListId,
    required this.title,
    String? description,
    String? location,
    Color? color,
    required this.startTimeStamp,
    required this.endTimeStamp,
    List<String>? tags,
    List<String>? dataFiles,
    DateTime? updateTimeStamp,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.white,
        tags = tags ?? [],
        dataFiles = dataFiles ?? [],
        updateTimeStamp = updateTimeStamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'description': description,
      'location': location,
      'color': color.value,
      'startTimeStamp': startTimeStamp.millisecondsSinceEpoch, // INTEGER
      'endTimeStamp': endTimeStamp.millisecondsSinceEpoch, // INTEGER
      'tags': jsonEncode(tags),
      'dataFiles': jsonEncode(dataFiles),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      taskListId: map['taskListId'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      color: Color(map['color']),
      startTimeStamp:
          DateTime.fromMillisecondsSinceEpoch(map['startTimeStamp']),
      endTimeStamp: DateTime.fromMillisecondsSinceEpoch(map['endTimeStamp']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      dataFiles: List<String>.from(jsonDecode(map['dataFiles'])),
      updateTimeStamp: DateTime.parse(map['updateTimeStamp']),
    );
  }

  String toJson() => json.encode(toMap());
  factory Event.fromJson(String source) => Event.fromMap(json.decode(source));
  // Implement toString to make it easier to see information about
  // each task when using the print statement.

  @override
  String toString() {
    return '''Task(
      id: $id, 
      title: $title, 
      description: $description, 
      color: $color, 
      taskListId: $taskListId)''';
  }

  @override
  List<Object?> get props => [id, taskListId, title, description];
}

class FocusInterval {
  final DateTime startTimeStamp;
  final DateTime endTimeStamp;

  FocusInterval({required this.startTimeStamp, required this.endTimeStamp});

  Map<String, dynamic> toMap() {
    return {
      'startTimeStamp': startTimeStamp.millisecondsSinceEpoch, // INTEGER
      'endTimeStamp': endTimeStamp.millisecondsSinceEpoch, // INTEGER
    };
  }

  factory FocusInterval.fromMap(Map<String, dynamic> map) {
    return FocusInterval(
      startTimeStamp:
          DateTime.fromMillisecondsSinceEpoch(map['startTimeStamp']),
      endTimeStamp: DateTime.fromMillisecondsSinceEpoch(map['endTimeStamp']),
    );
  }
}

class FocusIntervalsStats {
  String? id;
  String? taskId;
  String? measurableTaskId;
  String? taskWithSubtasksId;
  List<FocusInterval> focusIntervals;

  FocusIntervalsStats({
    String? id,
    String? taskId,
    String? measurableTaskId,
    String? taskWithSubtasksId,
    List<FocusInterval>? focusIntervals,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4(),
        taskId = taskId ?? '',
        taskWithSubtasksId = taskWithSubtasksId ?? '',
        measurableTaskId = measurableTaskId ?? '',
        focusIntervals = focusIntervals ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'taskWithSubtasksId': taskWithSubtasksId,
      'measurableTaskId': measurableTaskId,
      'focusIntervals': jsonEncode(focusIntervals!
          .map((focusInterval) => focusInterval.toMap())
          .toList()),
    };
  }

  factory FocusIntervalsStats.fromMap(Map<String, dynamic> map) {
    return FocusIntervalsStats(
        id: map['id'],
        taskId: map['taskId'],
        taskWithSubtasksId: map['taskWithSubtasksId'],
        measurableTaskId: map['measurableTaskId'],
        focusIntervals: List<FocusInterval>.from(
            jsonDecode(map['focusIntervals']).map((focusIntervalMap) =>
                FocusInterval.fromMap(focusIntervalMap))));
  }
}

/// The type definition for a JSON-serializable [Map].
typedef JsonMap = Map<String, dynamic>;

typedef TimeIntervalTileBuilder<T extends Object?> = Widget Function(
  DateTime date,
  //List<CalendarEventData<T>> events,
  List<TimeInterval> timeIntervals,
  Rect boundary,
  DateTime startDuration,
  DateTime endDuration,
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

abstract class EventArranger<T extends Object?> {
  /// [EventArranger] defines how simultaneous events will be arranged.
  /// Implement [arrange] method to define how events will be arranged.
  ///
  /// There are three predefined class that implements of [EventArranger].
  ///
  /// [_StackEventArranger], [SideEventArranger] and [MergeEventArranger].
  ///
  const EventArranger();

  /// This method will arrange all the events in and return List of
  /// [OrganizedCalendarEventData].
  ///
  List<OrganizedCalendarEventData<T>> arrange({
    //required List<CalendarEventData<T>> events,
    required List<TimeInterval> events,
    required double height,
    required double width,
    required double heightPerMinute,
  });
}

class OrganizedCalendarEventData<T extends Object?> {
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
  OrganizedCalendarEventData({
    required this.startDuration,
    required this.endDuration,
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.events,
  });

  OrganizedCalendarEventData.empty()
      : startDuration = DateTime.now(),
        endDuration = DateTime.now(),
        right = 0,
        left = 0,
        events = const [],
        top = 0,
        bottom = 0;

  OrganizedCalendarEventData<T> getWithUpdatedRight(double right) =>
      OrganizedCalendarEventData<T>(
        top: top,
        bottom: bottom,
        endDuration: endDuration,
        events: events,
        left: left,
        right: right,
        startDuration: startDuration,
      );
}

typedef CalendarPageChangeCallBack = void Function(DateTime date, int page);

class HourIndicatorSettings {
  final double height;
  final Color color;
  final double offset;
  final LineStyle lineStyle;
  final double dashWidth;
  final double dashSpaceWidth;

  /// Settings for hour lines
  const HourIndicatorSettings({
    this.height = 1.0,
    this.offset = 0.0,
    this.color = const Color.fromARGB(255, 158, 158, 158),
    this.lineStyle = LineStyle.solid,
    this.dashWidth = 4,
    this.dashSpaceWidth = 4,
  }) : assert(height >= 0, "Height must be greater than or equal to 0.");

  factory HourIndicatorSettings.none() => const HourIndicatorSettings(
        //color: Colors.transparent,
        height: 0.0,
      );
}

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

class HeaderStyle {
  /// Provide text style for calendar's header.
  final TextStyle? headerTextStyle;

  /// Widget used for left icon.
  ///
  /// Tapping on it will navigate to previous calendar page.
  final Widget? leftIcon;

  /// Widget used for right icon.
  ///
  /// Tapping on it will navigate to next calendar page.
  final Widget? rightIcon;

  /// Determines left icon visibility.
  final bool leftIconVisible;

  /// Determines right icon visibility.
  final bool rightIconVisible;

  /// Internal padding of the whole header.
  final EdgeInsets headerPadding;

  /// External margin of the whole header.
  final EdgeInsets headerMargin;

  /// Internal padding of left icon.
  final EdgeInsets leftIconPadding;

  /// Internal padding of right icon.
  final EdgeInsets rightIconPadding;

  /// Define Alignment of header text.
  final TextAlign titleAlign;

  /// Decoration of whole header.
  final BoxDecoration? decoration;

  /// Create a `HeaderStyle` of calendar view
  const HeaderStyle({
    this.headerTextStyle,
    this.leftIcon,
    this.rightIcon,
    this.leftIconVisible = true,
    this.rightIconVisible = true,
    this.headerMargin = EdgeInsets.zero,
    this.headerPadding = EdgeInsets.zero,
    this.leftIconPadding = const EdgeInsets.all(10),
    this.rightIconPadding = const EdgeInsets.all(10),
    this.titleAlign = TextAlign.center,
    this.decoration,
  });
}

typedef FullDayEventBuilder<T> = Widget Function(
    List<TimeInterval> events, DateTime date);

extension DateTimeExtensions on DateTime {
  /// Compares only [day], [month] and [year] of [DateTime].
  bool compareWithoutTime(DateTime date) {
    return day == date.day && month == date.month && year == date.year;
  }

  /// Gets difference of months between [date] and calling object.
  int getMonthDifference(DateTime date) {
    if (year == date.year) return ((date.month - month).abs() + 1);

    var months = ((date.year - year).abs() - 1) * 12;

    if (date.year >= year) {
      months += date.month + (13 - month);
    } else {
      months += month + (13 - date.month);
    }

    return months;
  }

  /// Gets difference of days between [date] and calling object.
  int getDayDifference(DateTime date) => DateTime.utc(year, month, day)
      .difference(DateTime.utc(date.year, date.month, date.day))
      .inDays
      .abs();

  /// Gets difference of weeks between [date] and calling object.
  int getWeekDifference(DateTime date, {WeekDays start = WeekDays.monday}) =>
      (firstDayOfWeek(start: start)
                  .difference(date.firstDayOfWeek(start: start))
                  .inDays
                  .abs() /
              7)
          .ceil();

  /// Returns The List of date of Current Week, all of the dates will be without
  /// time.
  /// Day will start from Monday to Sunday.
  ///
  /// ex: if Current Date instance is 8th and day is wednesday then weekDates
  /// will return dates
  /// [6,7,8,9,10,11,12]
  /// Where on 6th there will be monday and on 12th there will be Sunday
  List<DateTime> datesOfWeek({WeekDays start = WeekDays.monday}) {
    // Here %7 ensure that we do not subtract >6 and <0 days.
    // Initial formula is,
    //    difference = (weekday - startInt)%7
    // where weekday and startInt ranges from 1 to 7.
    // But in WeekDays enum index ranges from 0 to 6 so we are
    // adding 1 in index. So, new formula with WeekDays is,
    //    difference = (weekdays - (start.index + 1))%7
    //
    final startDay =
        DateTime(year, month, day - (weekday - start.index - 1) % 7);

    return [
      startDay,
      DateTime(startDay.year, startDay.month, startDay.day + 1),
      DateTime(startDay.year, startDay.month, startDay.day + 2),
      DateTime(startDay.year, startDay.month, startDay.day + 3),
      DateTime(startDay.year, startDay.month, startDay.day + 4),
      DateTime(startDay.year, startDay.month, startDay.day + 5),
      DateTime(startDay.year, startDay.month, startDay.day + 6),
    ];
  }

  /// Returns the first date of week containing the current date
  DateTime firstDayOfWeek({WeekDays start = WeekDays.monday}) =>
      DateTime(year, month, day - ((weekday - start.index - 1) % 7));

  /// Returns the last date of week containing the current date
  DateTime lastDayOfWeek({WeekDays start = WeekDays.monday}) =>
      DateTime(year, month, day + (6 - (weekday - start.index - 1) % 7));

  /// Returns list of all dates of [month].
  /// All the dates are week based that means it will return array of size 42
  /// which will contain 6 weeks that is the maximum number of weeks a month
  /// can have.
  List<DateTime> datesOfMonths({WeekDays startDay = WeekDays.monday}) {
    final monthDays = <DateTime>[];
    for (var i = 1, start = 1; i < 7; i++, start += 7) {
      monthDays
          .addAll(DateTime(year, month, start).datesOfWeek(start: startDay));
    }
    return monthDays;
  }

  /// Gives formatted date in form of 'month - year'.
  String get formatted => "$month-$year";

  /// Returns total minutes this date is pointing at.
  /// if [DateTime] object is, DateTime(2021, 5, 13, 12, 4, 5)
  /// Then this getter will return 12*60 + 4 which evaluates to 724.
  int get getTotalMinutes => hour * 60 + minute;

  /// Returns a new [DateTime] object with hour and minutes calculated from
  /// [totalMinutes].
  DateTime copyFromMinutes([int totalMinutes = 0]) => DateTime(
        year,
        month,
        day,
        totalMinutes ~/ 60,
        totalMinutes % 60,
      );

  /// Returns [DateTime] without timestamp.
  DateTime get withoutTime => DateTime(year, month, day);

  /// Compares time of two [DateTime] objects.
  bool hasSameTimeAs(DateTime other) {
    return other.hour == hour &&
        other.minute == minute &&
        other.second == second &&
        other.millisecond == millisecond &&
        other.microsecond == microsecond;
  }

  bool get isDayStart => hour % 24 == 0 && minute % 60 == 0;

  @Deprecated(
      "This extension is not being used in this package and will be removed "
      "in next major release. Please use withoutTime instead.")
  DateTime get dateYMD => DateTime(year, month, day);
}

typedef TileTapCallback<T extends Object?> = void Function(
    TimeInterval event, DateTime date);
