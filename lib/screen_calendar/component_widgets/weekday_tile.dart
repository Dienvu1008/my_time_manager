import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/screen_calendar/utils/constants.dart';
import 'package:my_time_manager/utils/utils.dart';

class WeekDayTile extends StatelessWidget {
  /// Index of week day.
  final int dayIndex;

  /// display week day
  final String Function(int)? weekDayStringBuilder;

  /// Background color of single week day tile.
  //final Color backgroundColor;

  /// Should display border or not.
  final bool displayBorder;

  /// Style for week day string.
  final TextStyle? textStyle;

  /// Title for week day in month view.
  const WeekDayTile({
    Key? key,
    required this.dayIndex,
    //this.backgroundColor = Constants.white,
    this.displayBorder = true,
    this.textStyle,
    this.weekDayStringBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.background;
    Color textColor = contrastColor(backgroundColor);
    final localizations = MaterialLocalizations.of(context);
    // M T W T F S S  ← the returned list contains these widgets
    final String weekday = localizations.narrowWeekdays[(dayIndex % 7 + 1) % 7];
    //final String weekday = localizations.shortWeekdays[(dayIndex % 7 + 1) % 7]
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: displayBorder
            ? Border.all(
                color: Constants.defaultBorderColor,
                width: 0.5,
              )
            : null,
      ),
      child: Text(
        //weekDayStringBuilder?.call(dayIndex) ?? Constants.weekTitles[dayIndex],
        weekDayStringBuilder?.call(dayIndex) ?? weekday,
        style: textStyle ??
            TextStyle(
              fontSize: 13,
              color: textColor,
            ),
      ),
    );
  }
}
