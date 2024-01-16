import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_alarm.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_repeat.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_set_time_intervals_block.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_timezone.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import 'package:my_time_manager/utils/constants.dart';

class ShowOrSetTimeIntervalsBottomSheet extends StatefulWidget {
  const ShowOrSetTimeIntervalsBottomSheet(
      {super.key,
      this.taskId,
      this.measurableTaskId,
      this.taskWithSubtasksId,
      required this.isSetTimeIntervalPage,
      required this.title,
      required this.color,
      required this.description,
      required this.location,
      required this.targetType,
      required this.targetAtLeast,
      required this.targetAtMost,
      required this.subtasks,
      required this.unit});

  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  final bool isSetTimeIntervalPage;
  final String title;
  final Color color;
  final String description;
  final String location;
  final TargetType targetType;
  final double targetAtLeast;
  final double targetAtMost;
  final String unit;
  final List<Subtask> subtasks;

  @override
  _ShowOrSetTimeIntervalsBottomSheetState createState() =>
      _ShowOrSetTimeIntervalsBottomSheetState();
}

class _ShowOrSetTimeIntervalsBottomSheetState
    extends State<ShowOrSetTimeIntervalsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSetTimeIntervalPage = false;
  ValueNotifier<String> _selectedTimeIntervalsNotifier =
      ValueNotifier<String>('all');

  final GlobalKey<_SetTimeIntervalPageState> key = GlobalKey();
  final DatabaseManager _databaseManager = DatabaseManager();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
    _isSetTimeIntervalPage = widget.isSetTimeIntervalPage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Color contrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color labelColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: widget.color)
        : ColorScheme.light(primary: widget.color);
    final backgroundColor = myColorScheme.primaryContainer;
    final titleTextColor = contrastColor(backgroundColor);
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            heightFactor: _animation.value,
            child: DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                maxChildSize: 1,
                minChildSize: 0.6,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Column(
                    children: <Widget>[
                      Container(
                        color: widget.color,
                        child: GestureDetector(
                          child: ListTile(
                            title: Text(
                              widget.title,
                              style: TextStyle(color: titleTextColor),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: widget.color,
                                  //title: Text('Dialog Title'),
                                  content: SingleChildScrollView(
                                    //child: Container(
                                    //color: widget.color,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            widget.title,
                                            style: TextStyle(
                                                color: titleTextColor),
                                          ),
                                        ),
                                        if (widget.description.isNotEmpty)
                                          ListTile(
                                            dense: true,
                                            leading: Icon(
                                                Icons.description_outlined,
                                                color: titleTextColor),
                                            title: Text(
                                              widget.description,
                                              style: TextStyle(
                                                  color: titleTextColor),
                                            ),
                                          ),
                                        if (widget.location.isNotEmpty)
                                          ListTile(
                                            dense: true,
                                            leading: Icon(
                                                Icons.location_on_outlined,
                                                color: titleTextColor),
                                            title: Text(
                                              widget.location,
                                              style: TextStyle(
                                                  color: titleTextColor),
                                            ),
                                          ),
                                        if (widget.measurableTaskId != null)
                                          ListTile(
                                            dense: true,
                                            title: Column(
                                              children: [
                                                if (widget.targetType ==
                                                    TargetType.about)
                                                  Text(
                                                    'Target: about ${widget.targetAtLeast} to ${widget.targetAtMost} ${widget.unit}',
                                                    style: TextStyle(
                                                        color: titleTextColor),
                                                  ),
                                                if (widget.targetType ==
                                                    TargetType.atLeast)
                                                  Text(
                                                    'Target: at least ${widget.targetAtLeast} ${widget.unit}',
                                                    style: TextStyle(
                                                        color: titleTextColor),
                                                  ),
                                                if (widget.targetType ==
                                                    TargetType.atMost)
                                                  Text(
                                                    'Target: at most ${widget.targetAtMost} ${widget.unit}',
                                                    style: TextStyle(
                                                        color: titleTextColor),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        if (widget.taskWithSubtasksId != null)
                                          ...widget.subtasks.map(
                                            (subtask) => ListTile(
                                                dense: true,
                                                leading: Icon(
                                                    subtask.isSubtaskCompleted
                                                        ? Icons.check_box
                                                        : Icons
                                                            .check_box_outline_blank,
                                                    color: titleTextColor),
                                                title: Text(
                                                  subtask.title,
                                                  style: TextStyle(
                                                      color: titleTextColor),
                                                )),
                                          )
                                      ],
                                    ),
                                    //),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Close'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _selectedTimeIntervalsNotifier,
                          builder: (context, value, child) {
                            return _isSetTimeIntervalPage
                                ? SetTimeIntervalPage(
                                    key: key,
                                    taskId: widget.taskId,
                                    measurableTaskId: widget.measurableTaskId,
                                    taskWithSubtasksId:
                                        widget.taskWithSubtasksId,
                                  )
                                : TimeIntervalOfTaskOrEventPage(
                                    taskId: widget.taskId,
                                    measurableTaskId: widget.measurableTaskId,
                                    taskWithSubtasksId:
                                        widget.taskWithSubtasksId,
                                    selectedTimeIntervals: value,
                                  );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: AppBar(
                          leading: Container(),
                          actions: <Widget>[
                            IconButton.filledTonal(
                              isSelected: _controller.status ==
                                  AnimationStatus.completed,
                              icon: AnimatedBuilder(
                                animation: _controller,
                                builder: (BuildContext context, Widget? child) {
                                  return Icon(
                                    _controller.status ==
                                            AnimationStatus.completed
                                        ? Icons.unfold_less
                                        : Icons.unfold_more,
                                  );
                                },
                              ),
                              onPressed: () {
                                if (_controller.status ==
                                    AnimationStatus.completed) {
                                  _controller.reverse();
                                } else {
                                  _controller.forward();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              isSelected: !_isSetTimeIntervalPage,
                              icon: const Icon(Icons.event_note_outlined),
                              selectedIcon: const Icon(Icons.event_note),
                              onPressed: () {
                                setState(() {
                                  _isSetTimeIntervalPage = false;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            if (_isSetTimeIntervalPage == false)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.filter_list_outlined),
                                onSelected: (String result) {
                                  if (result == 'today') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  } else if (result == 'this week') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  } else if (result == 'this month') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  } else if (result == 'gone') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  } else if (result == 'all') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  } else if (result == 'next month') {
                                    _selectedTimeIntervalsNotifier.value =
                                        result;
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'all',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event_note_outlined,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'all'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'All time intervals',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'all'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'today',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.today,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'today'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Today',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'today'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'this week',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.date_range,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'this week'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'This week',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'this week'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'this month',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'this month'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'This month',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'this month'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'next month',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'next month'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Next month',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'next month'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'gone',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.history,
                                          color: _selectedTimeIntervalsNotifier
                                                      .value ==
                                                  'gone'
                                              ? Colors.blue
                                              : labelColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Gone',
                                          style: TextStyle(
                                            color:
                                                _selectedTimeIntervalsNotifier
                                                            .value ==
                                                        'gone'
                                                    ? Colors.blue
                                                    : labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (_isSetTimeIntervalPage == false)
                              const SizedBox(width: 10),
                            IconButton.filledTonal(
                              isSelected: _isSetTimeIntervalPage,
                              icon: const Icon(Icons.hourglass_empty_outlined),
                              selectedIcon: const Icon(Icons.hourglass_empty),
                              onPressed: () {
                                setState(() {
                                  _isSetTimeIntervalPage = true;
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            if (_isSetTimeIntervalPage)
                              IconButton.filledTonal(
                                isSelected: false,
                                icon: const Icon(Icons.save_outlined),
                                onPressed: () {
                                  key.currentState!._onSave();
                                },
                              ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        });
  }
}

class SetTimeIntervalPage extends StatefulWidget {
  const SetTimeIntervalPage({
    super.key,
    this.taskId,
    this.measurableTaskId,
    this.taskWithSubtasksId,
  });

  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;

  @override
  _SetTimeIntervalPageState createState() => _SetTimeIntervalPageState();
}

class _SetTimeIntervalPageState extends State<SetTimeIntervalPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  final _formKey = GlobalKey<FormState>();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _startTimeController = TextEditingController();
  TextEditingController _endTimeController = TextEditingController();
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _title = '';
  String _description = '';
  String _location = '';

  Color _color = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;
  List<Subtask>? _subtasks = [];
  TargetType? _targetType = TargetType.about;
  double? _targetAtLeast = double.negativeInfinity;
  double? _targetAtMost = double.infinity;
  double? _howMuchHasBeenDone = 0.0;
  String? _unit = '';

  Future<void> _init() async {
    if (widget.taskId != null) {
      final Task task = await _databaseManager.task(widget.taskId!);
      _title = task.title;
      _color = task.color;
      _isImportant = task.isImportant;
      _description = task.description;
      _location = task.location;
    } else if (widget.taskWithSubtasksId != null) {
      final TaskWithSubtasks taskWithSubtasks =
          await _databaseManager.taskWithSubtasks(widget.taskWithSubtasksId!);
      _title = taskWithSubtasks.title;
      _color = taskWithSubtasks.color;
      _isImportant = taskWithSubtasks.isImportant;
      _description = taskWithSubtasks.description;
      _location = taskWithSubtasks.location;
      _subtasks = taskWithSubtasks.subtasks
          .map((subtask) => Subtask(
                isSubtaskCompleted: false,
                title: subtask.title,
              ))
          .toList();
    } else if (widget.measurableTaskId != null) {
      final MeasurableTask measurableTask =
          await _databaseManager.measurableTask(widget.measurableTaskId!);
      _title = measurableTask.title;
      _color = measurableTask.color;
      _isImportant = measurableTask.isImportant;
      _description = measurableTask.description;
      _location = measurableTask.location;
      _targetType = measurableTask.targetType;
      _targetAtLeast = measurableTask.targetAtLeast;
      _targetAtMost = measurableTask.targetAtMost;
      _unit = measurableTask.unit;
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      if ((_isStartDateUndefined &&
              _isEndDateUndefined &&
              _isStartTimeUndefined &&
              _isEndTimeUndefined) ||
          (_startDateController.text.isEmpty &&
              _endDateController.text.isEmpty) ||
          (_startDateController.text == 'undefined' &&
              _endDateController.text == 'undefined')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(AppLocalizations.of(context)!.enterAtLeastOneDate),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        if (_isStartDateUndefined) {
          _isStartTimeUndefined = true;
          _startDate = null;
          _startTime = null;
        } else {
          if (_startDateController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text('Please enter start date'),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          } else {
            _startDate = !_isStartDateUndefined
                ? (() {
                    try {
                      if (_startDateController.text == 'undefined') {
                        return null;
                      } else if (_startDateController.text == 'undefined') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text('Please enter start date'),
                            actions: [
                              TextButton(
                                child: Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        return DateFormat('EEE, dd MMM, yyyy',
                                Localizations.localeOf(context).languageCode)
                            .parse(_startDateController.text);
                      }
                    } catch (_) {
                      // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                      return null;
                    }
                  })()
                : null;

            if (_isStartTimeUndefined) {
              _startTime = null;
            } else {
              if (_startTimeController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text('Please enter start time'),
                    actions: [
                      TextButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // _startTime = TimeOfDay.fromDateTime(
                //     DateFormat('HH:mm').parse(_startTimeController.text));
                _startTime = !_isStartTimeUndefined
                    ? (() {
                        try {
                          if (_startTimeController.text == 'undefined') {
                            return null;
                          } else {
                            return TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                .parse(_startTimeController.text));
                          }
                        } catch (_) {
                          // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                          return null;
                        }
                      })()
                    : null;
              }
            }
          }
        }

        if (_isEndDateUndefined) {
          _isEndTimeUndefined = true;
          _endDate = null;
          _endTime = null;
        } else {
          if (_endDateController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text('Please enter end date'),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          } else {
            // _endDate = DateFormat('EEE, dd MMM, yyyy',
            //         Localizations.localeOf(context).languageCode)
            //     .parse(_endDateController.text);
            _endDate = !_isEndDateUndefined
                ? (() {
                    try {
                      if (_endDateController.text == 'undefined') {
                        return null;
                      } else {
                        return DateFormat('EEE, dd MMM, yyyy',
                                Localizations.localeOf(context).languageCode)
                            .parse(_endDateController.text);
                      }
                    } catch (_) {
                      // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                      return null;
                    }
                  })()
                : null;
            if (_isEndTimeUndefined) {
              _endTime = null;
            } else {
              if (_endTimeController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text('Please enter end time'),
                    actions: [
                      TextButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // _endTime = TimeOfDay.fromDateTime
                //     DateFormat('HH:mm').parse(_endTimeController.text));
                _endTime = !_isEndTimeUndefined
                    ? (() {
                        try {
                          if (_endTimeController.text == 'undefined') {
                            return null;
                          } else {
                            return TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                .parse(_endTimeController.text));
                          }
                        } catch (_) {
                          // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                          return null;
                        }
                      })()
                    : null;
              }
            }
          }
        }

        final timeInterval = TimeInterval(
          taskId: widget.taskId,
          measurableTaskId: widget.measurableTaskId,
          taskWithSubtasksId: widget.taskWithSubtasksId,
          color: _color,
          title: _title,
          isCompleted: _isCompleted,
          isImportant: _isImportant,
          description: _description,
          location: _location,
          subtasks: _subtasks,
          targetType: _targetType,
          unit: _unit,
          targetAtLeast: _targetAtLeast,
          targetAtMost: _targetAtMost,
          howMuchHasBeenDone: _howMuchHasBeenDone,
          startDate: _startDate,
          endDate: _endDate,
          startTime: _startTime,
          endTime: _endTime,
          isStartDateUndefined: _isStartDateUndefined,
          isEndDateUndefined: _isEndDateUndefined,
          isStartTimeUndefined: _isStartTimeUndefined,
          isEndTimeUndefined: _isEndTimeUndefined,
        );
        if ((timeInterval.startTimestamp != null &&
                timeInterval.endTimestamp != null &&
                timeInterval.startTimestamp! > timeInterval.endTimestamp!) ||
            (timeInterval.startDate != null &&
                timeInterval.endDate != null &&
                timeInterval.startDate!.isAfter(timeInterval.endDate!)) ||
            (timeInterval.startDate != null &&
                timeInterval.endDate != null &&
                timeInterval.startDate!
                    .isAtSameMomentAs(timeInterval.endDate!) &&
                timeInterval.startTime != null &&
                timeInterval.endTime != null &&
                (timeInterval.startTime!.hour * 60 +
                        timeInterval.startTime!.minute) >
                    (timeInterval.endTime!.hour * 60 +
                        timeInterval.endTime!.minute))) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Lỗi'),
                content: Text(
                    'Thời gian bắt đầu không được phép xảy ra sau thời gian kết thúc.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Đóng'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          await _databaseManager.insertTimeInterval(timeInterval);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('has been scheduled'),
            ),
          );
          setState(() {
            _startDateController.clear();
            _startTimeController.clear();
            _endDateController.clear();
            _endTimeController.clear();
            _isStartDateUndefined = false;
            _isEndDateUndefined = false;
            _isStartTimeUndefined = false;
            _isEndTimeUndefined = false;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    String languageCode = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _startDateController = TextEditingController(
      text: DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(now),
    );
    _endDateController = TextEditingController(
      text: DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(now),
    );
    _startTimeController = TextEditingController(
      text: TimeOfDay.fromDateTime(now).format(context),
    );
    _endTimeController = TextEditingController(
      text: TimeOfDay.fromDateTime(nextHour).format(context),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SetTimeIntervalBlockListTile(
                startDateController: _startDateController,
                isStartDateUndefined: _isStartDateUndefined,
                endDateController: _endDateController,
                isEndDateUndefined: _isEndDateUndefined,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
                isStartTimeUndefined: _isStartTimeUndefined,
                isEndTimeUndefined: _isEndTimeUndefined,
                languageCode: languageCode,
                formKey: _formKey),
            RepeatListTile(),
            AlarmListTile(),
            TimezoneListTile(),
          ],
        ),
      ),
    );
  }
}

class TimeIntervalOfTaskOrEventPage extends StatefulWidget {
  const TimeIntervalOfTaskOrEventPage(
      {super.key,
      this.taskId,
      this.measurableTaskId,
      this.taskWithSubtasksId,
      required this.selectedTimeIntervals});

  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  final String selectedTimeIntervals;

  @override
  _TimeIntervalOfTaskOrEventPageState createState() =>
      _TimeIntervalOfTaskOrEventPageState();
}

class _TimeIntervalOfTaskOrEventPageState
    extends State<TimeIntervalOfTaskOrEventPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];
  List<TimeInterval> _timeIntervalsGone = [];
  List<TimeInterval> _timeIntervalsToday = [];
  List<TimeInterval> _timeIntervalsThisWeek = [];
  List<TimeInterval> _timeIntervalsThisMonth = [];
  List<TimeInterval> _timeIntervalsNextMonth = [];
  List<TimeInterval> _timeIntervalsAll = [];
  Task? _task;
  MeasurableTask? _measurableTask;
  TaskWithSubtasks? _taskWithSubtasks;
  //bool _isExpanded = false;
  final Map<String, bool> _isExpanded = {};

  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';
  String _selectedTimeIntervals = 'today';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if the data has changed.
    for (var timeInterval in _timeIntervals) {
      if (_task != null) {
        if (timeInterval.description != _task!.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != _task!.location) {
          timeInterval.isLocationChanged = true;
        }
      } else if (_measurableTask != null) {
        if (timeInterval.description != _measurableTask!.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != _measurableTask!.location) {
          timeInterval.isLocationChanged = true;
        }
        if ((timeInterval.targetType != _measurableTask!.targetType) ||
            (timeInterval.targetAtLeast != _measurableTask!.targetAtLeast) ||
            (timeInterval.targetAtMost != _measurableTask!.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
      } else if (_taskWithSubtasks != null) {
        if (timeInterval.description != _taskWithSubtasks!.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != _taskWithSubtasks!.location) {
          timeInterval.isLocationChanged = true;
        }
        List<String> timeIntervalSubtasksTitles =
            timeInterval.subtasks.map((subtask) => subtask.title).toList();
        timeIntervalSubtasksTitles.sort();

        List<String> taskWithSubtasksSubtasksTitles = _taskWithSubtasks!
            .subtasks
            .map((subtask) => subtask.title)
            .toList();
        taskWithSubtasksSubtasksTitles.sort();

        if (!listEquals(
            timeIntervalSubtasksTitles, taskWithSubtasksSubtasksTitles)) {
          timeInterval.isSubtasksChanged = true;
        }
      }
    }
  }

  Future<void> _init() async {
    if (widget.taskId != null) {
      final task = await _databaseManager.task(widget.taskId!);
      _task = task;
      final timeIntervals =
          await _databaseManager.timeIntervalsOfTask(widget.taskId!);
      for (var timeInterval in timeIntervals) {
        if (timeInterval.description != task.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != task.location) {
          timeInterval.isLocationChanged = true;
        }
      }
      for (var timeInterval in timeIntervals) {
        _isExpanded[timeInterval.id] = false;
      }

      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });
      setState(() {
        _timeIntervalsAll = timeIntervals;
        _timeIntervalsToday = timeIntervals
            .where((timeInterval) => timeInterval.isToday ?? false)
            .toList();
        _timeIntervalsGone = timeIntervals
            .where((timeInterval) => timeInterval.isGone ?? false)
            .toList();
        _timeIntervalsThisWeek = timeIntervals
            .where((timeInterval) => timeInterval.isThisWeek ?? false)
            .toList();
        _timeIntervalsThisMonth = timeIntervals
            .where((timeInterval) => timeInterval.isThisMonth ?? false)
            .toList();
        _timeIntervalsNextMonth = timeIntervals
            .where((timeInterval) => timeInterval.isNextMonth ?? false)
            .toList();
      });
    } else if (widget.measurableTaskId != null) {
      final measurableTask =
          await _databaseManager.measurableTask(widget.measurableTaskId!);
      _measurableTask = measurableTask;
      final timeIntervals = await _databaseManager
          .timeIntervalsOfMeasureableTask(widget.measurableTaskId!);
      for (var timeInterval in timeIntervals) {
        if (timeInterval.description != measurableTask.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != measurableTask.location) {
          timeInterval.isLocationChanged = true;
        }
        if ((timeInterval.targetType != measurableTask.targetType) ||
            (timeInterval.targetAtLeast != measurableTask.targetAtLeast) ||
            (timeInterval.targetAtMost != measurableTask.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
      }
      for (var timeInterval in timeIntervals) {
        _isExpanded[timeInterval.id] = false;
      }
      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });
      setState(() {
        _timeIntervalsAll = timeIntervals;
        _timeIntervalsToday = timeIntervals
            .where((timeInterval) => timeInterval.isToday ?? false)
            .toList();
        _timeIntervalsGone = timeIntervals
            .where((timeInterval) => timeInterval.isGone ?? false)
            .toList();
        _timeIntervalsThisWeek = timeIntervals
            .where((timeInterval) => timeInterval.isThisWeek ?? false)
            .toList();
        _timeIntervalsThisMonth = timeIntervals
            .where((timeInterval) => timeInterval.isThisMonth ?? false)
            .toList();
        _timeIntervalsNextMonth = timeIntervals
            .where((timeInterval) => timeInterval.isNextMonth ?? false)
            .toList();
      });
    } else if (widget.taskWithSubtasksId != null) {
      final taskWithSubtasks =
          await _databaseManager.taskWithSubtasks(widget.taskWithSubtasksId!);
      _taskWithSubtasks = taskWithSubtasks;
      final timeIntervals = await _databaseManager
          .timeIntervalsOfTaskWithSubtasks(widget.taskWithSubtasksId!);
      for (var timeInterval in timeIntervals) {
        if (timeInterval.description != taskWithSubtasks.description) {
          timeInterval.isDescriptionChanged = true;
        }
        if (timeInterval.location != taskWithSubtasks.location) {
          timeInterval.isLocationChanged = true;
        }
        List<String> timeIntervalSubtasksTitles =
            timeInterval.subtasks.map((subtask) => subtask.title).toList();
        timeIntervalSubtasksTitles.sort();

        List<String> taskWithSubtasksSubtasksTitles =
            taskWithSubtasks.subtasks.map((subtask) => subtask.title).toList();
        taskWithSubtasksSubtasksTitles.sort();

        if (!listEquals(
            timeIntervalSubtasksTitles, taskWithSubtasksSubtasksTitles)) {
          timeInterval.isSubtasksChanged = true;
        }
      }
      for (var timeInterval in timeIntervals) {
        _isExpanded[timeInterval.id] = false;
      }

      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });

      setState(() {
        _timeIntervalsAll = timeIntervals;
        _timeIntervalsToday = timeIntervals
            .where((timeInterval) => timeInterval.isToday ?? false)
            .toList();
        _timeIntervalsGone = timeIntervals
            .where((timeInterval) => timeInterval.isGone ?? false)
            .toList();
        _timeIntervalsThisWeek = timeIntervals
            .where((timeInterval) => timeInterval.isThisWeek ?? false)
            .toList();
        _timeIntervalsThisMonth = timeIntervals
            .where((timeInterval) => timeInterval.isThisMonth ?? false)
            .toList();
        _timeIntervalsNextMonth = timeIntervals
            .where((timeInterval) => timeInterval.isNextMonth ?? false)
            .toList();
      });
    }
  }

  Future<void> _onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval =
        timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    final index =
        _timeIntervals.indexWhere((item) => item.id == _timeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = _timeInterval;
      });
    }
    await _databaseManager.updateTimeInterval(_timeInterval);
  }

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    setState(() => _timeIntervals.remove(timeInterval));
    await _databaseManager.deleteTimeInterval(timeInterval.id);
  }

  Future<void> _onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(
      subtasks: timeInterval.subtasks,
    );
    final index =
        _timeIntervals.indexWhere((item) => item.id == _timeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = _timeInterval;
      });
    }
    await _databaseManager.updateTimeInterval(_timeInterval);
  }

  Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: timeInterval.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Has been done:'),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              TimeInterval _timeInterval = timeInterval.copyWith(
                  howMuchHasBeenDone:
                      double.parse(_hasBeenDoneController.text));
              final index = _timeIntervals
                  .indexWhere((item) => item.id == _timeInterval.id);
              if (index != -1) {
                setState(() {
                  _timeIntervals[index] = _timeInterval;
                });
              }
              await _databaseManager.updateTimeInterval(_timeInterval);
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _selectedTimeIntervals = widget.selectedTimeIntervals;
    if (_selectedTimeIntervals == 'all') {
      _timeIntervals = _timeIntervalsAll;
    } else if (_selectedTimeIntervals == 'today') {
      _timeIntervals = _timeIntervalsToday;
    } else if (_selectedTimeIntervals == 'gone') {
      _timeIntervals = _timeIntervalsGone;
    } else if (_selectedTimeIntervals == 'this week') {
      _timeIntervals = _timeIntervalsThisWeek;
    } else if (_selectedTimeIntervals == 'this month') {
      _timeIntervals = _timeIntervalsThisMonth;
    } else if (_selectedTimeIntervals == 'next month') {
      _timeIntervals = _timeIntervalsNextMonth;
    }

    return _timeIntervals.isEmpty
        ? _selectedTimeIntervals == 'all'
            ? const Text('This task has not been scheduled yet')
            : _selectedTimeIntervals == 'today'
                ? const Text('This task has not been scheduled today')
                : _selectedTimeIntervals == 'this week'
                    ? const Text('This task has not been scheduled this week')
                    : _selectedTimeIntervals == 'this month'
                        ? const Text(
                            'This task has not been scheduled this month')
                        : _selectedTimeIntervals == 'next month'
                            ? const Text(
                                'This task has not been scheduled next month')
                            : _selectedTimeIntervals == 'gone'
                                ? const Text(
                                    'This task has not been scheduled in the past')
                                : Container()
        : ListView.builder(
            shrinkWrap: true,
            //physics: NeverScrollableScrollPhysics(),
            itemCount: _timeIntervals.length,
            itemBuilder: (context, index) {
              final timeInterval = _timeIntervals[index];
              final textTheme = Theme.of(context).textTheme;
              if (timeInterval.startDate != null) {
                _formattedStartDate = DateFormat('EEE, dd MMM, yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(timeInterval.startDate!);
              } else {
                _formattedStartDate = '--/--/----';
              }

              if (timeInterval.startTime != null) {
                _formattedStartTime = timeInterval.startTime!.format(context);
              } else {
                _formattedStartTime = '--:--';
              }

              if (timeInterval.endDate != null) {
                _formattedEndDate = DateFormat('EEE, dd MMM, yyyy',
                        Localizations.localeOf(context).languageCode)
                    .format(timeInterval.endDate!);
              } else {
                _formattedEndDate = '--/--/----';
              }

              if (timeInterval.endTime != null) {
                _formattedEndTime = timeInterval.endTime!.format(context);
              } else {
                _formattedEndTime = '--:--';
              }

              return Column(
                children: [
                  ListTile(
                    //contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8.0, // khoảng cách giữa các Chip
                          children: <Widget>[
                            if (timeInterval.isGone == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: const Text(
                                  'gone',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            if (timeInterval.isInProgress == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: const Text(
                                  'in progress',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            if (timeInterval.isToday == true)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(
                                      5), // bo tròn viền tại đây
                                ),
                                child: const Text(
                                  'today',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        RichText(
                          text: TextSpan(
                            style: timeInterval.isCompleted
                                ? textTheme.titleSmall!.copyWith(
                                    decoration: TextDecoration.lineThrough)
                                : textTheme.titleSmall,
                            text: _formattedStartDate == _formattedEndDate
                                ? 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndTime'
                                : 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndDate: $_formattedEndTime',
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                      ),
                      onSelected: (String result) {
                        if (result == 'mark_completed') {
                          _onTimeIntervalToggleCompleted(timeInterval);
                        } else if (result == 'sync_details') {
                        } else if (result == 'edit') {
                          Future<void> editTimeInterval() async {
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
                            if (index != -1) {
                              setState(() {
                                _timeIntervals[index] = updatedTimeInterval;
                              });
                            }
                          }

                          // Call the async function
                          editTimeInterval();
                        } else if (result == 'delete') {
                          _deleteTimeInterval(timeInterval);
                        } else if (result == 'expand') {
                          setState(() {
                            _isExpanded[timeInterval.id] =
                                !_isExpanded[timeInterval.id]!;
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'expand',
                          child: Row(
                            children: [
                              Icon(_isExpanded[timeInterval.id]!
                                  ? Icons.chevron_right
                                  : Icons.expand_more),
                              const SizedBox(width: 8),
                              _isExpanded[timeInterval.id]!
                                  ? const Text('Hide details')
                                  : const Text('Show details'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                            value: 'mark_completed',
                            child: Row(
                              children: [
                                Icon(timeInterval.isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(timeInterval.isCompleted
                                      ? 'Mark as incompleted in this time interval'
                                      : 'Mark as completed in this time interval'),
                                ),
                              ],
                            )),
                        const PopupMenuItem<String>(
                          value: 'sync_details',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Sync details from task to this time interval'),
                              )
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Expanded(
                                child:
                                    Text('Edit details in this time interval'),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Delete this time interval'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isExpanded[timeInterval.id]! &&
                      timeInterval.description.isNotEmpty)
                    ListTile(
                        dense: true,
                        leading: Icon(Icons.description_outlined),
                        title: Text(timeInterval.description)),
                  if (_isExpanded[timeInterval.id]! &&
                      timeInterval.location.isNotEmpty)
                    ListTile(
                        dense: true,
                        leading: Icon(Icons.location_on_outlined),
                        title: Text(timeInterval.location)),
                  if (timeInterval.measurableTaskId != null &&
                      _isExpanded[timeInterval.id]!)
                    ListTile(
                      dense: true,
                      title: Column(
                        children: [
                          if (timeInterval.targetType == TargetType.about)
                            Text(
                              'Target: about ${timeInterval.targetAtLeast} to ${timeInterval.targetAtMost} ${timeInterval.unit}',
                              //style: TextStyle(color: labelColor),
                            ),
                          if (timeInterval.targetType == TargetType.atLeast)
                            Text(
                              'Target: at least ${timeInterval.targetAtLeast} ${timeInterval.unit}',
                              //style: TextStyle(color: labelColor),
                            ),
                          if (timeInterval.targetType == TargetType.atMost)
                            Text(
                              'Target: at most ${timeInterval.targetAtMost} ${timeInterval.unit}',
                              //style: TextStyle(color: labelColor),
                            ),
                        ],
                      ),
                    ),
                  if (timeInterval.measurableTaskId != null &&
                      _isExpanded[timeInterval.id]!)
                    ListTile(
                      dense: true,
                      title: ActionChip(
                          label: Text(
                            'Has been done: ${timeInterval.howMuchHasBeenDone} ${timeInterval.unit}',
                          ),
                          onPressed: () => _onHasBeenDoneUpdate(timeInterval)),
                    ),
                  if (timeInterval.taskWithSubtasksId != null &&
                          _isExpanded[timeInterval.id]!
                      //timeInterval.isSubtasksChanged
                      )
                    ...timeInterval.subtasks.reversed.map(
                      (subtask) => CheckboxListTile(
                        //contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                        dense: true,
                        side: BorderSide(
                            //color: labelColor,
                            ),
                        //activeColor: labelColor,
                        activeColor: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Colors.black
                            : Colors.white, // Màu nền khi Checkbox được chọn
                        checkColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: subtask.isSubtaskCompleted,
                        onChanged: (value) {
                          subtask.isSubtaskCompleted = value ?? false;
                          _onSubtasksChanged(timeInterval);
                        },
                        title: Text(
                          subtask.title,
                          style: TextStyle(
                            decoration: subtask.isSubtaskCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            //color: labelColor,
                          ),
                        ),
                        secondary: IconButton(
                          icon: Icon(
                            Icons.delete_outlined,
                            //color: labelColor,
                          ),
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Delete Subtask'),
                                  content: Text(
                                      'Are you sure you want to delete this subtask?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (result == true) {
                              timeInterval.subtasks.remove(subtask);
                              _onSubtasksChanged(timeInterval);
                            }
                          },
                        ),
                      ),
                    ),
                  const Divider(
                    height: 4,
                  ),
                ],
              );
            },
          );
  }
}
