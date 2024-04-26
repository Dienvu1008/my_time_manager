import 'dart:collection';
import 'dart:io';
import 'package:calendar_widgets/src_table_calendar/customization/calendar_builders.dart';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_widgets/src_sticky_header/widgets/sliver_sticky_header.dart';
import '../app/app_localizations.dart';
import '../data/database/database_manager.dart';
import '../data/models/model_time_interval.dart';
import '../home/data_controller.dart';
import '../home/data_controller_provider.dart';
import 'component_widgets/card_time_interval.dart';
import 'component_widgets/page_add_edit_time_interval.dart';
import '../utils/utils.dart';

class TasksTimeLinePage extends StatefulWidget {
  final List<TimeInterval> timeIntervals;
  // final bool showCalendar;
  // late final DateTime focusedDay;
  // late final DateTime? rangeStart;
  // late final DateTime? rangeEnd;
  // final bool Function(DateTime) selectedDayPredicate;
  //
  // final List<TimeInterval> Function(DateTime) getTimeIntervalsForDay;
  //
  // final CalendarFormat calendarFormat;
  // late final RangeSelectionMode rangeSelectionMode;
  // final void Function(DateTime, DateTime) onDaySelected;
  // final void Function(DateTime?, DateTime?, DateTime) onRangeSelected;
  // final void Function(PageController) onCalendarCreated;
  // final void Function(DateTime) onPageChanged;
  // final void Function(CalendarFormat) onFormatChanged;
  // //final CalendarBuilders calendarBuilders;
  //
  // final List<DateTime> selectedDaysSorted;
  // final List<TimeInterval> selectedTimeIntervals;
  //
  // final DataController? controller;

  TasksTimeLinePage({
    super.key,
    required this.timeIntervals,
    // required this.showCalendar,
    // required this.focusedDay,
    // required this.selectedDayPredicate,
    // required this.rangeStart,
    // required this.rangeEnd,
    // required this.getTimeIntervalsForDay,
    // required this.calendarFormat,
    // required this.rangeSelectionMode,
    // required this.onDaySelected,
    // required this.onRangeSelected,
    // required this.onCalendarCreated,
    // required this.onPageChanged,
    // required this.onFormatChanged,
    // required this.selectedDaysSorted,
    // required this.selectedTimeIntervals,
    // this.controller,
    //required this.calendarBuilders,
  });

  @override
  _TasksTimeLinePageState createState() => _TasksTimeLinePageState();
}

class _TasksTimeLinePageState extends State<TasksTimeLinePage> {
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  late final ValueNotifier<List<TimeInterval>> _selectedTimeIntervals;

  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _selectedTimeIntervalsNew = [];
  DateTime _focusedDayNew = DateTime.now();
  // late final CalendarBuilders<TimeInterval> calendarBuilders =
  //     const CalendarBuilders();
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  List<DateTime> _selectedDaysList = [];

  late LinkedHashMap<DateTime, List<TimeInterval>> _kTimeIntervals =
      LinkedHashMap<DateTime, List<TimeInterval>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  //List<TimeInterval> _timeIntervals = [];

  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _showCalendar = true;

  @override
  void initState() {
    super.initState();
    _init();
    _selectedDays.add(DateTime.now());
    _selectedDaysList = _selectedDays.toList()..sort((a, b) => a.compareTo(b));
    _selectedTimeIntervalsNew = _getTimeIntervalsForDays(_selectedDaysList);

  }

  @override
  void dispose() {
    //_focusedDay.dispose();
    _selectedTimeIntervals.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    //final timeIntervals = await _databaseManager.timeIntervals();
    final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
    for (final interval in widget.timeIntervals) {
      // final date = DateTime(interval.startDate!.year, interval.startDate!.month,
      //     interval.startDate!.day);
      final date = (interval.startDate != null)
          ? DateTime(interval.startDate!.year, interval.startDate!.month,
              interval.startDate!.day)
          : DateTime(interval.endDate!.year, interval.endDate!.month,
              interval.endDate!.day);

      if (kTimeIntervalSource.containsKey(date)) {
        kTimeIntervalSource[date]!.add(interval);
      } else {
        kTimeIntervalSource[date] = [interval];
      }
    }
    _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(kTimeIntervalSource);
    //_timeIntervals = timeIntervals;
  }

  bool get canClearSelection =>
      _selectedDays.isNotEmpty || _rangeStart != null || _rangeEnd != null;

  List<TimeInterval> _getTimeIntervalsForDay(DateTime day) {
    return _kTimeIntervals[day] ?? [];
  }

  List<TimeInterval> _getTimeIntervalsForDays(Iterable<DateTime> days) {
    return [
      for (final d in days) ..._getTimeIntervalsForDay(d),
    ];
  }

  List<TimeInterval> _getTimeIntervalsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return _getTimeIntervalsForDays(days);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDaysList.contains(selectedDay)) {
        _selectedDaysList.remove(selectedDay);
      } else {
        _selectedDaysList.add(selectedDay);
      }
      _selectedDaysList.toList().sort((a, b) => a.compareTo(b));

      //_focusedDay.value = focusedDay;
      _focusedDayNew = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });

    _selectedTimeIntervals.value = _getTimeIntervalsForDays(_selectedDaysList);
    _selectedTimeIntervalsNew = _getTimeIntervalsForDays(_selectedDaysList);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      //_focusedDay.value = focusedDay;
      _focusedDayNew = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedDaysList.clear();
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // if (start != null && end != null) {
    //   _selectedTimeIntervals.value = _getTimeIntervalsForRange(start, end);
    // } else if (start != null) {

    //   _selectedTimeIntervals.value = _getTimeIntervalsForDay(start);
    // } else if (end != null) {
    //   _selectedTimeIntervals.value = _getTimeIntervalsForDay(end);
    // }

    if (start != null && end != null) {
      _selectedTimeIntervalsNew = _getTimeIntervalsForRange(start, end);
    } else if (start != null) {
      _selectedTimeIntervalsNew = _getTimeIntervalsForDay(start);
    } else if (end != null) {
      _selectedTimeIntervalsNew = _getTimeIntervalsForDay(end);
    }
  }

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.deleteTimeInterval(timeInterval.id);
    setState(() {
      widget.timeIntervals.remove(timeInterval);
      //_selectedTimeIntervals.value.remove(timeInterval);
      _selectedTimeIntervalsNew.remove(timeInterval);
    });
  }

  Future<void> _onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval =
        timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        widget.timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    // final index2 = _selectedTimeIntervals.value
    //     .indexWhere((item) => item.id == updatedTimeInterval.id);
    // if (index != -1) {
    //   setState(() {
    //     _timeIntervals[index] = updatedTimeInterval;
    //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
    //   });
    // }
    final index2 = _selectedTimeIntervalsNew
        .indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
      setState(() {
        widget.timeIntervals[index] = updatedTimeInterval;
        _selectedTimeIntervalsNew[index2] = updatedTimeInterval;
      });
    }
  }

  Future<void> _onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(
      subtasks: timeInterval.subtasks,
    );
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        widget.timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    // final index2 = _selectedTimeIntervals.value
    //     .indexWhere((item) => item.id == updatedTimeInterval.id);
    // if (index != -1) {
    //   setState(() {
    //     _timeIntervals[index] = updatedTimeInterval;
    //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
    //   });
    // }
    final index2 = _selectedTimeIntervalsNew
        .indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
      setState(() {
        widget.timeIntervals[index] = updatedTimeInterval;
        _selectedTimeIntervalsNew[index2] = updatedTimeInterval;
      });
    }
  }

  Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: timeInterval.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.hasBeenDone),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              TimeInterval _timeInterval = timeInterval.copyWith(
                  howMuchHasBeenDone:
                      double.parse(_hasBeenDoneController.text));
              await _databaseManager.updateTimeInterval(_timeInterval);
              final updatedTimeInterval =
                  await _databaseManager.timeInterval(timeInterval.id);
              final index = widget.timeIntervals
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              // final index2 = _selectedTimeIntervals.value
              //     .indexWhere((item) => item.id == updatedTimeInterval.id);
              // if (index != -1) {
              //   setState(() {
              //     _timeIntervals[index] = updatedTimeInterval;
              //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
              //   });
              // }
              final index2 = _selectedTimeIntervalsNew
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              if (index != -1) {
                setState(() {
                  widget.timeIntervals[index] = updatedTimeInterval;
                  _selectedTimeIntervalsNew[index2] = updatedTimeInterval;
                });
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  // @override
  // void initState() {
  //   super.initState();
  //   setState(() {});
  // }

  // DataController? _controller;
  // late VoidCallback _reloadCallback;

  /// Reloads page.
  ///
  // void _reload() {
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _reloadCallback = _reload;
  //
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //
  //   final newController = widget.controller ??
  //       DataControllerProvider.of(context).controller;
  //
  //   if (newController != _controller) {
  //     _controller = newController;
  //
  //     _controller!
  //     // Removes existing callback.
  //       ..removeListener(_reloadCallback)
  //
  //     // Reloads the view if there is any change in controller or
  //     // user adds new events.
  //       ..addListener(_reloadCallback);
  //   }
  // }

  // @override
  // void didUpdateWidget(TasksTimeLinePage oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Update controller.
  //   final newController = widget.controller ??
  //       DataControllerProvider.of(context).controller;
  //
  //   if (newController != _controller) {
  //     _controller?.removeListener(_reloadCallback);
  //     _controller = newController;
  //     _controller?.addListener(_reloadCallback);
  //   }
  //
  // }
  //
  // @override
  // void dispose() {
  //   _controller?.removeListener(_reloadCallback);
  //   super.dispose();
  // }
  //
  // DataController get controller {
  //   if (_controller == null) {
  //     throw "EventController is not initialized yet.";
  //   }
  //   return _controller!;
  // }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AppBar(
            title: ValueListenableBuilder<DateTime>(
                valueListenable: _focusedDay,
                builder: (context, value, _) {
                  return CalendarHeader(
                    focusedDay: _focusedDayNew,
                    clearButtonVisible: canClearSelection,
                    onTodayButtonTap: () {
                      setState(() => _focusedDayNew = DateTime.now());
                    },
                    onClearButtonTap: () {
                      setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                        _selectedDays.clear();
                        _selectedTimeIntervalsNew = [];
                      });
                    },
                    onLeftArrowTap: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    onRightArrowTap: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    onSelectionModeChanged: (String value) {
                      setState(() {
                        if (value == 'multi') {
                          _rangeSelectionMode = RangeSelectionMode.toggledOff;
                        } else if (value == 'range') {
                          _rangeSelectionMode = RangeSelectionMode.toggledOn;
                        } else if (value == 'hide calendar') {
                          _showCalendar = false;
                        } else if (value == 'show calendar') {
                          _showCalendar = true;
                        }
                      });
                    },

                    rangeSelectionMode: _rangeSelectionMode,
                    showCalendar: _showCalendar,

                    //);
                    //},
                  );
                }),
          ),
          if (_showCalendar)
            Card(
              child: TableCalendar<TimeInterval>(
                firstDay: kFirstDay,
                lastDay: kLastDay,
                focusedDay: _focusedDayNew,
                headerVisible: false,
                selectedDayPredicate: (day) => _selectedDays.contains(day),
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: _calendarFormat,
                rangeSelectionMode: _rangeSelectionMode,
                eventLoader: _getTimeIntervalsForDay,
                daysOfWeekVisible: true,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: _onDaySelected,
                onRangeSelected: _onRangeSelected,
                onCalendarCreated: (controller) => _pageController = controller,
                //onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
                onPageChanged: (focusedDay) => _focusedDayNew = focusedDay,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                calendarBuilders: //_calendarBuilders,
                CalendarBuilders(
                  markerBuilder: (BuildContext context, date, timeIntervals) {
                    if (timeIntervals.isEmpty) return const SizedBox();
                    return ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: timeIntervals.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(1),
                            child: Container(
                              width: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: timeIntervals[index].color,
                              ),
                            ),
                          );
                        });
                  },
                ),
                //calendarBuilders: calendarBuilders,

                // headerVisible: false,
                // selectedDayPredicate: widget.selectedDayPredicate,
                // rangeStartDay: widget.rangeStart,
                // rangeEndDay: widget.rangeEnd,
                // calendarFormat: widget.calendarFormat,
                // rangeSelectionMode: widget.rangeSelectionMode,
                // eventLoader: widget.getTimeIntervalsForDay,
                // daysOfWeekVisible: true,
                // startingDayOfWeek: StartingDayOfWeek.monday,
                // onDaySelected: widget.onDaySelected,
                // onRangeSelected: widget.onRangeSelected,
                // onCalendarCreated: widget.onCalendarCreated,
                // onPageChanged: widget.onPageChanged,
                // onFormatChanged: widget.onFormatChanged,
                //calendarBuilders: widget.calendarBuilders,
              ),
            ),
          Expanded(
            child: AppScaffold(
              title: 'Selected Events',
              slivers: [
                for (final selectedDay in _selectedDaysList)
                  StickyHeaderList(
                    //controller: DataControllerProvider.of(context).controller,
                    date: selectedDay,
                    index: _selectedDaysList.toList().indexOf(selectedDay),
                    timeIntervals: _selectedTimeIntervalsNew
                        //DataControllerProvider.of(context).controller.getEventsOnDays(widget.selectedDaysSorted)
                        //controller.getEventsOnDays(widget.selectedDaysSorted)
                        .where(
                            (event) => isSameDay(event.startDate, selectedDay))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarHeader extends StatefulWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final void Function(String) onSelectionModeChanged;
  final RangeSelectionMode rangeSelectionMode;
  final bool clearButtonVisible;
  final bool showCalendar;

  const CalendarHeader({
    Key? key,
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.onClearButtonTap,
    required this.clearButtonVisible,
    required this.onSelectionModeChanged,
    required this.rangeSelectionMode,
    required this.showCalendar,
  }) : super(key: key);

  @override
  _CalendarHeaderState createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final headerText =
        DateFormat.yMMM(Localizations.localeOf(context).languageCode)
            .format(widget.focusedDay);

    return
        // Padding(
        // padding: const EdgeInsets.symmetric(vertical: 8.0),
        // child:
        Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Text(
            headerText,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
        if (widget.showCalendar && Platform.isWindows)
          IconButton(
            icon: Icon(Icons.chevron_left_outlined),
            onPressed: widget.onLeftArrowTap,
          ),
        if (widget.showCalendar && Platform.isWindows)
          IconButton(
            icon: Icon(Icons.chevron_right_outlined),
            onPressed: widget.onRightArrowTap,
          ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.calendar_today_outlined),
          //visualDensity: VisualDensity.compact,
          onPressed: widget.onTodayButtonTap,
        ),
        if (widget.clearButtonVisible)
          IconButton(
            icon: Icon(Icons.clear_outlined),
            //visualDensity: VisualDensity.compact,
            onPressed: widget.onClearButtonTap,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.settings_outlined, size: 18.0),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: widget.showCalendar ? 'hide calendar' : 'show calendar',
              child: Text(
                widget.showCalendar
                    ? localizations!.hideCalendar
                    : localizations!.showCalendar,
              ),
            ),
            PopupMenuItem<String>(
              value: 'multi',
              child: Text(
                localizations!.selectMultipleDays,
                style: TextStyle(
                  color:
                      widget.rangeSelectionMode == RangeSelectionMode.toggledOff
                          ? Colors.blue
                          : null,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'range',
              child: Text(
                localizations.selectDateRange,
                style: TextStyle(
                  color:
                      widget.rangeSelectionMode == RangeSelectionMode.toggledOn
                          ? Colors.blue
                          : null,
                ),
              ),
            ),
          ],
          onSelected: widget.onSelectionModeChanged,
        ),
      ],
      //),
    );
  }
}

class StickyHeaderList extends StatefulWidget {
  const StickyHeaderList(
      {Key? key,
      required this.index,
      required this.date,
      required this.timeIntervals,
      this.controller})
      : super(key: key);

  final int index;
  final DateTime date;
  final List<TimeInterval> timeIntervals;
  final DataController? controller;

  @override
  _StickyHeaderListState createState() => _StickyHeaderListState();
}

class _StickyHeaderListState extends State<StickyHeaderList> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.deleteTimeInterval(timeInterval.id);
    setState(() {
      _timeIntervals.remove(timeInterval);
      //_selectedTimeIntervals.value.remove(timeInterval);
    });
  }

  Future<void> _onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval =
        timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    // final index2 = _selectedTimeIntervals.value
    //     .indexWhere((item) => item.id == updatedTimeInterval.id);
    // if (index != -1) {
    //   setState(() {
    //     _timeIntervals[index] = updatedTimeInterval;
    //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
    //   });
    // }

    setState(() {
      _timeIntervals[index] = updatedTimeInterval;
    });
  }

  Future<void> _onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(
      subtasks: timeInterval.subtasks,
    );
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
        await _databaseManager.timeInterval(timeInterval.id);
    final index =
        _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    // final index2 = _selectedTimeIntervals.value
    //     .indexWhere((item) => item.id == updatedTimeInterval.id);
    // if (index != -1) {
    //   setState(() {
    //     _timeIntervals[index] = updatedTimeInterval;
    //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
    //   });
    // }

    setState(() {
      _timeIntervals[index] = updatedTimeInterval;
    });
  }

  Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: timeInterval.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.hasBeenDone),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              TimeInterval _timeInterval = timeInterval.copyWith(
                  howMuchHasBeenDone:
                      double.parse(_hasBeenDoneController.text));
              await _databaseManager.updateTimeInterval(_timeInterval);
              final updatedTimeInterval =
                  await _databaseManager.timeInterval(timeInterval.id);
              final index = _timeIntervals
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              // final index2 = _selectedTimeIntervals.value
              //     .indexWhere((item) => item.id == updatedTimeInterval.id);
              // if (index != -1) {
              //   setState(() {
              //     _timeIntervals[index] = updatedTimeInterval;
              //     _selectedTimeIntervals.value[index2] = updatedTimeInterval;
              //   });
              // }

              setState(() {
                _timeIntervals[index] = updatedTimeInterval;
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  // DataController? _controller;
  // late VoidCallback _reloadCallback;

  /// Reloads page.
  ///
  // void _reload() {
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _reloadCallback = _reload;
  // }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //
  //   final newController =
  //       widget.controller ?? DataControllerProvider.of(context).controller;
  //
  //   if (newController != _controller) {
  //     _controller = newController;
  //
  //     _controller!
  //       // Removes existing callback.
  //       ..removeListener(_reloadCallback)
  //
  //       // Reloads the view if there is any change in controller or
  //       // user adds new events.
  //       ..addListener(_reloadCallback);
  //   }
  // }

  // @override
  // void didUpdateWidget(StickyHeaderList oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Update controller.
  //   final newController =
  //       widget.controller ?? DataControllerProvider.of(context).controller;
  //
  //   if (newController != _controller) {
  //     _controller?.removeListener(_reloadCallback);
  //     _controller = newController;
  //     _controller?.addListener(_reloadCallback);
  //   }
  // }
  //
  // @override
  // void dispose() {
  //   _controller?.removeListener(_reloadCallback);
  //   super.dispose();
  // }
  //
  // DataController get controller {
  //   if (_controller == null) {
  //     throw "EventController is not initialized yet.";
  //   }
  //   return _controller!;
  // }

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      overlapsContent: true,
      header: _SideHeader(
        index: widget.index,
        date: widget.date,
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.only(left: 60),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final event = widget.timeIntervals[i];
              return TimeIntervalCard(
                timeInterval: event,
                onHasBeenDoneUpdate: _onHasBeenDoneUpdate,
                onSubtasksChanged: _onSubtasksChanged,
                onTimeIntervalDelete: _deleteTimeInterval, //(event) => _controller?.remove(
                    //event), //DataControllerProvider.of(context).controller.remove(event) , //
                onTimeIntervalEdit: (TimeInterval timeInterval) async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddOrEditTimeIntervalPage(
                        timeInterval: timeInterval,
                      ),
                      fullscreenDialog: false,
                    ),
                  );
                  final updatedTimeInterval =
                      await _databaseManager.timeInterval(timeInterval.id);
                  final index = _timeIntervals
                      .indexWhere((item) => item.id == updatedTimeInterval.id);
                  // final index2 = _selectedTimeIntervals.value.indexWhere(
                  //         (item) => item.id == updatedTimeInterval.id);
                  // if (index != -1) {
                  //   setState(() {
                  //     _timeIntervals[index] = updatedTimeInterval;
                  //     _selectedTimeIntervals.value[index2] =
                  //         updatedTimeInterval;
                  //   });
                  // }

                  setState(() {
                    _timeIntervals[index] = updatedTimeInterval;
                  });
                },
                onTimeIntervalToggleComplete: (TimeInterval timeInterval) {
                  _onTimeIntervalToggleCompleted(timeInterval);
                },
              );
            },
            childCount: widget.timeIntervals.length,
          ),
        ),
      ),
    );
  }
}

class _SideHeader extends StatelessWidget {
  const _SideHeader({
    Key? key,
    this.index,
    required this.date,
  }) : super(key: key);

  final int? index;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final String todayString = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final String dateString = DateFormat('dd/MM/yyyy').format(date);
    final bool isToday = todayString == dateString;
    final List<String> dateParts = dateString.split('/');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateParts.last,
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
            if (!isToday) ...{
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: dateParts[0], style: TextStyle(fontSize: 13.0)),
                    TextSpan(text: '-', style: TextStyle(fontSize: 13.0)),
                    TextSpan(
                        text: dateParts[1], style: TextStyle(fontSize: 13.0)),
                  ],
                ),
              ),
            } else ...{
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: dateParts[0],
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Colors.blue,
                      ),
                    ),
                    TextSpan(
                        text: '-',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.blue,
                        )),
                    TextSpan(
                        text: dateParts[1],
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.blue,
                        )),
                  ],
                ),
              ),
            },
            // if (isToday) ...{
            //   Text(
            //     'Today',
            //     style: TextStyle(
            //       fontSize: 12.0,
            //       color: Colors.blue,
            //     ),
            //   ),
            // },
          ],
        ),
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    Key? key,
    required this.title,
    required this.slivers,
    this.reverse = false,
  }) : super(key: key);

  final String title;
  final List<Widget> slivers;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return DefaultStickyHeaderController(
      child: Scaffold(
        body: CustomScrollView(
          slivers: slivers,
          reverse: reverse,
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    Key? key,
    this.index,
    this.title,
    this.color = Colors.lightBlue,
  }) : super(key: key);

  final String? title;
  final int? index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('hit $index');
      },
      child: Container(
        height: 60,
        color: color,
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        alignment: Alignment.centerLeft,
        child: Text(
          title ?? 'Header #$index',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
