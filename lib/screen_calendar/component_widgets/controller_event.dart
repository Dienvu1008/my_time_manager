import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/calendar_data.dart';
import 'package:my_time_manager/screen_calendar/utils/datetime_extensions.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

class EventController<T extends Object?> extends ChangeNotifier {
  /// Calendar controller to control all the events related operations like,
  /// adding event, removing event, etc.
  EventController({
    /// This method will provide list of events on particular date.
    ///
    /// This method is use full when you have recurring events.
    /// As of now this library does not support recurring events.
    /// You can implement same behaviour in this function.
    /// This function will overwrite default behaviour of [getEventsOnDay]
    /// function which will be used to display events on given day in
    /// [MonthView], [DayView] and [WeekView].
    ///
    EventFilter<T>? eventFilter,
  }) : _eventFilter = eventFilter;

  //#region Private Fields
  EventFilter<T>? _eventFilter;

  // Store all calendar event data
  final CalendarData<T> _calendarData = CalendarData();

  //#endregion

  //#region Public Fields

  // TODO: change the type from List<CalendarEventData>
  //  to UnmodifiableListView provided in dart:collection.

  // Note: Do not use this getter inside of EventController class.
  // use _eventList instead.
  /// Returns list of [CalendarEventData<T>] stored in this controller.
  List<TimeInterval> get events =>
      _calendarData.eventList.toList(growable: false);

  /// This method will provide list of events on particular date.
  ///
  /// This method is use full when you have recurring events.
  /// As of now this library does not support recurring events.
  /// You can implement same behaviour in this function.
  /// This function will overwrite default behaviour of [getEventsOnDay]
  /// function which will be used to display events on given day in
  /// [MonthView], [DayView] and [WeekView].
  ///
  EventFilter<T>? get eventFilter => _eventFilter;

  //#endregion

  //#region Public Methods
  /// Add all the events in the list
  /// If there is an event with same date then
  void addAll(List<TimeInterval> events) {
    for (final event in events) {
      _addEvent(event);
    }

    notifyListeners();
  }

  /// Adds a single event in [_events]
  void add(TimeInterval event) {
    _addEvent(event);

    notifyListeners();
  }

  /// Removes [event] from this controller.
  void remove(TimeInterval event) {
    final date = (event.startDate != null ? event.startDate! : event.endDate!)
        .withoutTime;

    // Removes the event from single event map.
    if (_calendarData.events[date] != null) {
      if (_calendarData.events[date]!.remove(event)) {
        _calendarData.eventList.remove(event);
        notifyListeners();
        return;
      }
    }

    // Removes the event from ranging or full day event.
    _calendarData.eventList.remove(event);
    _calendarData.rangingEventList.remove(event);
    _calendarData.fullDayEventList.remove(event);
    notifyListeners();
  }

  /// Removes multiple [event] from this controller.
  void removeWhere(bool Function(TimeInterval element) test) {
    for (final e in _calendarData.events.values) {
      e.removeWhere(test);
    }
    _calendarData.rangingEventList.removeWhere(test);
    _calendarData.eventList.removeWhere(test);
    _calendarData.fullDayEventList.removeWhere(test);
    notifyListeners();
  }

  /// Returns events on given day.
  ///
  /// To overwrite default behaviour of this function,
  /// provide [_eventFilter] argument in [EventController] constructor.
  List<TimeInterval> getEventsOnDay(DateTime date) {
    if (_eventFilter != null) return _eventFilter!.call(date, this.events);

    final events = <TimeInterval>[];

    if (_calendarData.events[date] != null) {
      events.addAll(_calendarData.events[date]!);
    }

    for (final rangingEvent in _calendarData.rangingEventList) {
      if (date == rangingEvent.startDate ||
          date == rangingEvent.endDate ||
          (date.isBefore(rangingEvent.endDate!) &&
              date.isAfter(rangingEvent.startDate!))) {
        events.add(rangingEvent);
      }
    }

    events.addAll(getFullDayEvent(date));

    return events;
  }

  /// Returns full day events on given day.
  List<TimeInterval> getFullDayEvent(DateTime dateTime) {
    final events = <TimeInterval>[];
    for (final event in _calendarData.fullDayEventList) {
      if (dateTime.difference(event.startDate!).inDays >= 0 &&
          event.endDate!.difference(dateTime).inDays > 0) {
        events.add(event);
      }
    }
    return events;
  }

  void updateFilter({required EventFilter<T> newFilter}) {
    if (newFilter != _eventFilter) {
      _eventFilter = newFilter;
      notifyListeners();
    }
  }

  //#endregion

  //#region Private Methods
  void _addEvent(TimeInterval event) {
    assert(event.endDate!.difference(event.startDate!).inDays >= 0,
        'The end date must be greater or equal to the start date');
    if (_calendarData.eventList.contains(event)) return;
    if (event.endDate!.difference(event.startDate!).inDays > 0) {
      if (DateTime.fromMillisecondsSinceEpoch(event.startTimestamp!)
              .isDayStart &&
          DateTime.fromMillisecondsSinceEpoch(event.endTimestamp!).isDayStart) {
        _calendarData.fullDayEventList.add(event);
      } else {
        _calendarData.rangingEventList.add(event);
      }
    } else {
      final date = event.startDate!.withoutTime;

      if (_calendarData.events[date] == null) {
        _calendarData.events.addAll({
          date: [event],
        });
      } else {
        _calendarData.events[date]!.add(event);
      }
    }

    _calendarData.eventList.add(event);

    notifyListeners();
  }

//#endregion
}
