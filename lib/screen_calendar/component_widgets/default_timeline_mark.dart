import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

class DefaultTimeLineMark extends StatelessWidget {
  /// Defines time to display
  final DateTime date;

  /// StringProvider for time string
  final StringProvider? timeStringBuilder;

  /// Text style for time string.
  final TextStyle? markingStyle;

  /// Time marker for timeline used in week and day view.
  const DefaultTimeLineMark({
    Key? key,
    required this.date,
    this.markingStyle,
    this.timeStringBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final hour = ((date.hour - 1) % 12) + 1;
    // final timeString = (timeStringBuilder != null)
    //     ? timeStringBuilder!(date)
    //     : date.minute != 0
    //         ? "$hour:${date.minute}"
    //         : "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}";

    final timeString = (timeStringBuilder != null)
    ? timeStringBuilder!(date)
    : "${date.toString().substring(11, 16)}";

    return Transform.translate(
      offset: Offset(0, -7.5),
      child: Padding(
        padding: const EdgeInsets.only(right: 7.0),
        child: Text(
          timeString,
          textAlign: TextAlign.right,
          style: markingStyle ??
              TextStyle(
                fontSize: 10.0,
              ),
        ),
      ),
    );
  }
}
 