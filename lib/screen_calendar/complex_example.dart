import 'dart:collection';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/utils/utils.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';

class TableComplexExample extends StatefulWidget {
  const TableComplexExample({super.key});
  @override
  _TableComplexExampleState createState() => _TableComplexExampleState();
}

class _TableComplexExampleState extends State<TableComplexExample> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late final ValueNotifier<List<TimeInterval>> _selectedTimeIntervals;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());

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

  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<TimeInterval> _timeIntervals = [];
  bool _showCalendar = true;

  @override
  void initState() {
    super.initState();
    _init();
    _selectedDays.add(_focusedDay.value);
    _selectedDaysList = _selectedDays.toList()..sort((a, b) => a.compareTo(b));
    _selectedTimeIntervals =
        ValueNotifier(_getTimeIntervalsForDay(_focusedDay.value));
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _selectedTimeIntervals.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final timeIntervals = await _databaseManager.timeIntervals();
    final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
    for (final interval in timeIntervals) {
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
    _timeIntervals = timeIntervals;

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
      if (_selectedDays.contains(selectedDay)) {
        _selectedDays.remove(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }
      _selectedDaysList = _selectedDays.toList()
        ..sort((a, b) => a.compareTo(b));

      _focusedDay.value = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });

    _selectedTimeIntervals.value = _getTimeIntervalsForDays(_selectedDaysList);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _focusedDay.value = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _selectedDays.clear();
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedTimeIntervals.value = _getTimeIntervalsForRange(start, end);
    } else if (start != null) {
      _selectedTimeIntervals.value = _getTimeIntervalsForDay(start);
    } else if (end != null) {
      _selectedTimeIntervals.value = _getTimeIntervalsForDay(end);
    }
  }

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.deleteTimeInterval(timeInterval.id);
    setState(() {
      _timeIntervals.remove(timeInterval);
      _selectedTimeIntervals.value.remove(timeInterval);
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
    final index2 = _selectedTimeIntervals.value
        .indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = updatedTimeInterval;
        _selectedTimeIntervals.value[index2] = updatedTimeInterval;
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
        _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    final index2 = _selectedTimeIntervals.value
        .indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = updatedTimeInterval;
        _selectedTimeIntervals.value[index2] = updatedTimeInterval;
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
              final index = _timeIntervals
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              final index2 = _selectedTimeIntervals.value
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              if (index != -1) {
                setState(() {
                  _timeIntervals[index] = updatedTimeInterval;
                  _selectedTimeIntervals.value[index2] = updatedTimeInterval;
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

  void _onCalendarSelectionModeChanged(String value) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ValueListenableBuilder<DateTime>(
            valueListenable: _focusedDay,
            builder: (context, value, _) {
              return _CalendarHeader(
                focusedDay: value,
                clearButtonVisible: canClearSelection,
                onTodayButtonTap: () {
                  setState(() => _focusedDay.value = DateTime.now());
                },
                onClearButtonTap: () {
                  setState(() {
                    _rangeStart = null;
                    _rangeEnd = null;
                    _selectedDays.clear();
                    _selectedTimeIntervals.value = [];
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
              );
            },
          ),
          if (_showCalendar)
            TableCalendar<TimeInterval>(
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay.value,
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
              onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
            ),
          const SizedBox(height: 8.0),
          const Divider(height: 4,),
          Expanded(
            child: ValueListenableBuilder<List<TimeInterval>>(
              valueListenable: _selectedTimeIntervals,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final timeInterval = value[index];
                    //final timeIntervalColor = value[index].color;
                    // final myColorScheme = Theme.of(context).brightness == Brightness.dark
                    //     ? ColorScheme.dark(primary: timeIntervalColor)
                    //     : ColorScheme.light(primary: timeIntervalColor);
                    //final backgroundColor = myColorScheme.primaryContainer;
                    //final labelColor = contrastColor(backgroundColor);
                    // final textTheme =
                    //     Theme.of(context).textTheme.apply(bodyColor: labelColor);
                    // final String formattedStartDate = timeInterval.startDate != null
                    //     ? DateFormat.yMMMd().format(timeInterval.startDate!)
                    //     : '--/--/----';

                    return TimeIntervalCard(
                      timeInterval: timeInterval,
                      onHasBeenDoneUpdate: _onHasBeenDoneUpdate,
                      onSubtasksChanged: _onSubtasksChanged,
                      onTimeIntervalDelete: _deleteTimeInterval,
                      onTimeIntervalEdit: (TimeInterval timeInterval) async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddOrEditTimeIntervalPage(
                              timeInterval: timeInterval,
                            ),
                            fullscreenDialog: false,
                          ),
                        );
                        final updatedTimeInterval = await _databaseManager
                            .timeInterval(timeInterval.id);
                        final index = _timeIntervals.indexWhere(
                            (item) => item.id == updatedTimeInterval.id);
                        final index2 = _selectedTimeIntervals.value.indexWhere(
                            (item) => item.id == updatedTimeInterval.id);
                        if (index != -1) {
                          setState(() {
                            _timeIntervals[index] = updatedTimeInterval;
                            _selectedTimeIntervals.value[index2] =
                                updatedTimeInterval;
                          });
                        }
                      },
                      onTimeIntervalToggleComplete:
                          (TimeInterval timeInterval) {
                        _onTimeIntervalToggleCompleted(timeInterval);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final void Function(String) onSelectionModeChanged;
  final RangeSelectionMode rangeSelectionMode;
  final bool clearButtonVisible;
  final bool showCalendar;

  const _CalendarHeader({
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final headerText =
        DateFormat.yMMM(Localizations.localeOf(context).languageCode)
            .format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          SizedBox(
            width: 120.0,
            child: Text(
              headerText,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 18.0),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
          ),
          if (clearButtonVisible)
            IconButton(
              icon: const Icon(Icons.clear, size: 18.0),
              visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_outlined, size: 18.0),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: showCalendar ? 'hide calendar' : 'show calendar',
                child: Text(
                  showCalendar
                      ? localizations!.hideCalendar
                      : localizations!.showCalendar,
                ),
              ),
              PopupMenuItem<String>(
                value: 'multi',
                child: Text(
                  localizations!.selectMultipleDays,
                  style: TextStyle(
                    color: rangeSelectionMode == RangeSelectionMode.toggledOff
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
                    color: rangeSelectionMode == RangeSelectionMode.toggledOn
                        ? Colors.blue
                        : null,
                  ),
                ),
              ),
            ],
            onSelected: onSelectionModeChanged,
          ),
          const Spacer(),
          if (showCalendar)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onLeftArrowTap,
            ),
          if (showCalendar)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onRightArrowTap,
            ),
        ],
      ),
    );
  }
}
