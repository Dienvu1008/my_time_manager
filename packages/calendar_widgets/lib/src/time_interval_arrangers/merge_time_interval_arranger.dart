part of 'time_interval_arrangers.dart';

class MergeTimeIntervalArranger<T extends Object?> extends TimeIntervalArranger<T> {
  /// This class will provide method that will merge all the simultaneous
  /// events. and that will act like one single event.
  /// [OrganizedCalendarTimeIntervalData.timeIntervals] will gives
  /// list of all the combined events.
  const MergeTimeIntervalArranger({
    this.includeEdges = true,
  });

  /// Decides whether events that are overlapping on edge
  /// (ex, event1 has the same end-time as the start-time of event 2)
  /// should be merged together or not.
  ///
  /// If includeEdges is true, it will merge the events else it will not.
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
    // TODO: Right now all the events that are passed in this function must be
    // sorted in ascending order of the start time.
    //
    final arrangedTimeIntervals = <OrganizedCalendarTimeIntervalData<T>>[];

    for (final timeInterval in timeIntervals) {
      // Checks if an event has valid start and end time.
      if (timeInterval.startTime == null ||
          timeInterval.endTime == null ||
          timeInterval.endTime!.getTotalMinutes <= timeInterval.startTime!.getTotalMinutes) {
        if (!(timeInterval.endTime!.getTotalMinutes == 0 &&
            timeInterval.startTime!.getTotalMinutes > 0)) {
          assert(() {
            try {
              debugPrint(
                  "Failed to add event because of one of the given reasons: "
                      "\n1. Start time or end time might be null"
                      "\n2. endTime occurs before or at the same time as startTime."
                      "\nEvent data: \n$timeInterval\n");
            } catch (e) {} // Suppress exceptions.

            return true;
          }(), "Can not add event in the list.");
          continue;
        }
      }

      final startTime = timeInterval.startTime!;
      final endTime = timeInterval.endTime!;

      final eventStart = startTime.getTotalMinutes;
      final eventEnd = endTime.getTotalMinutes == 0
          ? Constants.minutesADay
          : endTime.getTotalMinutes;

      final arrangeEventLen = arrangedTimeIntervals.length;

      var eventIndex = -1;

      for (var i = 0; i < arrangeEventLen; i++) {
        final arrangedEventStart =
            arrangedTimeIntervals[i].startDuration.getTotalMinutes;

        final arrangedEventEnd =
        arrangedTimeIntervals[i].endDuration.getTotalMinutes == 0
            ? Constants.minutesADay
            : arrangedTimeIntervals[i].endDuration.getTotalMinutes;

        if (_checkIsOverlapping(
            arrangedEventStart, arrangedEventEnd, eventStart, eventEnd)) {
          eventIndex = i;
          break;
        }
      }

      if (eventIndex == -1) {
        final top = eventStart * heightPerMinute;
        final bottom = eventEnd * heightPerMinute == height
            ? 0.0
            : height - eventEnd * heightPerMinute;

        final newEvent = OrganizedCalendarTimeIntervalData<T>(
          top: top,
          bottom: bottom,
          left: 0,
          right: 0,
          startDuration: startTime.copyFromMinutes(eventStart),
          endDuration: endTime.copyFromMinutes(eventEnd),
          timeIntervals: [timeInterval],
        );

        arrangedTimeIntervals.add(newEvent);
      } else {
        final arrangedEventData = arrangedTimeIntervals[eventIndex];

        final arrangedEventStart =
            arrangedEventData.startDuration.getTotalMinutes;
        final arrangedEventEnd =
        arrangedEventData.endDuration.getTotalMinutes == 0
            ? Constants.minutesADay
            : arrangedEventData.endDuration.getTotalMinutes;

        final startDuration = math.min(eventStart, arrangedEventStart);
        final endDuration = math.max(eventEnd, arrangedEventEnd);

        final top = startDuration * heightPerMinute;
        final bottom = endDuration * heightPerMinute == height
            ? 0.0
            : height - endDuration * heightPerMinute;

        final newEvent = OrganizedCalendarTimeIntervalData<T>(
          top: top,
          bottom: bottom,
          left: 0,
          right: 0,
          startDuration:
          arrangedEventData.startDuration.copyFromMinutes(startDuration),
          endDuration:
          arrangedEventData.endDuration.copyFromMinutes(endDuration),
          timeIntervals: arrangedEventData.timeIntervals..add(timeInterval),
        );

        arrangedTimeIntervals[eventIndex] = newEvent;
      }
    }

    return arrangedTimeIntervals;
  }

  bool _checkIsOverlapping(int eStart1, int eEnd1, int eStart2, int eEnd2) {
    final result = (eStart1 >= eStart2 && eStart1 < eEnd2) ||
        (eEnd1 > eStart2 && eEnd1 <= eEnd2) ||
        (eStart2 >= eStart1 && eStart2 < eEnd1) ||
        (eEnd2 > eStart1 && eEnd2 <= eEnd1) ||
        (includeEdges &&
            (eStart1 == eEnd2 ||
                eEnd1 == eStart2 ||
                eStart2 == eEnd1 ||
                eEnd2 == eStart1));

    return result;
  }
}
