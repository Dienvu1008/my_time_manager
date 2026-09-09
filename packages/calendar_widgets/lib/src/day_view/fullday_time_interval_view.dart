import 'package:flutter/material.dart';
import '../calendar_time_interval_data.dart';
import '../extensions.dart';
import '../typedefs.dart';

/// This class is defined default view of full day event
class FullDayTimeIntervalView<T> extends StatelessWidget {
  const FullDayTimeIntervalView({
    Key? key,
    this.boxConstraints = const BoxConstraints(maxHeight: 100),
    required this.timeIntervals,
    this.padding,
    this.itemView,
    this.titleStyle,
    this.onEventTap,
    required this.date,
  }) : super(key: key);

  /// Constraints for view
  final BoxConstraints boxConstraints;

  /// Define List of Event to display
  final List<CalendarTimeIntervalData<T>> timeIntervals;

  /// Define Padding of view
  final EdgeInsets? padding;

  /// Define custom Item view of Event.
  final Widget Function(CalendarTimeIntervalData<T>? event)? itemView;

  /// Style for title
  final TextStyle? titleStyle;

  /// Called when user taps on event tile.
  final TileTapCallback<T>? onEventTap;

  /// Defines date for which events will be displayed.
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: boxConstraints,
      child: ListView.builder(
        itemCount: timeIntervals.length,
        padding: padding ?? EdgeInsets.zero,
        shrinkWrap: true,
        itemBuilder: (context, index) => InkWell(
          onTap: () => onEventTap?.call(timeIntervals[index], date),
          child: itemView?.call(timeIntervals[index]) ??
              Container(
                margin: const EdgeInsets.all(5.0),
                padding: const EdgeInsets.all(1.0),
                height: 24,
                child: Text(
                  timeIntervals[index].title,
                  style: titleStyle ??
                      TextStyle(
                        fontSize: 16,
                        color: timeIntervals[index].color.accent,
                      ),
                  maxLines: 1,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: timeIntervals[index].color,
                ),
                alignment: Alignment.centerLeft,
              ),
        ),
      ),
    );
  }
}
