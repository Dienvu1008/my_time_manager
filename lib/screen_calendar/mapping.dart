import 'package:calendar_widgets/calendar_widgets.dart';

import '../data/models/model_time_interval.dart';

extension ListTimeIntervalCalendarData on List<TimeInterval> {
  List<CalendarTimeIntervalData> toCalendarData() {
    return map((timeInterval) => CalendarTimeIntervalData(
          date:
              timeInterval.startDate ?? timeInterval.endDate ?? DateTime.now(),
          startTime: timeInterval.calendarStartDateTime,
          endTime: timeInterval.calendarEndDateTime,
          title: timeInterval.title,
          description: timeInterval.description,
          color: timeInterval.color,
          event: timeInterval,
        )).toList();
  }
}

