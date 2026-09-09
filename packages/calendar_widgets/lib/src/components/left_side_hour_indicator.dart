import 'package:flutter/material.dart';

import '../constants.dart';
import '../typedefs.dart';

/// Left side hour indicator to display time at left side of day or week view.
class LeftSideHourIndicator extends StatelessWidget {
  /// Width of left side hour indicator
  final double leftSideHourIndicatorWidth;

  /// Height for one hour.
  final double hourHeight;

  /// Total height of left side hour indicator.
  final double height;

  /// Offset for left side hour indicator
  final double leftSideHourIndicatorOffset;

  /// This will display time string in left side hour indicator.
  final DateWidgetBuilder displayTimeStringBuilder;

  /// Flag to display half hours.
  final bool showHalfHours;

  /// Flag to display quarter hours.
  final bool showQuarterHours;

  static DateTime get _date => DateTime.now();

  double get _halfHourHeight => hourHeight / 2;

  /// Left side hour indicator to display time at left side of day or week view.
  const LeftSideHourIndicator({
    Key? key,
    required this.leftSideHourIndicatorWidth,
    required this.hourHeight,
    required this.height,
    required this.leftSideHourIndicatorOffset,
    required this.displayTimeStringBuilder,
    this.showHalfHours = false,
    this.showQuarterHours = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: ValueKey(hourHeight),
      constraints: BoxConstraints(
        maxWidth: leftSideHourIndicatorWidth,
        minWidth: leftSideHourIndicatorWidth,
        maxHeight: height,
        minHeight: height,
      ),
      child: Stack(
        children: [
          for (int i = 1; i < Constants.hoursADay; i++)
            _leftSideHourIndicatorPositioned(
              topPosition: hourHeight * i - leftSideHourIndicatorOffset,
              bottomPosition: height - (hourHeight * (i + 1)) + leftSideHourIndicatorOffset,
              hour: i,
            ),
          if (showHalfHours)
            for (int i = 0; i < Constants.hoursADay; i++)
              _leftSideHourIndicatorPositioned(
                topPosition: hourHeight * i - leftSideHourIndicatorOffset + _halfHourHeight,
                bottomPosition:
                    height - (hourHeight * (i + 1)) + leftSideHourIndicatorOffset,
                hour: i,
                minutes: 30,
              ),
          if (showQuarterHours)
            for (int i = 0; i < Constants.hoursADay; i++) ...[
              /// this is for 15 minutes
              _leftSideHourIndicatorPositioned(
                topPosition:
                    hourHeight * i - leftSideHourIndicatorOffset + hourHeight * 0.25,
                bottomPosition:
                    height - (hourHeight * (i + 1)) + leftSideHourIndicatorOffset,
                hour: i,
                minutes: 15,
              ),

              /// this is for 45 minutes
              _leftSideHourIndicatorPositioned(
                topPosition:
                    hourHeight * i - leftSideHourIndicatorOffset + hourHeight * 0.75,
                bottomPosition:
                    height - (hourHeight * (i + 1)) + leftSideHourIndicatorOffset,
                hour: i,
                minutes: 45,
              ),
            ],
        ],
      ),
    );
  }

  Widget _leftSideHourIndicatorPositioned({
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
        width: leftSideHourIndicatorWidth,
        child: displayTimeStringBuilder.call(
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
