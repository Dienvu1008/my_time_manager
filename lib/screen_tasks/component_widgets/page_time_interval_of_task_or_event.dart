import 'dart:collection';
import 'dart:ui';

import 'package:calendar_widgets/src_sticky_header/widgets/sliver_sticky_header.dart';
import 'package:calendar_widgets/src_table_calendar/customization/calendar_builders.dart';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';

import '../../app/app_localizations.dart';
import '../../data/database/database_manager.dart';
import '../../data/models/model_list.dart';
import '../../data/models/model_measurable_task.dart';
import '../../data/models/model_task.dart';
import '../../data/models/model_task_with_subtasks.dart';
import '../../data/models/model_time_interval.dart';
import '../../home/component_widgets/button_select_calendar_mode.dart';
import '../../home/component_widgets/button_show_timeline_calendar.dart';
import '../../utils/utils.dart';

class TimeIntervalOfTaskOrEventPageNew extends StatefulWidget {
  const TimeIntervalOfTaskOrEventPageNew(
      {super.key,
      this.taskId,
      this.measurableTaskId,
      this.taskWithSubtasksId,
      required this.showCalendar,
      required this.timeIntervalsOfThisTask});

  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  final List<TimeInterval> timeIntervalsOfThisTask;
  final bool showCalendar;

  @override
  _TimeIntervalOfTaskOrEventPageNewState createState() =>
      _TimeIntervalOfTaskOrEventPageNewState();
}

class _TimeIntervalOfTaskOrEventPageNewState
    extends State<TimeIntervalOfTaskOrEventPageNew> {
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
  void dispose() {
    _focusedDay.dispose();
    _selectedTimeIntervals.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timeIntervals = widget.timeIntervalsOfThisTask;
    _initData();
    //_loadData();
    // setState(() {
    _selectedDays.add(_focusedDay.value);
    _selectedDaysList = _selectedDays.toList()..sort((a, b) => a.compareTo(b));
    _selectedTimeIntervals =
        ValueNotifier(_getTimeIntervalsForDay(_focusedDay.value));
    // });
  }

  _initData() {
    final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
    for (final interval in _timeIntervals) {
      final date = (interval.startDate != null)
          ? DateTime(interval.startDate!.year, interval.startDate!.month,
              interval.startDate!.day)
          : DateTime(interval.endDate!.year, interval.endDate!.month,
              interval.endDate!.day);

      if (kTimeIntervalSource.containsKey(date)) {
        kTimeIntervalSource[date]!.add(interval);

        // Sắp xếp các TimeInterval theo startTime
        kTimeIntervalSource[date]!.sort((a, b) {
          if (a.startTime == null) return -1;
          if (b.startTime == null) return 1;
          if (a.startTime != null && b.startTime != null) {
            final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
            final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
            return aMinutes.compareTo(bMinutes);
          }
          return 0;
        });
      } else {
        kTimeIntervalSource[date] = [interval];
      }
    }

    _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(kTimeIntervalSource);
  }

  Future<void> _loadData() async {
    if (widget.taskId != null) {
      final timeIntervals =
          await _databaseManager.timeIntervalsOfTask(widget.taskId!);
      final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
      for (final interval in timeIntervals) {
        final date = (interval.startDate != null)
            ? DateTime(interval.startDate!.year, interval.startDate!.month,
                interval.startDate!.day)
            : DateTime(interval.endDate!.year, interval.endDate!.month,
                interval.endDate!.day);

        if (kTimeIntervalSource.containsKey(date)) {
          kTimeIntervalSource[date]!.add(interval);

          // Sắp xếp các TimeInterval theo startTime
          kTimeIntervalSource[date]!.sort((a, b) {
            if (a.startTime == null) return -1;
            if (b.startTime == null) return 1;
            if (a.startTime != null && b.startTime != null) {
              final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
              final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
              return aMinutes.compareTo(bMinutes);
            }
            return 0;
          });
        } else {
          kTimeIntervalSource[date] = [interval];
        }

        _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
          equals: isSameDay,
          hashCode: getHashCode,
        )..addAll(kTimeIntervalSource);
        _timeIntervals = timeIntervals;
      }
    } else if (widget.measurableTaskId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfMeasureableTask(widget.measurableTaskId!);
      final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
      for (final interval in timeIntervals) {
        final date = (interval.startDate != null)
            ? DateTime(interval.startDate!.year, interval.startDate!.month,
                interval.startDate!.day)
            : DateTime(interval.endDate!.year, interval.endDate!.month,
                interval.endDate!.day);

        if (kTimeIntervalSource.containsKey(date)) {
          kTimeIntervalSource[date]!.add(interval);

          // Sắp xếp các TimeInterval theo startTime
          kTimeIntervalSource[date]!.sort((a, b) {
            if (a.startTime == null) return -1;
            if (b.startTime == null) return 1;
            if (a.startTime != null && b.startTime != null) {
              final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
              final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
              return aMinutes.compareTo(bMinutes);
            }
            return 0;
          });
        } else {
          kTimeIntervalSource[date] = [interval];
        }

        _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
          equals: isSameDay,
          hashCode: getHashCode,
        )..addAll(kTimeIntervalSource);

        _timeIntervals = timeIntervals;
      }
    } else if (widget.taskWithSubtasksId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfTaskWithSubtasks(widget.taskWithSubtasksId!);
      final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
      for (final interval in timeIntervals) {
        final date = (interval.startDate != null)
            ? DateTime(interval.startDate!.year, interval.startDate!.month,
                interval.startDate!.day)
            : DateTime(interval.endDate!.year, interval.endDate!.month,
                interval.endDate!.day);

        if (kTimeIntervalSource.containsKey(date)) {
          kTimeIntervalSource[date]!.add(interval);

          // Sắp xếp các TimeInterval theo startTime
          kTimeIntervalSource[date]!.sort((a, b) {
            if (a.startTime == null) return -1;
            if (b.startTime == null) return 1;
            if (a.startTime != null && b.startTime != null) {
              final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
              final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
              return aMinutes.compareTo(bMinutes);
            }
            return 0;
          });
        } else {
          kTimeIntervalSource[date] = [interval];
        }

        _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
          equals: isSameDay,
          hashCode: getHashCode,
        )..addAll(kTimeIntervalSource);
        _timeIntervals = timeIntervals;
      }
    }
  }

  bool get canClearSelection =>
      _selectedDays.isNotEmpty || _rangeStart != null || _rangeEnd != null;

  List<TimeInterval> _getTimeIntervalsForDay(DateTime day) {
    //_loadData();
    return _kTimeIntervals[day] ?? [];
  }

  List<TimeInterval> _getTimeIntervalsForDays(Iterable<DateTime> days) {
    //_loadData();
    return [
      for (final d in days) ..._getTimeIntervalsForDay(d),
    ];
  }

  List<TimeInterval> _getTimeIntervalsForRange(DateTime start, DateTime end) {
    //_loadData();
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
      _selectedTimeIntervals.value =
          _getTimeIntervalsForDays(_selectedDaysList);
    });

    _selectedTimeIntervals.value = _getTimeIntervalsForDays(_selectedDaysList);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    //_loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.showCalendar)
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
                  handleCalendarVisibilityChange: () => setState(() {
                    _showCalendar = !_showCalendar;
                  }),
                );
              },
            ),
          if (widget.showCalendar)
            Card(
              child: TableCalendar<TimeInterval>(
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
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (BuildContext context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(1),
                          child: Container(
                            width: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: events[index].color,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: ValueListenableBuilder<List<TimeInterval>>(
              valueListenable: _selectedTimeIntervals,
              builder: (context, value, _) {
                return AppScaffold(
                  title: 'Selected Events',
                  slivers: [
                    for (final selectedDay in _selectedDaysList)
                      StickyHeaderList(
                        date: selectedDay,
                        index: _selectedDaysList.toList().indexOf(selectedDay),
                        timeIntervals: _selectedTimeIntervals.value
                            .where((event) =>
                                isSameDay(event.startDate, selectedDay))
                            .toList(),
                        deleteTimeInterval: (TimeInterval timeInterval) {
                          _deleteTimeInterval(timeInterval);
                        },
                        onTimeIntervalToggleCompleted:
                            (TimeInterval timeInterval) {
                          _onTimeIntervalToggleCompleted(timeInterval);
                        },
                        onSubtasksChanged: (TimeInterval timeInterval) {
                          _onSubtasksChanged(timeInterval);
                        },
                        onHasBeenDoneUpdate: (TimeInterval timeInterval) {
                          _onHasBeenDoneUpdate(timeInterval);
                        },
                      ),
                  ],
                );
              },
            ),
          )
        ],
      ),
      // floatingActionButton:
      //     FloatingActionButton.small(
      //       onPressed: () async {
      //         final timeInterval = await showDialog<TimeInterval>(
      //           context: context,
      //           builder: (context) => SetTimeIntervalPage(
      //             taskId: widget.taskId,
      //             measurableTaskId: widget.measurableTaskId,
      //             taskWithSubtasksId:
      //             widget.taskWithSubtasksId,
      //           ),
      //         );
      //
      //     }, child: Icon(Icons.add)),
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
  final void Function() handleCalendarVisibilityChange;

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
    required this.handleCalendarVisibilityChange,
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
          if (showCalendar)
            SizedBox(
              width: 80.0,
              child: Text(
                headerText,
              ),
            ),
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
          if (showCalendar)
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              //visualDensity: VisualDensity.compact,
              onPressed: onTodayButtonTap,
            ),
          if (clearButtonVisible)
            IconButton(
              icon: const Icon(Icons.clear_outlined),
              //visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          const Spacer(),
          MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: const Icon(Icons.more_vert_outlined),
                );
              },
              menuChildren: [
                // ShowHideCalendarMenuItemButton(
                //   handleCalendarVisibilityChange:
                //       handleCalendarVisibilityChange,
                //   showCalendar: showCalendar,
                // ),
                CalendarModeSubmenuButton(
                  handleSelectionModeChange: onSelectionModeChanged,
                  rangeSelectionMode: rangeSelectionMode,
                ),
              ]),
        ],
      ),
    );
  }
}

class StickyHeaderList extends StatefulWidget {
  const StickyHeaderList({
    Key? key,
    required this.index,
    required this.date,
    required this.timeIntervals,
    required this.deleteTimeInterval,
    required this.onTimeIntervalToggleCompleted,
    required this.onSubtasksChanged,
    required this.onHasBeenDoneUpdate,
  }) : super(key: key);

  final int index;
  final DateTime date;
  final List<TimeInterval> timeIntervals;
  final Function(TimeInterval) deleteTimeInterval;
  final Function(TimeInterval) onTimeIntervalToggleCompleted;
  final Function(TimeInterval) onSubtasksChanged;
  final Function(TimeInterval) onHasBeenDoneUpdate;

  @override
  _StickyHeaderListState createState() => _StickyHeaderListState();
}

class _StickyHeaderListState extends State<StickyHeaderList> {
  final DatabaseManager _databaseManager = DatabaseManager();

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
              return TimeIntervalCardNew(
                timeInterval: event,
                onHasBeenDoneUpdate: widget.onHasBeenDoneUpdate,
                onSubtasksChanged: widget.onSubtasksChanged,
                onTimeIntervalDelete: widget.deleteTimeInterval,
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
                  setState(() {
                    widget.timeIntervals[i] = updatedTimeInterval;
                  });
                },
                onTimeIntervalToggleComplete:
                    widget.onTimeIntervalToggleCompleted,
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
                      // style: TextStyle(
                      //   fontSize: 13.0,
                      //   color: Colors.blue,
                      // ),
                    ),
                    TextSpan(
                      text: '-',
                      // style: TextStyle(
                      //   fontSize: 13.0,
                      //   color: Colors.blue,
                      // ),
                    ),
                    TextSpan(
                      text: dateParts[1],
                      // style: TextStyle(
                      //   fontSize: 13.0,
                      //   color: Colors.blue,
                      // ),
                    ),
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

class TimeIntervalCardNew extends StatefulWidget {
  final TimeInterval timeInterval;
  final Function(TimeInterval) onTimeIntervalEdit;
  final Function(TimeInterval) onTimeIntervalDelete;
  final Function(TimeInterval) onTimeIntervalToggleComplete;
  final Function(TimeInterval) onSubtasksChanged;
  final Function(TimeInterval) onHasBeenDoneUpdate;

  const TimeIntervalCardNew({
    Key? key,
    required this.timeInterval,
    required this.onTimeIntervalEdit,
    required this.onTimeIntervalDelete,
    required this.onTimeIntervalToggleComplete,
    required this.onSubtasksChanged,
    required this.onHasBeenDoneUpdate,
  }) : super(key: key);

  @override
  _TimeIntervalCardNewState createState() => _TimeIntervalCardNewState();
}

class _TimeIntervalCardNewState extends State<TimeIntervalCardNew> {
  bool _isExpanded = false;
  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';

  @override
  void initState() {
    super.initState();
    //_loadIsExpanded();
  }

  // void _loadIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final isExpanded =
  //       prefs.getBool('isExpanded_${widget.timeInterval.id}') ?? true;
  //   if (mounted) {
  //     setState(() {
  //       _isExpanded = isExpanded;
  //     });
  //   }
  // }

  // void _saveIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setBool('isExpanded_${widget.timeInterval.id}', _isExpanded);
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final timeIntervalColor = widget.timeInterval.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: timeIntervalColor)
        : ColorScheme.light(primary: timeIntervalColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    final textTheme = Theme.of(context).textTheme;

    if (widget.timeInterval.startDate != null) {
      _formattedStartDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval.startDate!);
    } else {
      _formattedStartDate = '--/--/----';
    }

    if (widget.timeInterval.startTime != null) {
      _formattedStartTime = widget.timeInterval.startTime!.format(context);
    } else {
      _formattedStartTime = '--:--';
    }

    if (widget.timeInterval.endDate != null) {
      _formattedEndDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval.endDate!);
    } else {
      _formattedEndDate = '--/--/----';
    }

    if (widget.timeInterval.endTime != null) {
      _formattedEndTime = widget.timeInterval.endTime!.format(context);
    } else {
      _formattedEndTime = '--:--';
    }

    return Card(
      //color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onTimeIntervalEdit(widget.timeInterval),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(right:0, left: 8),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8.0,
                          children: <Widget>[
                            if (widget.timeInterval.isGone == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  localizations!.gone,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            if (widget.timeInterval.isInProgress == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  localizations!.inProgress,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            style: widget.timeInterval.isCompleted
                                ? textTheme.labelLarge!.copyWith(
                                    decoration: TextDecoration.lineThrough)
                                : textTheme.labelLarge,
                            text: _formattedStartDate == _formattedEndDate
                                ? '$_formattedStartTime ${localizations!.to} $_formattedEndTime'
                                : '$_formattedStartTime ${localizations!.to} $_formattedEndDate: $_formattedEndTime',
                          ),
                        ),
                      ],
                    ),
                    // subtitle: _isExpanded
                    //     ? Column(
                    //         children: [
                    //           if (widget.timeInterval.description.isNotEmpty)
                    //             Row(
                    //               children: [
                    //                 const Icon(Icons.description_outlined),
                    //                 const SizedBox(width: 10),
                    //                 Expanded(
                    //                   child: Text(
                    //                       widget.timeInterval.description,
                    //                       style: textTheme.labelMedium!),
                    //                 )
                    //               ],
                    //             ),
                    //           if (widget.timeInterval.location.isNotEmpty)
                    //             Row(
                    //               children: [
                    //                 const Icon(Icons.location_on_outlined),
                    //                 const SizedBox(width: 10),
                    //                 Expanded(
                    //                   child: Text(widget.timeInterval.location,
                    //                       style: textTheme.labelMedium!),
                    //                 ),
                    //               ],
                    //             ),
                    //           if (widget.timeInterval.measurableTaskId !=
                    //                   null &&
                    //               widget.timeInterval.targetType ==
                    //                   TargetType.about)
                    //             Text(
                    //                 '${localizations.targetAbout} ${widget.timeInterval.targetAtLeast} ${localizations.to} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                    //                 style: textTheme.labelMedium!),
                    //           if (widget.timeInterval.measurableTaskId !=
                    //                   null &&
                    //               widget.timeInterval.targetType ==
                    //                   TargetType.atLeast)
                    //             Text(
                    //                 '${localizations.targetAtLeast} ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                    //                 style: textTheme.labelMedium!),
                    //           if (widget.timeInterval.measurableTaskId !=
                    //                   null &&
                    //               widget.timeInterval.targetType ==
                    //                   TargetType.atMost)
                    //             Text(
                    //                 '${localizations.targetAtMost} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                    //                 style: textTheme.labelMedium!),
                    //           if (widget.timeInterval.measurableTaskId != null)
                    //             Center(
                    //               child: ActionChip(
                    //                 label: Text(
                    //                     '${localizations.hasBeenDone} ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                    //                     style: textTheme.labelMedium!),
                    //                 onPressed: () => setState(
                    //                   () {
                    //                     widget.onHasBeenDoneUpdate(
                    //                         widget.timeInterval);
                    //                   },
                    //                 ),
                    //               ),
                    //             ),
                    //         ],
                    //       )
                    //     : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_outlined,
                      ),
                      onSelected: (String result) async {
                        if (result == 'sync_from_task') {
                          showComingSoonDialog(context);
                        } else if (result == 'delete_time_interval') {
                          widget.onTimeIntervalDelete(widget.timeInterval);
                        } else if (result == 'option3') {
                          widget.onTimeIntervalToggleComplete(
                              widget.timeInterval);
                        } else if (result == 'go_to_main_task') {
                          final DatabaseManager databaseManager =
                              DatabaseManager();
                          if (widget.timeInterval.taskWithSubtasksId != null) {
                            final id = widget.timeInterval.taskWithSubtasksId;
                            final TaskWithSubtasks taskWithSubtasks =
                                await databaseManager.taskWithSubtasks(id!);
                            final TaskList taskList = await databaseManager
                                .taskList(taskWithSubtasks.taskListId);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddOrEditTaskWithSubtasksPage(
                                  taskList: taskList,
                                  taskWithSubtasks: taskWithSubtasks,
                                ),
                              ),
                            );
                          } else if (widget.timeInterval.measurableTaskId !=
                              null) {
                            final id = widget.timeInterval.measurableTaskId;
                            final MeasurableTask measurableTask =
                                await databaseManager.measurableTask(id!);
                            final TaskList taskList = await databaseManager
                                .taskList(measurableTask.taskListId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddOrEditMeasurableTaskPage(
                                  taskList: taskList,
                                  measurableTask: measurableTask,
                                ),
                              ),
                            );
                          } else if (widget.timeInterval.taskId != null) {
                            final id = widget.timeInterval.taskId;
                            final Task task = await databaseManager.task(id!);
                            final TaskList taskList =
                                await databaseManager.taskList(task.taskListId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddOrEditTaskPage(
                                  taskList: taskList,
                                  task: task,
                                ),
                              ),
                            );
                          }
                        } else if (result == 'option5') {
                          setState(() => _isExpanded = !_isExpanded);
                          //_saveIsExpanded();
                          //widget.onSubtasksDisplayChanged;
                        } else if (result == 'option6') {
                          setState(() => _isExpanded = !_isExpanded);
                          //_saveIsExpanded();
                          //widget.onSubtasksDisplayChanged;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        if (widget.timeInterval.taskWithSubtasksId != null)
                          PopupMenuItem<String>(
                            value: 'option5',
                            child: Row(
                              children: [
                                Icon(_isExpanded
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded
                                    ? Text(localizations.hideSubTasks)
                                    : Text(localizations.showSubTasks),
                              ],
                            ),
                          ),
                        if (widget.timeInterval.measurableTaskId != null)
                          PopupMenuItem<String>(
                            value: 'option6',
                            child: Row(
                              children: [
                                Icon(_isExpanded
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded
                                    ? Text(localizations.hideTargetInfor)
                                    : Text(localizations.showTargetInfor),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'option3',
                          child: Row(
                            children: [
                              Icon(widget.timeInterval.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.timeInterval.isCompleted
                                  ? Expanded(
                                      child: Text(localizations
                                          .markAsIncompletedInThisTimeInterval))
                                  : Expanded(
                                      child: Text(localizations
                                          .markAsCompletedInThisTimeInterval),
                                    )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'sync_from_task',
                          child: Row(
                            children: [
                              const Icon(Icons.copy_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations
                                    .syncDetailsFromTaskToThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'go_to_main_task',
                          child: Row(
                            children: [
                              const Icon(Icons.read_more_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.goToMainTask),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(localizations.editThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete_time_interval',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    Text(localizations.deleteThisTimeInterval),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded &&
                      (widget.timeInterval.measurableTaskId != null ||
                          widget.timeInterval.description.isNotEmpty ||
                          widget.timeInterval.location.isNotEmpty))
                    ListTile(
                        title: Column(
                      children: [
                        if (widget.timeInterval.description.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.description_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(widget.timeInterval.description,
                                    style: textTheme.labelMedium!),
                              )
                            ],
                          ),
                        if (widget.timeInterval.location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(widget.timeInterval.location,
                                    style: textTheme.labelMedium!),
                              ),
                            ],
                          ),
                        if (widget.timeInterval.measurableTaskId != null &&
                            widget.timeInterval.targetType == TargetType.about)
                          Text(
                              '${localizations.targetAbout} ${widget.timeInterval.targetAtLeast} ${localizations.to} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!),
                        if (widget.timeInterval.measurableTaskId != null &&
                            widget.timeInterval.targetType ==
                                TargetType.atLeast)
                          Text(
                              '${localizations.targetAtLeast} ${widget.timeInterval.targetAtLeast} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!),
                        if (widget.timeInterval.measurableTaskId != null &&
                            widget.timeInterval.targetType == TargetType.atMost)
                          Text(
                              '${localizations.targetAtMost} ${widget.timeInterval.targetAtMost} ${widget.timeInterval.unit}',
                              style: textTheme.labelMedium!),
                        if (widget.timeInterval.measurableTaskId != null)
                          Center(
                            child: ActionChip(
                              label: Text(
                                  '${localizations.hasBeenDone} ${widget.timeInterval.howMuchHasBeenDone} ${widget.timeInterval.unit}',
                                  style: textTheme.labelMedium!),
                              onPressed: () => setState(
                                () {
                                  widget
                                      .onHasBeenDoneUpdate(widget.timeInterval);
                                },
                              ),
                            ),
                          ),
                      ],
                    )),
                  if (_isExpanded &&
                      widget.timeInterval.taskWithSubtasksId != null)
                    SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          ...widget.timeInterval.subtasks.map(
                            (subtask) => CheckboxListTile(
                              contentPadding: const EdgeInsets.only(right:0, left: 8),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: subtask.isSubtaskCompleted,
                              onChanged: (value) {
                                setState(() {
                                  subtask.isSubtaskCompleted = value ?? false;
                                  widget.onSubtasksChanged(widget.timeInterval);
                                });
                              },
                              title: Text(subtask.title,
                                  style: subtask.isSubtaskCompleted
                                      ? textTheme.labelMedium!.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough)
                                      : textTheme.labelMedium!.copyWith(
                                          decoration: TextDecoration.none)),
                              secondary: IconButton(
                                icon: const Icon(
                                  Icons.delete_outlined,
                                ),
                                onPressed: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            Text(localizations.deleteSubtask),
                                        content: Text(localizations
                                            .areYouSureYouWantToDeleteThisSubtask),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(localizations.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(localizations.delete),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (result == true) {
                                    widget.timeInterval.subtasks
                                        .remove(subtask);
                                    widget
                                        .onSubtasksChanged(widget.timeInterval);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
