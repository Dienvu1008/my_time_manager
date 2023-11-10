import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/utils/constants.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

/// Time line to display time at left side of day or week view.
class TimeLine extends StatelessWidget {
  /// Width of timeline
  final double timeLineWidth;

  /// Height for one hour.
  final double hourHeight;

  /// Total height of timeline.
  final double height;

  /// Offset for time line
  final double timeLineOffset;

  /// This will display time string in timeline.
  final DateWidgetBuilder timeLineBuilder;

  /// Flag to display half hours.
  final bool showHalfHours;

  static DateTime get _date => DateTime.now();

  double get _halfHourHeight => hourHeight / 2;

  /// Time line to display time at left side of day or week view.
  const TimeLine({
    Key? key,
    required this.timeLineWidth,
    required this.hourHeight,
    required this.height,
    required this.timeLineOffset,
    required this.timeLineBuilder,
    this.showHalfHours = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: ValueKey(hourHeight),
      constraints: BoxConstraints(
        maxWidth: timeLineWidth,
        minWidth: timeLineWidth,
        maxHeight: height,
        minHeight: height,
      ),
      child: Stack(
        children: [
          for (int i = 1; i < Constants.hoursADay; i++)
            _timelinePositioned(
              topPosition: hourHeight * i - timeLineOffset,
              bottomPosition: height - (hourHeight * (i + 1)) + timeLineOffset,
              hour: i,
            ),
          if (showHalfHours)
            for (int i = 0; i < Constants.hoursADay; i++)
              _timelinePositioned(
                topPosition: hourHeight * i - timeLineOffset + _halfHourHeight,
                bottomPosition:
                    height - (hourHeight * (i + 1)) + timeLineOffset,
                hour: i,
                minutes: 30,
              ),
        ],
      ),
    );
  }

  Widget _timelinePositioned({
    required double topPosition,
    required double bottomPosition,
    required int hour,
    int minutes = 0,
  }) {
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      bottom: bottomPosition,
      child: Container(
        height: hourHeight,
        width: timeLineWidth,
        child: timeLineBuilder.call(
          DateTime(
            _date.year,
            _date.month,
            _date.day,
            hour,
            minutes,
          ),
        ),
      ),
    );
  }
}
