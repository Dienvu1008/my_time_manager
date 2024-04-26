import 'dart:collection';

import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';

import '../data/models/model_list.dart';
import '../data/models/model_time_interval.dart';
import '../utils/utils.dart';

typedef TimeIntervalFilter = List<TimeInterval> Function(
    DateTime date, List<TimeInterval> timeIntervals);

typedef TaskListFilter = List<TaskList> Function(List<TaskList> timeIntervals);

typedef TestPredicate<T> = bool Function(T element);

class DataController extends ChangeNotifier {
  DataController({
    /// This method will provide list of events on particular date.
    ///
    /// This method is use full when you have recurring events.
    /// As of now this library does not support recurring events.
    /// You can implement same behaviour in this function.
    /// This function will overwrite default behaviour of [getEventsOnDay]
    /// function which will be used to display events on given day in
    /// [MonthView], [DayView] and [WeekView].
    ///
    TimeIntervalFilter? timeIntervalFilter,
  }) : _timeIntevalFilter = timeIntervalFilter;

  //#region Private Fields
  TimeIntervalFilter? _timeIntevalFilter;

  /// Store all calendar event data
  final TimeIntervalData _timeIntervalsData = TimeIntervalData();
  final DatabaseManager _databaseManager = DatabaseManager();

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
  // List<TimeInterval> get timeIntervals =>
  //     _calendarData.timeIntervals.toList(growable: false);

  /// Lists all the events that are added in the Controller.
  UnmodifiableListView<TimeInterval> get allEvents =>
      _timeIntervalsData.timeIntervals;

  /// Defines which events should be displayed on given date.
  ///
  /// This method is use full when you have recurring events.
  /// As of now this library does not support recurring events.
  /// You can implement same behaviour in this function.
  /// This function will overwrite default behaviour of [getEventsOnDay]
  /// function which will be used to display events on given day in
  /// [MonthView], [DayView] and [WeekView].
  ///
  TimeIntervalFilter? get timeIntervalFilter => _timeIntevalFilter;

  //#endregion

  //#region Public Methods
  /// Add all the events in the list
  /// If there is an event with same date then
  void addAll(List<TimeInterval> events) {
    for (final event in events) {
      _timeIntervalsData.addEvent(event);
    }
    notifyListeners();
  }

  /// Adds a single event in [_events]
  void add(TimeInterval event) {
    _databaseManager.insertTimeInterval(event);
    _timeIntervalsData.addEvent(event);
    notifyListeners();
  }

  /// Removes [event] from this controller.
  void remove(TimeInterval event) {
    _databaseManager.deleteTimeInterval(event.id);
    _timeIntervalsData.removeEvent(event);
    notifyListeners();
  }

  /// Updates the [event] to have the data from [updated] event.
  ///
  /// If [event] is not found in the controller, it will add the [updated]
  /// event in the controller.
  ///
  void update(TimeInterval event, TimeInterval updated) {
    _databaseManager.updateTimeInterval(event);
    _timeIntervalsData.updateTimeInterval(event, updated);
    notifyListeners();
  }

  /// Removes all the [events] from this controller.
  void removeAll(List<TimeInterval> events) {
    for (final event in events) {
      _databaseManager.deleteTimeInterval(event.id);
      _timeIntervalsData.removeEvent(event);
    }
    notifyListeners();
  }

  /// Removes multiple [event] from this controller.
  void removeWhere(TestPredicate<TimeInterval> test) {
    //_databaseManager.deleteTimeInterval(test);
    _timeIntervalsData.removeWhere(test);
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
  List<TimeInterval> getEventsOnDay(DateTime date,
      {bool includeFullDayEvents = true}) {
    //ignore: deprecated_member_use_from_same_package
    //if (_timeIntevalFilter != null) return _timeIntevalFilter!.call(date, timeIntervals);
    if (_timeIntevalFilter != null)
      return _timeIntevalFilter!.call(date, allEvents);

    return _timeIntervalsData.getTimeIntervalsOnDay(date,
        includeFullDayTimeIntervals: includeFullDayEvents);
  }

  List<TimeInterval> getEventsOnDays(
    Iterable<DateTime> dates,
    //{bool includeFullDayEvents = true}
  ) {
    //ignore: deprecated_member_use_from_same_package
    ///if (_timeIntevalFilter != null) return _timeIntevalFilter!.call(date, timeIntervals);

    return _timeIntervalsData._getTimeIntervalsForDays(
      dates,
      //includeFullDayTimeIntervals: includeFullDayEvents
    );
  }

  /// Returns full day events on given day.
  List<TimeInterval> getFullDayEvent(DateTime date) {
    return _timeIntervalsData.getFullDayTimeInterval(date);
  }

  /// Updates the [timeIntervalFilter].
  ///
  /// This will also refresh the UI to reflect the latest event filter.
  void updateFilter({required TimeIntervalFilter newFilter}) {
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
class TimeIntervalData<T> {
  /// Stores all the events in a list(all the items in below 3 list will be
  /// available in this list as global itemList of all events).
  final _timeIntervals = <TimeInterval>[];
  final DatabaseManager _databaseManager = DatabaseManager();

  UnmodifiableListView<TimeInterval> get timeIntervals =>
      //UnmodifiableListView(_timeIntervals);
      UnmodifiableListView(
          _databaseManager.timeIntervals() as Iterable<TimeInterval>);

  /// Stores events that occurs only once in a map, Here the key will a day
  /// and along to the day as key we will store all the events of that day as
  /// list as value
  final _singleDayEvents = <DateTime, List<TimeInterval>>{};

  UnmodifiableMapView<DateTime, UnmodifiableListView<TimeInterval>>
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

  final _multiDaysEvents = <List<DateTime>, List<TimeInterval>>{};

  // UnmodifiableMapView<List<DateTime>, UnmodifiableListView<TimeInterval>>
  // get _multiDaysEvents => UnmodifiableMapView(
  //   Map.fromIterable(
  //     _multiDaysEvents.keys.map((key) {
  //       return MapEntry(
  //           key,
  //           UnmodifiableListView(
  //             _multiDaysEvents[key] ?? [],
  //           ));
  //     }),
  //   ),
  // );

  /// Stores all the ranging events in a list
  ///
  /// Events that occurs on multiple day from startDate to endDate.
  ///
  final _rangingEventList = <TimeInterval>[];
  UnmodifiableListView<TimeInterval> get rangingEventList =>
      UnmodifiableListView(_rangingEventList);

  /// Stores all full day events(24hr event).
  ///
  /// This includes all full day events that are recurring day events as well.
  ///
  ///
  final _fullDayEventList = <TimeInterval>[];
  UnmodifiableListView<TimeInterval> get fullDayEventList =>
      UnmodifiableListView(_fullDayEventList);

  //#region Data Manipulation Methods
  void addFullDayEvent(TimeInterval event) {
    // TODO: add separate logic for adding full day event and ranging event.
    _fullDayEventList.addEventInSortedManner(event);
    //_timeIntervals.add(event);
  }

  void addRangingEvent(TimeInterval event) {
    _rangingEventList.addEventInSortedManner(event);
    //_timeIntervals.add(event);
  }

  void addSingleDayEvent(TimeInterval event) {
    final date = event.startDate ?? event.endDate ?? DateTime.now();

    if (_singleDayEvents[date] == null) {
      _singleDayEvents.addAll({
        date: [event],
      });
    } else {
      _singleDayEvents[date]!.addEventInSortedManner(event);
    }

    _timeIntervals.add(event);
  }

  void addEvent(TimeInterval event) {
    assert(event.endDate!.difference(event.startDate!).inDays >= 0,
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

  void removeFullDayEvent(TimeInterval event) {
    if (_fullDayEventList.remove(event)) {
      _timeIntervals.remove(event);
    }
  }

  void removeRangingEvent(TimeInterval event) {
    if (_rangingEventList.remove(event)) {
      _timeIntervals.remove(event);
    }
  }

  void removeSingleDayEvent(TimeInterval event) {
    if (_singleDayEvents[event.startDate]?.remove(event) ?? false) {
      _timeIntervals.remove(event);
    }
  }

  void removeEvent(TimeInterval event) {
    if (event.isFullDayEvent) {
      removeFullDayEvent(event);
    } else if (event.isRangingEvent) {
      removeRangingEvent(event);
    } else {
      removeSingleDayEvent(event);
    }
  }

  void removeWhere(TestPredicate<TimeInterval> test) {
    final _predicates = <TimeInterval, bool>{};

    bool wrappedPredicate(TimeInterval event) {
      return _predicates[event] = test(event);
    }

    for (final e in _singleDayEvents.values) {
      e.removeWhere(wrappedPredicate);
    }

    _rangingEventList.removeWhere(wrappedPredicate);
    _fullDayEventList.removeWhere(wrappedPredicate);

    _timeIntervals.removeWhere((event) => _predicates[event] ?? false);
  }

  void updateTimeInterval(
      TimeInterval oldTimeInterval, TimeInterval newTimeInterval) {
    removeEvent(oldTimeInterval);
    addEvent(newTimeInterval);
  }

  Future<void> deleteTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.deleteTimeInterval(timeInterval.id);

    _timeIntervals.remove(timeInterval);
  }

  Future<void> onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval =
        timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);

    _timeIntervals[index] = updatedTimeInterval;
  }

  Future<void> onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(
      subtasks: timeInterval.subtasks,
    );
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);

    _timeIntervals[index] = updatedTimeInterval;
  }

  // Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
  //   final TextEditingController _hasBeenDoneController = TextEditingController(
  //     text: timeInterval.howMuchHasBeenDone.toString(),
  //   );
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(AppLocalizations.of(context)!.hasBeenDone),
  //       content: TextFormField(
  //         controller: _hasBeenDoneController,
  //         //decoration: InputDecoration(labelText: 'has been done'),
  //         keyboardType: const TextInputType.numberWithOptions(
  //             decimal: true, signed: false),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(AppLocalizations.of(context)!.cancel),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             TimeInterval _timeInterval = timeInterval.copyWith(
  //                 howMuchHasBeenDone:
  //                     double.parse(_hasBeenDoneController.text));
  //             await _databaseManager.updateTimeInterval(_timeInterval);
  //             final updatedTimeInterval =
  //                 await _databaseManager.timeInterval(timeInterval.id);
  //             final index = _timeIntervals
  //                 .indexWhere((item) => item.id == updatedTimeInterval.id);
  //             // final index2 = _selectedTimeIntervals.value
  //             //     .indexWhere((item) => item.id == updatedTimeInterval.id);
  //             // if (index != -1) {
  //             //   setState(() {
  //             //     _timeIntervals[index] = updatedTimeInterval;
  //             //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
  //             //   });
  //             // }
  //
  //             setState(() {
  //               _timeIntervals[index] = updatedTimeInterval;
  //             });
  //             Navigator.pop(context);
  //           },
  //           child: Text(AppLocalizations.of(context)!.update),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  //#endregion

  //#region Data Fetch Methods
  List<TimeInterval> getTimeIntervalsOnDay(DateTime date,
      {bool includeFullDayTimeIntervals = true}) {
    final timeIntervals = <TimeInterval>[];

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
  List<TimeInterval> getFullDayTimeInterval(DateTime date) {
    final timeIntervals = <TimeInterval>[];

    for (final timeInterval in fullDayEventList) {
      if (timeInterval.occursOnDate(date)) {
        timeIntervals.add(timeInterval);
      }
    }
    return timeIntervals;
  }

  final LinkedHashMap<DateTime, List<TimeInterval>> _kTimeIntervals =
      LinkedHashMap<DateTime, List<TimeInterval>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  List<TimeInterval> _getTimeIntervalsForDay(DateTime day) {

    return _kTimeIntervals[day] ?? [];
  }

  List<TimeInterval> _getTimeIntervalsForDays(Iterable<DateTime> days) {
    return [
      for (final d in days) ..._getTimeIntervalsForDay(d),
      //for (final d in days) ...getTimeIntervalsOnDay(d)
    ];
  }

  List<TimeInterval> _getTimeIntervalsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return _getTimeIntervalsForDays(days);
  }

//#endregion
}

extension MyList on List<TimeInterval> {
  // Below function will add the new event in sorted manner(startTimeWise) in
  // the existing list of CalendarEventData.

  void addEventInSortedManner(TimeInterval timeIntervals) {
    var addIndex = -1;

    for (var i = 0; i < this.length; i++) {
      if ((timeIntervals.startTime?.getTotalMinutes ?? 0) -
              (this[i].startTime?.getTotalMinutes ?? 0) <=
          0) {
        addIndex = i;
        break;
      }
    }

    if (addIndex > -1) {
      insert(addIndex, timeIntervals);
    } else {
      add(timeIntervals);
    }
  }
}

extension TimerOfDayExtension on TimeOfDay {
  int get getTotalMinutes => hour * 60 + minute;
}
