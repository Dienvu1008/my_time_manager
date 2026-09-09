part of 'time_interval_arrangers.dart';

class SideTimeIntervalArranger<T extends Object?> extends TimeIntervalArranger<T> {
  /// This class will provide method that will arrange
  /// all the events side by side.
  const SideTimeIntervalArranger({
    this.includeEdges = false,
  });

  /// Decides whether events that are overlapping on edge
  /// (ex, event1 has the same end-time as the start-time of event 2)
  /// should be offset or not.
  ///
  /// If includeEdges is true, it will offset the events else it will not.
  ///
  final bool includeEdges;

  /// {@macro event_arranger_arrange_method_doc}
  ///
  /// Make sure that all the events that are passed in [timeIntervals], must be in
  /// ascending order of start time.
  @override
  List<OrganizedCalendarTimeIntervalData<T>> arrange({
    required List<CalendarTimeIntervalData<T>> timeIntervals,
    required double height,
    required double width,
    required double heightPerMinute,
  }) {
    final mergedTimeIntervals = MergeTimeIntervalArranger<T>(
      includeEdges: includeEdges,
    ).arrange(
      timeIntervals: timeIntervals,
      height: height,
      width: width,
      heightPerMinute: heightPerMinute,
    );

    final arrangedEvents = <OrganizedCalendarTimeIntervalData<T>>[];

    for (final event in mergedTimeIntervals) {
      // If there is only one event in list that means, there
      // is no simultaneous events.
      if (event.timeIntervals.length == 1) {
        arrangedEvents.add(event);
        continue;
      }

      final concurrentEvents = event.timeIntervals;

      if (concurrentEvents.isEmpty) continue;

      var column = 1;
      final sideEventData = <_SideEventData<T>>[];
      var currentEventIndex = 0;

      while (concurrentEvents.isNotEmpty) {
        final event = concurrentEvents[currentEventIndex];
        final end = event.endTime!.getTotalMinutes == 0
            ? Constants.minutesADay
            : event.endTime!.getTotalMinutes;
        sideEventData.add(_SideEventData(column: column, event: event));
        concurrentEvents.removeAt(currentEventIndex);

        while (currentEventIndex < concurrentEvents.length) {
          if (end <
              concurrentEvents[currentEventIndex].startTime!.getTotalMinutes) {
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

        final startTime = sideEvent.event.startTime!;
        final endTime = sideEvent.event.endTime!;
        final bottom = height -
            (endTime.getTotalMinutes == 0
                ? Constants.minutesADay
                : endTime.getTotalMinutes) *
                heightPerMinute;
        arrangedEvents.add(OrganizedCalendarTimeIntervalData<T>(
          left: slotWidth * (sideEvent.column - 1),
          right: slotWidth * (column - sideEvent.column),
          top: startTime.getTotalMinutes * heightPerMinute,
          bottom: bottom,
          startDuration: startTime,
          endDuration: endTime,
          timeIntervals: [sideEvent.event],
        ));
      }
    }

    return arrangedEvents;
  }
}

class _SideEventData<T> {
  final int column;
  final CalendarTimeIntervalData<T> event;

  const _SideEventData({
    required this.column,
    required this.event,
  });
}
