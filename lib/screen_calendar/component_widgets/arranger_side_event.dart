
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/arranger_time_intervals.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/arranger_merge_event.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/organized_calendar_time_intervals_data.dart';
import 'package:my_time_manager/screen_calendar/utils/constants.dart';
import 'package:my_time_manager/screen_calendar/utils/datetime_extensions.dart';

class SideEventArranger<T extends Object?> extends TimeIntervalsArranger<T> {
  /// This class will provide method that will arrange
  /// all the events side by side.
  const SideEventArranger();

  @override
  List<OrganizedCalendarTimeIntervalsData<T>> arrange({
    required List<TimeInterval> timeIntervals,
    required double height,
    required double width,
    required double heightPerMinute,
  }) {
    final mergedEvents = MergeEventArranger<T>().arrange(
      timeIntervals: timeIntervals,
      height: height,
      width: width,
      heightPerMinute: heightPerMinute,
    );

    final arrangedEvents = <OrganizedCalendarTimeIntervalsData<T>>[];

    for (final event in mergedEvents) {
      // If there is only one event in list that means, there
      // is no simultaneous events.
      if (event.events.length == 1) {
        arrangedEvents.add(event);
        continue;
      }

      final concurrentEvents = event.events;

      if (concurrentEvents.isEmpty) continue;

      var column = 1;
      final sideEventData = <_SideEventData<T>>[];
      var currentEventIndex = 0;

      while (concurrentEvents.isNotEmpty) {
        final event = concurrentEvents[currentEventIndex];
        final end = DateTime.fromMillisecondsSinceEpoch(event.endTimestamp!)
                    .getTotalMinutes ==
                0
            ? Constants.minutesADay
            : DateTime.fromMillisecondsSinceEpoch(event.endTimestamp!)
                .getTotalMinutes;
        sideEventData.add(_SideEventData(column: column, event: event));
        concurrentEvents.removeAt(currentEventIndex);

        while (currentEventIndex < concurrentEvents.length) {
          if (end <
              DateTime.fromMillisecondsSinceEpoch(
                      concurrentEvents[currentEventIndex].startTimestamp!)
                  .getTotalMinutes) {
            break;
          }

          currentEventIndex++;
        }

        if (concurrentEvents.isNotEmpty &&
            currentEventIndex >= concurrentEvents.length) {
          column++;
          currentEventIndex = 0;
        }
      }

      final slotWidth = width / column;

      for (final sideEvent in sideEventData) {
        if (sideEvent.event.startTime == null ||
            sideEvent.event.endTime == null) {
          assert(() {
            try {
              debugPrint("Start time or end time of an event can not be null. "
                  "This ${sideEvent.event} will be ignored.");
            } catch (e) {} // Suppress exceptions.

            return true;
          }(), "Can not add event in the list.");

          continue;
        }

        final startTime = sideEvent.event.startTimestamp!;
        final endTime = sideEvent.event.endTimestamp!;
        final bottom = height -
            (DateTime.fromMillisecondsSinceEpoch(endTime).getTotalMinutes == 0
                    ? Constants.minutesADay
                    : DateTime.fromMillisecondsSinceEpoch(endTime)
                        .getTotalMinutes) *
                heightPerMinute;
        arrangedEvents.add(OrganizedCalendarTimeIntervalsData<T>(
          left: slotWidth * (sideEvent.column - 1),
          right: slotWidth * (column - sideEvent.column),
          top: DateTime.fromMillisecondsSinceEpoch(startTime).getTotalMinutes *
              heightPerMinute,
          bottom: bottom,
          startDuration: DateTime.fromMillisecondsSinceEpoch(startTime),
          endDuration: DateTime.fromMillisecondsSinceEpoch(endTime),
          events: [sideEvent.event],
        ));
      }
    }

    return arrangedEvents;
  }
}

class _SideEventData<T> {
  final int column;
  final TimeInterval event;

  const _SideEventData({
    required this.column,
    required this.event,
  });
}