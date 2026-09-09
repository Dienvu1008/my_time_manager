import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../calendar_time_interval_data.dart';
import '../constants.dart';
import '../typedefs.dart';
import '../utils.dart';



class FilledCell<T extends Object?> extends StatelessWidget {
  /// Date of current cell.
  final DateTime date;

  /// List of events on for current date.
  final List<CalendarTimeIntervalData<T>> timeIntervals;

  /// defines date string for current cell.
  final DateTimeStringProvider? dateStringBuilder;

  /// Defines if cell should be highlighted or not.
  /// If true it will display date title in a circle.
  final bool shouldHighlight;

  /// Defines background color of cell.
  final Color backgroundColor;

  /// Defines highlight color.
  final Color highlightColor;

  /// Color for event tile.
  final Color tileColor;

  /// Called when user taps on any event tile.
  final TileTapCallback<T>? onTileTap;

  /// defines that [date] is in current month or not.
  final bool isInMonth;

  /// defines radius of highlighted date.
  final double highlightRadius;

  /// color of cell title
  final Color titleColor;

  /// color of highlighted cell title
  final Color highlightedTitleColor;

  /// This class will defines how cell will be displayed.
  /// This widget will display all the events as tile below date title.
  const FilledCell({
    Key? key,
    required this.date,
    required this.timeIntervals,
    this.isInMonth = false,
    this.shouldHighlight = false,
    this.backgroundColor = Colors.black,
    this.highlightColor = Colors.blue,
    this.onTileTap,
    this.tileColor = Colors.blue,
    this.highlightRadius = 11,
    this.titleColor = Constants.black,
    this.highlightedTitleColor = Constants.white,
    this.dateStringBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color textColor = contrastColor(backgroundColor);
    final locale = Localizations.localeOf(context);
    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: 5.0,
          ),
          CircleAvatar(
            radius: highlightRadius,
            backgroundColor:
            shouldHighlight ? highlightColor : Colors.transparent,
            child: Text(
              dateStringBuilder?.call(date,locale) ?? "${date.day}",
              style: TextStyle(
                color: shouldHighlight
                    ? highlightedTitleColor
                    : isInMonth
                // ? titleColor
                // : titleColor.withOpacity(0.4),
                    ? textColor.withOpacity(0.4)
                    : textColor,
                fontSize: 12,
              ),
            ),
          ),
          if (timeIntervals.isNotEmpty)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 5.0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(),
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      timeIntervals.length,
                          (index) => GestureDetector(
                        onTap: () =>
                            onTileTap?.call(timeIntervals[index], timeIntervals[index].date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: timeIntervals[index].color,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          margin: EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 3.0),
                          padding: const EdgeInsets.all(2.0),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  timeIntervals[index].title,
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                  style: timeIntervals[0].titleStyle ??
                                      TextStyle(
                                        color: timeIntervals[index].color.accent,
                                        fontSize: 12,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}