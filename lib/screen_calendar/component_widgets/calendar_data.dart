import 'package:my_time_manager/data/models/model_time_interval.dart';

class CalendarData<T> {
  // Stores events that occurs only once in a map.
  final events = <DateTime, List<TimeInterval>>{};

  // Stores all the events in a list.
  final eventList = <TimeInterval>[];

  // Stores all the ranging events in a list.
  final rangingEventList = <TimeInterval>[];

  // Stores all full day events
  final fullDayEventList = <TimeInterval>[];
}

