import 'package:flutter/material.dart';
import '../typedefs.dart';

class DefaultLeftSideHourIndicatorMark extends StatelessWidget {
  /// Defines time to display
  final DateTime date;

  /// StringProvider for time string
  final DateTimeStringProvider? leftSideHourIndicatorTimeStringBuilder;

  /// Text style for time string.
  final TextStyle? markingStyle;

  /// Time marker for timeline used in week and day view.
  const DefaultLeftSideHourIndicatorMark({
    Key? key,
    required this.date,
    this.markingStyle,
    this.leftSideHourIndicatorTimeStringBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    // final hour = ((date.hour - 1) % 12) + 1;
    // final timeString = (timeStringBuilder != null)
    //     ? timeStringBuilder!(date)
    //     : date.minute != 0
    //         ? "$hour:${date.minute}"
    //         : "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}";
    final timeString = (leftSideHourIndicatorTimeStringBuilder != null)
        ? leftSideHourIndicatorTimeStringBuilder!(date, locale)
        : date.toString().substring(11, 16);
    return Transform.translate(
      offset: Offset(0, -7.5),
      child: Padding(
        padding: const EdgeInsets.only(right: 7.0),
        child: Text(
          timeString,
          textAlign: TextAlign.right,
          style: markingStyle ??
              TextStyle(
                fontSize: 15.0,
              ),
        ),
      ),
    );
  }
}
