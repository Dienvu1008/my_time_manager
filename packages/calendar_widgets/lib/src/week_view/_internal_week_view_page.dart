import 'package:flutter/material.dart';

import '../components/display_time_interval_tile.dart';
import '../components/left_side_hour_indicator.dart';
import '../components/time_interval_scroll_notifier.dart';
import '../enumerations.dart';
import '../modals.dart';
import '../painters.dart';
import '../time_interval_arrangers/time_interval_arrangers.dart';
import '../time_interval_controller.dart';
import '../typedefs.dart';
import 'week_current_time_indicator.dart';

/// A single page for week view.
class InternalWeekViewPage<T extends Object?> extends StatelessWidget {
  /// Width of the page.
  final double width;

  /// Height of the page.
  final double height;

  /// Dates to display on page.
  final List<DateTime> dates;

  /// Builds tile for a single event.
  final TimeIntervalTileBuilder<T> timeIntervalTileBuilder;

  /// A calendar controller that controls all the events and rebuilds widget
  /// if event(s) are added or removed.
  final TimeIntervalController<T> controller;

  /// A builder to build time line.
  final DateWidgetBuilder leftSideHourIndicatorBuilder;

  /// Settings for hour indicator lines.
  final HourIndicatorSettings hourIndicatorSettings;

  /// Custom painter for hour line.
  final CustomHourLinePainter hourLinePainter;

  /// Settings for half hour indicator lines.
  final HourIndicatorSettings halfHourIndicatorSettings;

  /// Settings for quarter hour indicator lines.
  final HourIndicatorSettings quarterHourIndicatorSettings;

  /// Flag to display live line.
  final bool showLiveLine;

  /// Settings for live time indicator.
  final HourIndicatorSettings currentTimeIndicatorSettings;

  ///  Height occupied by one minute time span.
  final double heightPerMinute;

  /// Width of left side hour indicator.
  final double leftSideHourIndicatorWidth;

  /// Offset of left side hour indicator.
  final double leftSideHourIndicatorOffset;

  /// Height occupied by one hour time span.
  final double hourHeight;

  /// Arranger to arrange events.
  final TimeIntervalArranger<T> timeIntervalArranger;

  /// Flag to display vertical line or not.
  final bool showVerticalLine;

  /// Offset for vertical line offset.
  final double verticalLineOffset;

  /// Builder for week day title.
  final DateWidgetBuilder weekDayBuilder;

  /// Builder for week number.
  final WeekNumberBuilder weekNumberBuilder;

  /// Builds custom PressDetector widget
  final DetectorBuilder weekDetectorBuilder;

  /// Height of week title.
  final double weekTitleHeight;

  /// Width of week title.
  final double weekTitleWidth;

  final ScrollController scrollController;

  /// Called when user taps on event tile.
  final CellTapCallback<T>? onTileTap;

  /// Defines which days should be displayed in one week.
  ///
  /// By default all the days will be visible.
  /// Sequence will be monday to sunday.
  final List<WeekDays> weekDays;

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

  final TimeIntervalScrollConfiguration scrollConfiguration;

  /// Display full day events.
  final FullDayTimeIntervalBuilder<T> fullDayTimeIntervalBuilder;

  /// If true this will show week day at bottom position.
  final bool showWeekDayAtBottom;

  /// Flag to display half hours
  final bool showHalfHours;

  /// Flag to display quarter hours
  final bool showQuarterHours;

  /// Emulate vertical line offset from hour line starts.
  final double emulateVerticalOffsetBy;

  /// A single page for week view.
  const InternalWeekViewPage(
      {Key? key,
      required this.showVerticalLine,
      required this.weekTitleHeight,
      required this.weekDayBuilder,
      required this.weekNumberBuilder,
      required this.width,
      required this.dates,
      required this.timeIntervalTileBuilder,
      required this.controller,
      required this.leftSideHourIndicatorBuilder,
      required this.hourIndicatorSettings,
      required this.hourLinePainter,
      required this.halfHourIndicatorSettings,
      required this.quarterHourIndicatorSettings,
      required this.showLiveLine,
      required this.currentTimeIndicatorSettings,
      required this.heightPerMinute,
      required this.leftSideHourIndicatorWidth,
      required this.leftSideHourIndicatorOffset,
      required this.height,
      required this.hourHeight,
      required this.timeIntervalArranger,
      required this.verticalLineOffset,
      required this.weekTitleWidth,
      required this.scrollController,
      required this.onTileTap,
      required this.onDateLongPress,
      required this.onDateTap,
      required this.weekDays,
      required this.minuteSlotSize,
      required this.scrollConfiguration,
      required this.fullDayTimeIntervalBuilder,
      required this.weekDetectorBuilder,
      required this.showWeekDayAtBottom,
      required this.showHalfHours,
      required this.showQuarterHours,
      required this.emulateVerticalOffsetBy})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredDates = _filteredDate();
    return Container(
      height: height + weekTitleHeight,
      width: width,
      child: Column(
        verticalDirection:
            showWeekDayAtBottom ? VerticalDirection.up : VerticalDirection.down,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: weekTitleHeight,
                  width:
                      leftSideHourIndicatorWidth + hourIndicatorSettings.offset,
                  child: weekNumberBuilder.call(filteredDates[0]),
                ),
                ...List.generate(
                  filteredDates.length,
                  (index) => SizedBox(
                    height: weekTitleHeight,
                    width: weekTitleWidth,
                    child: weekDayBuilder(
                      filteredDates[index],
                    ),
                  ),
                )
              ],
            ),
          ),
          Divider(
            thickness: 1,
            height: 1,
          ),
          SizedBox(
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: leftSideHourIndicatorWidth +
                        hourIndicatorSettings.offset),
                ...List.generate(
                  filteredDates.length,
                  (index) {
                    final fullDayEventList =
                        controller.getFullDayEvent(filteredDates[index]);
                    return fullDayEventList.isEmpty
                        ? SizedBox.shrink()
                        : SizedBox(
                            width: weekTitleWidth,
                            child: fullDayTimeIntervalBuilder.call(
                              fullDayEventList,
                              dates[index],
                            ),
                          );
                  },
                )
              ],
            ),
          ),
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
                        leftSideHourIndicatorWidth +
                            hourIndicatorSettings.offset,
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
                          offset: leftSideHourIndicatorWidth +
                              halfHourIndicatorSettings.offset,
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
                    if (showLiveLine &&
                        currentTimeIndicatorSettings.height > 0 &&
                        _todayColumnIndex(filteredDates) != -1)
                      Builder(
                        builder: (context) {
                          final todayIndex = _todayColumnIndex(filteredDates);
                          final columnsStart = leftSideHourIndicatorWidth +
                              hourIndicatorSettings.offset;
                          // Vị trí ngang cột ngày hiện tại + bề rộng một cột ->
                          // đường kẻ chỉ nằm trong đúng ngày hôm nay.
                          final dayStartOffset =
                              columnsStart + todayIndex * weekTitleWidth;
                          return WeekCurrentTimeIndicator(
                            currentTimeIndicatorSettings:
                                currentTimeIndicatorSettings,
                            indicatorWidth: width,
                            height: height,
                            heightPerMinute: heightPerMinute,
                            leftSideHourIndicatorWidth:
                                leftSideHourIndicatorWidth,
                            dayStartOffset: dayStartOffset,
                            dayWidth: weekTitleWidth,
                          );
                        },
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: weekTitleWidth * filteredDates.length,
                        height: height,
                        child: Row(
                          children: [
                            ...List.generate(
                              filteredDates.length,
                              (index) => Container(
                                decoration: showVerticalLine
                                    ? BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: hourIndicatorSettings.color,
                                            width: hourIndicatorSettings.height,
                                          ),
                                        ),
                                      )
                                    : null,
                                height: height,
                                width: weekTitleWidth,
                                child: Stack(
                                  children: [
                                    weekDetectorBuilder(
                                      width: weekTitleWidth,
                                      height: height,
                                      heightPerMinute: heightPerMinute,
                                      date: dates[index],
                                      minuteSlotSize: minuteSlotSize,
                                    ),
                                    DisplayTimeIntervalTile<T>(
                                      height: height,
                                      date: filteredDates[index],
                                      onTileTap: onTileTap,
                                      width: weekTitleWidth,
                                      timeIntervalArranger:
                                          timeIntervalArranger,
                                      eventTileBuilder: timeIntervalTileBuilder,
                                      scrollNotifier: scrollConfiguration,
                                      timeIntervals: controller.getEventsOnDay(
                                        filteredDates[index],
                                        includeFullDayEvents: false,
                                      ),
                                      heightPerMinute: heightPerMinute,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    LeftSideHourIndicator(
                      leftSideHourIndicatorWidth: leftSideHourIndicatorWidth,
                      hourHeight: hourHeight,
                      height: height,
                      leftSideHourIndicatorOffset: leftSideHourIndicatorOffset,
                      displayTimeStringBuilder: leftSideHourIndicatorBuilder,
                      showHalfHours: showHalfHours,
                      showQuarterHours: showQuarterHours,
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

  List<DateTime> _filteredDate() {
    final output = <DateTime>[];

    final weekDays = this.weekDays.toList();

    for (final date in dates) {
      if (weekDays.any((weekDay) => weekDay.index + 1 == date.weekday)) {
        output.add(date);
      }
    }

    return output;
  }

  /// Chỉ số cột (trong [filteredDates]) ứng với NGÀY HÔM NAY, hoặc -1 nếu hôm
  /// nay không nằm trong tuần đang hiển thị. Dùng để vẽ thanh chỉ thời gian
  /// đúng vào cột ngày hiện tại.
  int _todayColumnIndex(List<DateTime> filteredDates) {
    final now = DateTime.now();
    for (var i = 0; i < filteredDates.length; i++) {
      final d = filteredDates[i];
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return i;
      }
    }
    return -1;
  }
}
