import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

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
