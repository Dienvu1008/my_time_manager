import 'dart:collection';

import 'package:flutter/material.dart';

import 'calendar_time_interval_data.dart';
import 'extensions.dart';
import 'typedefs.dart';

class TimeIntervalController<T extends Object?> extends ChangeNotifier {
  /// Calendar controller to control all the events related operations like,
  /// adding event, removing event, etc.
  TimeIntervalController({
    /// This method will provide list of events on particular date.
    ///
    /// This method is use full when you have recurring events.
    /// As of now this library does not support recurring events.
    /// You can implement same behaviour in this function.
    /// This function will overwrite default behaviour of [getEventsOnDay]
    /// function which will be used to display events on given day in
    /// [MonthView], [DayView] and [WeekView].
    ///
    TimeIntervalFilter<T>? timeIntervalFilter,
  }) : _timeIntevalFilter = timeIntervalFilter;

  //#region Private Fields
  TimeIntervalFilter<T>? _timeIntevalFilter;

  /// Store all calendar event data
  final CalendarData<T> _calendarData = CalendarData();

  //#endregion

  //#region Public Fields

  // TODO: change the type from List<CalendarEventData>
  //  to UnmodifiableListView provided in dart:collection.

  // Note: Do not use this getter inside of EventController class.
  // use _eventList instead.
  /// Returns list of [CalendarEventData<T>] stored in this controller.
  // @Deprecated('This is deprecated and will be removed in next major release. '
  //     'Use allEvents instead.')

  /// Lists all the events that are added in the Controller.
  ///
  /// NOTE: This field is deprecated. use [allEvents] instead.
  List<CalendarTimeIntervalData<T>> get timeIntervals =>
      _calendarData.timeIntervals.toList(growable: false);

  /// Lists all the events that are added in the Controller.
  UnmodifiableListView<CalendarTimeIntervalData<T>> get allEvents =>
      _calendarData.timeIntervals;

  /// Defines which events should be displayed on given date.
  ///
  /// This method is use full when you have recurring events.
  /// As of now this library does not support recurring events.
  /// You can implement same behaviour in this function.
  /// This function will overwrite default behaviour of [getEventsOnDay]
  /// function which will be used to display events on given day in
  /// [MonthView], [DayView] and [WeekView].
  ///
  TimeIntervalFilter<T>? get timeIntervalFilter => _timeIntevalFilter;

  //#endregion

  //#region Public Methods
  /// Add all the events in the list
  /// If there is an event with same date then
  void addAll(List<CalendarTimeIntervalData<T>> events) {
    for (final event in events) {
      _calendarData.addEvent(event);
    }
    notifyListeners();
  }

  /// Adds a single event in [_events]
  void add(CalendarTimeIntervalData<T> event) {
    _calendarData.addEvent(event);
    notifyListeners();
  }

  /// Removes [event] from this controller.
  void remove(CalendarTimeIntervalData<T> event) {
    _calendarData.removeEvent(event);
    notifyListeners();
  }

  /// Updates the [event] to have the data from [updated] event.
  ///
  /// If [event] is not found in the controller, it will add the [updated]
  /// event in the controller.
  ///
  void update(
      CalendarTimeIntervalData<T> event, CalendarTimeIntervalData<T> updated) {
    _calendarData.updateTimeInterval(event, updated);
    notifyListeners();
  }

  /// Removes all the [events] from this controller.
  void removeAll(List<CalendarTimeIntervalData<T>> events) {
    for (final event in events) {
      _calendarData.removeEvent(event);
    }
    notifyListeners();
  }

  /// Removes multiple [event] from this controller.
  void removeWhere(TestPredicate<CalendarTimeIntervalData<T>> test) {
    _calendarData.removeWhere(test);
    notifyListeners();
  }

  /// Returns events on given day.
  ///
  /// To overwrite default behaviour of this function,
  /// provide [timeIntervalFilter] argument in [TimeIntervalController] constructor.
  ///
  /// if [includeFullDayEvents] is true, it will include full day events
  /// as well else, it will exclude full day events.
  ///
  /// NOTE: If [timeIntervalFilter] is set i.e, not null, [includeFullDayEvents] will
  /// have no effect. As what events to be included will be decided
  /// by the [timeIntervalFilter].
  ///
  /// To get full day events exclusively, check [getFullDayEvent] method.
  ///
  List<CalendarTimeIntervalData<T>> getEventsOnDay(DateTime date,
      {bool includeFullDayEvents = true}) {
    //ignore: deprecated_member_use_from_same_package
    if (_timeIntevalFilter != null) return _timeIntevalFilter!.call(date, this.timeIntervals);

    return _calendarData.getTimeIntervalsOnDay(date.withoutTime,
        includeFullDayTimeIntervals: includeFullDayEvents);
  }

  /// Returns full day events on given day.
  List<CalendarTimeIntervalData<T>> getFullDayEvent(DateTime date) {
    return _calendarData.getFullDayTimeInterval(date.withoutTime);
  }

  /// Updates the [timeIntervalFilter].
  ///
  /// This will also refresh the UI to reflect the latest event filter.
  void updateFilter({required TimeIntervalFilter<T> newFilter}) {
    if (newFilter != _timeIntevalFilter) {
      _timeIntevalFilter = newFilter;
      notifyListeners();
    }
  }
//#endregion
}

/// Stores the list of the calendar events.
///
/// Provides basic data structure to store the events.
///
/// Exposes methods to manipulate stored data.
///
///
class CalendarData<T> {
  /// Stores all the events in a list(all the items in below 3 list will be
  /// available in this list as global itemList of all events).
  final _timeIntervals = <CalendarTimeIntervalData<T>>[];

  UnmodifiableListView<CalendarTimeIntervalData<T>> get timeIntervals =>
      UnmodifiableListView(_timeIntervals);

  /// Stores events that occurs only once in a map, Here the key will a day
  /// and along to the day as key we will store all the events of that day as
  /// list as value
  final _singleDayEvents = <DateTime, List<CalendarTimeIntervalData<T>>>{};

  UnmodifiableMapView<DateTime,
      UnmodifiableListView<CalendarTimeIntervalData<T>>>
  get singleDayEvents => UnmodifiableMapView(
    Map.fromIterable(
      _singleDayEvents.keys.map((key) {
        return MapEntry(
            key,
            UnmodifiableListView(
              _singleDayEvents[key] ?? [],
            ));
      }),
    ),
  );

  /// Stores all the ranging events in a list
  ///
  /// Events that occurs on multiple day from startDate to endDate.
  ///
  final _rangingEventList = <CalendarTimeIntervalData<T>>[];
  UnmodifiableListView<CalendarTimeIntervalData<T>> get rangingEventList =>
      UnmodifiableListView(_rangingEventList);

  /// Stores all full day events(24hr event).
  ///
  /// This includes all full day events that are recurring day events as well.
  ///
  ///
  final _fullDayEventList = <CalendarTimeIntervalData<T>>[];
  UnmodifiableListView<CalendarTimeIntervalData<T>> get fullDayEventList =>
      UnmodifiableListView(_fullDayEventList);

  //#region Data Manipulation Methods
  void addFullDayEvent(CalendarTimeIntervalData<T> event) {
    // TODO: add separate logic for adding full day event and ranging event.
    _fullDayEventList.addEventInSortedManner(event);
    _timeIntervals.add(event);
  }

  void addRangingEvent(CalendarTimeIntervalData<T> event) {
    _rangingEventList.addEventInSortedManner(event);
    _timeIntervals.add(event);
  }

  void addSingleDayEvent(CalendarTimeIntervalData<T> event) {
    final date = event.date;

    if (_singleDayEvents[date] == null) {
      _singleDayEvents.addAll({
        date: [event],
      });
    } else {
      _singleDayEvents[date]!.addEventInSortedManner(event);
    }

    _timeIntervals.add(event);
  }

  void addEvent(CalendarTimeIntervalData<T> event) {
    assert(event.endDate.difference(event.date).inDays >= 0,
    'The end date must be greater or equal to the start date');

    // TODO: improve this...
    if (_timeIntervals.contains(event)) return;

    if (event.isFullDayEvent) {
      addFullDayEvent(event);
    } else if (event.isRangingEvent) {
      addRangingEvent(event);
    } else {
      addSingleDayEvent(event);
    }
  }

  void removeFullDayEvent(CalendarTimeIntervalData<T> event) {
    if (_fullDayEventList.remove(event)) {
      _timeIntervals.remove(event);
    }
  }

  void removeRangingEvent(CalendarTimeIntervalData<T> event) {
    if (_rangingEventList.remove(event)) {
      _timeIntervals.remove(event);
    }
  }

  void removeSingleDayEvent(CalendarTimeIntervalData<T> event) {
    if (_singleDayEvents[event.date]?.remove(event) ?? false) {
      _timeIntervals.remove(event);
    }
  }

  void removeEvent(CalendarTimeIntervalData<T> event) {
    if (event.isFullDayEvent) {
      removeFullDayEvent(event);
    } else if (event.isRangingEvent) {
      removeRangingEvent(event);
    } else {
      removeSingleDayEvent(event);
    }
  }

  void removeWhere(TestPredicate<CalendarTimeIntervalData<T>> test) {
    final _predicates = <CalendarTimeIntervalData<T>, bool>{};

    bool wrappedPredicate(CalendarTimeIntervalData<T> event) {
      return _predicates[event] = test(event);
    }

    for (final e in _singleDayEvents.values) {
      e.removeWhere(wrappedPredicate);
    }

    _rangingEventList.removeWhere(wrappedPredicate);
    _fullDayEventList.removeWhere(wrappedPredicate);

    _timeIntervals.removeWhere((event) => _predicates[event] ?? false);
  }

  void updateTimeInterval(CalendarTimeIntervalData<T> oldTimeInterval,
      CalendarTimeIntervalData<T> newTimeInterval) {
    removeEvent(oldTimeInterval);
    addEvent(newTimeInterval);
  }
  //#endregion

  //#region Data Fetch Methods
  List<CalendarTimeIntervalData<T>> getTimeIntervalsOnDay(DateTime date,
      {bool includeFullDayTimeIntervals = true}) {
    final timeIntervals = <CalendarTimeIntervalData<T>>[];

    if (_singleDayEvents[date] != null) {
      timeIntervals.addAll(_singleDayEvents[date]!);
    }

    for (final rangingEvent in _rangingEventList) {
      if (rangingEvent.occursOnDate(date)) {
        timeIntervals.add(rangingEvent);
      }
    }

    if (includeFullDayTimeIntervals) {
      timeIntervals.addAll(getFullDayTimeInterval(date));
    }

    return timeIntervals;
  }

  /// Returns full day events on given day.
  List<CalendarTimeIntervalData<T>> getFullDayTimeInterval(DateTime date) {
    final timeIntervals = <CalendarTimeIntervalData<T>>[];

    for (final timeInterval in fullDayEventList) {
      if (timeInterval.occursOnDate(date)) {
        timeIntervals.add(timeInterval);
      }
    }
    return timeIntervals;
  }
//#endregion
}
