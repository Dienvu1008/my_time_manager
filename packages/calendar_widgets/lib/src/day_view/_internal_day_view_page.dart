import 'package:flutter/material.dart';

import '../components/current_time_indicator.dart';
import '../components/display_time_interval_tile.dart';
import '../components/left_side_hour_indicator.dart';
import '../components/time_interval_scroll_notifier.dart';
import '../enumerations.dart';
import '../modals.dart';
import '../painters.dart';
import '../time_interval_arrangers/time_interval_arrangers.dart';
import '../time_interval_controller.dart';
import '../typedefs.dart';

/// Defines a single day page.
class InternalDayViewPage<T extends Object?> extends StatelessWidget {
  /// Width of the page
  final double width;

  /// Height of the page.
  final double height;

  /// Date for which we are displaying page.
  final DateTime date;

  /// A builder that returns a widget to show event on screen.
  final TimeIntervalTileBuilder<T> timeIntervalTileBuilder;

  /// Controller for calendar
  final TimeIntervalController<T> controller;

  /// A builder that builds time line.
  final DateWidgetBuilder leftSideHourIndicatorBuilder;

  /// Builds custom PressDetector widget
  final DetectorBuilder dayDetectorBuilder;

  /// Settings for hour indicator lines.
  final HourIndicatorSettings hourIndicatorSettings;

  /// Custom painter for hour line.
  final CustomHourLinePainter hourLinePainter;

  /// Flag to display live time indicator.
  /// If true then indicator will be displayed else not.
  final bool showLiveLine;

  /// Settings for live time indicator.
  final HourIndicatorSettings liveTimeIndicatorSettings;

  /// Height occupied by one minute of time span.
  final double heightPerMinute;

  /// Width of time line.
  final double leftSideHourIndicatorWidth;

  /// Offset for time line widgets.
  final double leftSideHourIndicatorOffset;

  /// Height occupied by one hour of time span.
  final double hourHeight;

  /// event arranger to arrange events.
  final TimeIntervalArranger<T> timeIntervalArranger;

  /// Flag to display vertical line.
  final bool showVerticalLine;

  /// Offset  of vertical line.
  final double verticalLineOffset;

  /// Called when user taps on event tile.
  final CellTapCallback<T>? onTileTap;

  /// Called when user long press on calendar.
  final DatePressCallback? onDateLongPress;

  /// Called when user taps on day view page.
  ///
  /// This callback will have a date parameter which
  /// will provide the time span on which user has tapped.
  ///
  /// Ex, User Taps on Date page with date 11/01/2022 and time span is 1PM to 2PM.
  /// then DateTime object will be  DateTime(2022,01,11,1,0)
  final DateTapCallback? onDateTap;

  /// Defines size of the slots that provides long press callback on area
  /// where events are not there.
  final MinuteSlotSize minuteSlotSize;

  /// Notifies if there is any event that needs to be visible instantly.
  final TimeIntervalScrollConfiguration scrollNotifier;

  /// Display full day events.
  final FullDayTimeIntervalBuilder<T> fullDayEventBuilder;

  /// Flag to display half hours.
  final bool showHalfHours;

  /// Flag to display quarter hours.
  final bool showQuarterHours;

  /// Settings for half hour indicator lines.
  final HourIndicatorSettings halfHourIndicatorSettings;

  /// Settings for half hour indicator lines.
  final HourIndicatorSettings quarterHourIndicatorSettings;

  final ScrollController scrollController;

  /// Emulate vertical line offset from hour line starts.
  final double emulateVerticalOffsetBy;

  /// Defines a single day page.
  const InternalDayViewPage({
    Key? key,
    required this.showVerticalLine,
    required this.width,
    required this.date,
    required this.timeIntervalTileBuilder,
    required this.controller,
    required this.leftSideHourIndicatorBuilder,
    required this.hourIndicatorSettings,
    required this.hourLinePainter,
    required this.showLiveLine,
    required this.liveTimeIndicatorSettings,
    required this.heightPerMinute,
    required this.leftSideHourIndicatorWidth,
    required this.leftSideHourIndicatorOffset,
    required this.height,
    required this.hourHeight,
    required this.timeIntervalArranger,
    required this.verticalLineOffset,
    required this.onTileTap,
    required this.onDateLongPress,
    required this.onDateTap,
    required this.minuteSlotSize,
    required this.scrollNotifier,
    required this.fullDayEventBuilder,
    required this.scrollController,
    required this.dayDetectorBuilder,
    required this.showHalfHours,
    required this.showQuarterHours,
    required this.halfHourIndicatorSettings,
    required this.quarterHourIndicatorSettings,
    required this.emulateVerticalOffsetBy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullDayEventList = controller.getFullDayEvent(date);
    return Container(
      height: height,
      width: width,
      child: Column(
        children: [
          fullDayEventList.isEmpty
              ? SizedBox.shrink()
              : fullDayEventBuilder(fullDayEventList, date),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                height: height,
                width: width,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(width, height),
                      painter: hourLinePainter(
                        hourIndicatorSettings.color,
                        hourIndicatorSettings.height,
                        leftSideHourIndicatorWidth + hourIndicatorSettings.offset,
                        heightPerMinute,
                        showVerticalLine,
                        verticalLineOffset,
                        hourIndicatorSettings.lineStyle,
                        hourIndicatorSettings.dashWidth,
                        hourIndicatorSettings.dashSpaceWidth,
                        emulateVerticalOffsetBy,
                      ),
                    ),
                    if (showHalfHours)
                      CustomPaint(
                        size: Size(width, height),
                        painter: HalfHourLinePainter(
                          lineColor: halfHourIndicatorSettings.color,
                          lineHeight: halfHourIndicatorSettings.height,
                          offset:
                              leftSideHourIndicatorWidth + halfHourIndicatorSettings.offset,
                          minuteHeight: heightPerMinute,
                          lineStyle: halfHourIndicatorSettings.lineStyle,
                          dashWidth: halfHourIndicatorSettings.dashWidth,
                          dashSpaceWidth:
                              halfHourIndicatorSettings.dashSpaceWidth,
                        ),
                      ),
                    if (showQuarterHours)
                      CustomPaint(
                        size: Size(width, height),
                        painter: QuarterHourLinePainter(
                          lineColor: quarterHourIndicatorSettings.color,
                          lineHeight: quarterHourIndicatorSettings.height,
                          offset: leftSideHourIndicatorWidth +
                              quarterHourIndicatorSettings.offset,
                          minuteHeight: heightPerMinute,
                          lineStyle: quarterHourIndicatorSettings.lineStyle,
                          dashWidth: quarterHourIndicatorSettings.dashWidth,
                          dashSpaceWidth:
                              quarterHourIndicatorSettings.dashSpaceWidth,
                        ),
                      ),
                    dayDetectorBuilder(
                      width: width,
                      height: height,
                      heightPerMinute: heightPerMinute,
                      date: date,
                      minuteSlotSize: minuteSlotSize,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: DisplayTimeIntervalTile<T>(
                        height: height,
                        date: date,
                        onTileTap: onTileTap,
                        timeIntervalArranger: timeIntervalArranger,
                        timeIntervals: controller.getEventsOnDay(
                          date,
                          includeFullDayEvents: false,
                        ),
                        heightPerMinute: heightPerMinute,
                        eventTileBuilder: timeIntervalTileBuilder,
                        scrollNotifier: scrollNotifier,
                        width: width -
                            leftSideHourIndicatorWidth -
                            hourIndicatorSettings.offset -
                            verticalLineOffset,
                      ),
                    ),
                    LeftSideHourIndicator(
                      height: height,
                      hourHeight: hourHeight,
                      displayTimeStringBuilder: leftSideHourIndicatorBuilder,
                      leftSideHourIndicatorOffset: leftSideHourIndicatorOffset,
                      leftSideHourIndicatorWidth: leftSideHourIndicatorWidth,
                      showHalfHours: showHalfHours,
                      showQuarterHours: showQuarterHours,
                      key: ValueKey(heightPerMinute),
                    ),
                    if (showLiveLine && liveTimeIndicatorSettings.height > 0)
                      IgnorePointer(
                        child: CurrentTimeIndicator(
                          currentTimeIndicatorSettings: liveTimeIndicatorSettings,
                          width: width,
                          height: height,
                          heightPerMinute: heightPerMinute,
                          leftSideHourIndicatorWidth: leftSideHourIndicatorWidth,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
