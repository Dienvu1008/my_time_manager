import 'dart:collection';
import 'dart:io';

import 'dart:math';
import 'package:calendar_widgets/src_sticky_header/widgets/sliver_sticky_header.dart';
import 'package:calendar_widgets/src_table_calendar/customization/calendar_builders.dart';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/home/data_controller_provider.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';

import '../home/component_widgets/button_brightness.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';
import '../home/component_widgets/button_material3.dart';
import '../home/component_widgets/button_select_calendar_mode.dart';
import '../home/component_widgets/button_show_timeline_calendar.dart';
import '../home/component_widgets/button_use_bottom_bar.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

class TableComplexExample extends StatefulWidget {
  final List<TimeInterval> timeIntervals;

  final Function handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function(int) handleColorSelect;
  final bool useBottomBar;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  final bool showBrightnessButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;

  TableComplexExample({
    super.key,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleUsingBottomBarChange,
    required this.useBottomBar,
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.handleLanguageSelect,
    required this.languageSelected,
    required this.showBrightnessButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.timeIntervals,
  });
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

    _timeIntervals = widget.timeIntervals;

    _initData();

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

  // Future<void> _loadData() async {
  //   final timeIntervals = await _databaseManager.timeIntervals();
  //   final kTimeIntervalSource = <DateTime, List<TimeInterval>>{};
  //   for (final interval in timeIntervals) {
  //     final date = (interval.startDate != null)
  //         ? DateTime(interval.startDate!.year, interval.startDate!.month,
  //             interval.startDate!.day)
  //         : DateTime(interval.endDate!.year, interval.endDate!.month,
  //             interval.endDate!.day);
  //
  //     if (kTimeIntervalSource.containsKey(date)) {
  //       kTimeIntervalSource[date]!.add(interval);
  //
  //       // Sắp xếp các TimeInterval theo startTime
  //       kTimeIntervalSource[date]!.sort((a, b) {
  //         if (a.startTime == null) return -1;
  //         if (b.startTime == null) return 1;
  //         if (a.startTime != null && b.startTime != null) {
  //           final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
  //           final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
  //           return aMinutes.compareTo(bMinutes);
  //         }
  //         return 0;
  //       });
  //     } else {
  //       kTimeIntervalSource[date] = [interval];
  //     }
  //   }
  //
  //   _kTimeIntervals = LinkedHashMap<DateTime, List<TimeInterval>>(
  //     equals: isSameDay,
  //     hashCode: getHashCode,
  //   )..addAll(kTimeIntervalSource);
  //
  //   _timeIntervals = timeIntervals;
  // }

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
    return Expanded(
      child: Column(
        children: [
          AppBar(
              title: ValueListenableBuilder<DateTime>(
                valueListenable: _focusedDay,
                builder: (context, value, _) {
                  return _CalendarHeader(
                    focusedDay: value,
                    //focusedDay: _focusedDayNew,
                    clearButtonVisible: canClearSelection,
                    onTodayButtonTap: () {
                      setState(() => _focusedDay.value = DateTime.now());
                      //setState(() => _focusedDayNew = DateTime.now());
                    },
                    onClearButtonTap: () {
                      setState(() {
                        _rangeStart = null;
                        _rangeEnd = null;
                        _selectedDays.clear();
                        _selectedTimeIntervals.value = [];
                        //_selectedTimeIntervalsNew = [];
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
              actions: [
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
                    ShowHideCalendarMenuItemButton(
                      handleCalendarVisibilityChange: () => setState(() {
                        _showCalendar = !_showCalendar;
                      }),
                      showCalendar: _showCalendar,
                    ),
                    if (_showCalendar)
                      CalendarModeSubmenuButton(
                        handleSelectionModeChange: (String value) {
                          setState(
                            () {
                              if (value == 'multi') {
                                _rangeSelectionMode =
                                    RangeSelectionMode.toggledOff;
                              } else if (value == 'range') {
                                _rangeSelectionMode =
                                    RangeSelectionMode.toggledOn;
                              }
                            },
                          );
                        },
                        rangeSelectionMode: _rangeSelectionMode,
                      ),
                    if (widget.showBrightnessButtonInAppBar)
                      BrightnessMenuItemButton(
                        handleBrightnessChange: widget.handleBrightnessChange,
                      ),
                    if (widget.showMaterialDesignButtonInAppBar)
                      Material3MenuItemButton(
                        handleMaterialVersionChange:
                            widget.handleMaterialVersionChange,
                      ),
                    //if(widget.s)
                    UsingBottomBarMenuItemButton(
                        handleUsingBottomBarChange:
                            widget.handleUsingBottomBarChange,
                        useBottomBar: widget.useBottomBar),
                    if (widget.showColorSeedButtonInAppBar)
                      ColorSeedSubmenuButton(
                        handleColorSelect: widget.handleColorSelect,
                        colorSelected: widget.colorSelected,
                        colorSelectionMethod: widget.colorSelectionMethod,
                      ),
                    if (widget.showColorImageButtonInAppBar)
                      ColorImageSubmenuButton(
                        handleImageSelect: widget.handleImageSelect,
                        imageSelected: widget.imageSelected,
                        colorSelectionMethod: widget.colorSelectionMethod,
                      ),
                    if (widget.showLanguagesButtonInAppBar)
                      LanguageSubmenuButton(
                        handleLanguageSelect: widget.handleLanguageSelect,
                        languageSelected: widget.languageSelected,
                      ),
                  ],
                ),
              ]),
          if (_showCalendar)
            Card(
              child: TableCalendar<TimeInterval>(
                firstDay: kFirstDay,
                lastDay: kLastDay,
                focusedDay: _focusedDay.value,
                //focusedDay: _focusedDayNew,
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
                //onPageChanged: (focusedDay) => _focusedDayNew = focusedDay,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() => _calendarFormat = format);
                  }
                },
                calendarBuilders:
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
                      },
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: AppScaffold(
              title: 'Selected Events',
              slivers: [
                for (final selectedDay in _selectedDaysList)
                  StickyHeaderList(
                    date: selectedDay,
                    index: _selectedDaysList.toList().indexOf(selectedDay),
                    timeIntervals: _selectedTimeIntervals.value
                        //_selectedTimeIntervalsNew
                        .where(
                            (event) => isSameDay(event.startDate, selectedDay))
                        .toList(),
                    deleteTimeInterval: (TimeInterval timeInterval) {
                      _deleteTimeInterval(timeInterval);
                    },
                    onTimeIntervalToggleCompleted: (TimeInterval timeInterval) {
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
          //const SizedBox(width: 16.0),
          SizedBox(
            width: 120.0,
            child: Text(
              headerText,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
          if (showCalendar)
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              //visualDensity: VisualDensity.compact,
              onPressed: onTodayButtonTap,
            ),
          if (clearButtonVisible && showCalendar)
            IconButton(
              icon: const Icon(Icons.clear_outlined),
              //visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.settings_outlined),
          //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          //     PopupMenuItem<String>(
          //       value: showCalendar ? 'hide calendar' : 'show calendar',
          //       child: Text(
          //         showCalendar
          //             ? localizations!.hideCalendar
          //             : localizations!.showCalendar,
          //       ),
          //     ),
          //     PopupMenuItem<String>(
          //       value: 'multi',
          //       child: Text(
          //         localizations!.selectMultipleDays,
          //         style: TextStyle(
          //           color: rangeSelectionMode == RangeSelectionMode.toggledOff
          //               ? Colors.blue
          //               : null,
          //         ),
          //       ),
          //     ),
          //     PopupMenuItem<String>(
          //       value: 'range',
          //       child: Text(
          //         localizations.selectDateRange,
          //         style: TextStyle(
          //           color: rangeSelectionMode == RangeSelectionMode.toggledOn
          //               ? Colors.blue
          //               : null,
          //         ),
          //       ),
          //     ),
          //   ],
          //   onSelected: onSelectionModeChanged,
          // ),
          const Spacer(),
          if (showCalendar && Platform.isWindows)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onLeftArrowTap,
            ),
          if (showCalendar && Platform.isWindows)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onRightArrowTap,
            ),
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
              return TimeIntervalCard(
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
