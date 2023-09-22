import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/utils/constants.dart';

class SetTimeIntervalBottomSheet extends StatefulWidget {
  const SetTimeIntervalBottomSheet(
      {super.key, this.taskId, this.measurableTaskId, this.taskWithSubtasksId});
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;

  @override
  _SetTimeIntervalBottomSheetState createState() =>
      _SetTimeIntervalBottomSheetState();
}

class _SetTimeIntervalBottomSheetState extends State<SetTimeIntervalBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final GlobalKey<_SetTimeIntervalPageState> key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            heightFactor: _animation.value,
            child: DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                maxChildSize: 1,
                minChildSize: 0.4,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Column(
                    children: <Widget>[
                      // Listener(
                      //   onPointerMove: (PointerMoveEvent event) {
                      //     if (event.delta.dy < 0) {
                      //       _controller.forward();
                      //     } else if (event.delta.dy > 0) {
                      //       _controller.reverse();
                      //     }
                      //   },
                      //   child: Container(
                      //     height: 60, // Set this to your desired height
                      //     width: double.infinity,
                      //     color: Colors.grey[300],
                      //     alignment: Alignment.center,
                      //     child: const Icon(Icons.horizontal_rule),
                      //   ),
                      // ),
                      //Không xóa, phần này sẽ được chỉnh sửa sau và thêm vào các chức năng như filter, search...
                      AppBar(
                        toolbarHeight: 40.0,
                        leading: IconButton(
                          icon: AnimatedBuilder(
                            animation: _controller,
                            builder: (BuildContext context, Widget? child) {
                              return Icon(
                                _controller.status == AnimationStatus.completed
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
                        //title: Text('Schedule'),
                        actions: <Widget>[
                          //Switch display between calendar and list of time intervals
                          IconButton(
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.save_outlined),
                            onPressed: () {
                              key.currentState!._onSave();
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: SetTimeIntervalPage(
                          key: key,
                          taskId: widget.taskId,
                          measurableTaskId: widget.measurableTaskId,
                          taskWithSubtasksId: widget.taskWithSubtasksId,
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
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;
  //List<TimeInterval> _timeIntervals = [];
  //bool _isAscending = true;
  //String _languageCode = 'en';
  String _title = '';
  String _description = '';
  String _location = '';

  Color _color = ColorSeed.baseColor.color;
  bool _isCompleted = false;
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
      _description = task.description;
      _location = task.location;
    } else if (widget.taskWithSubtasksId != null) {
      final TaskWithSubtasks taskWithSubtasks =
          await _databaseManager.taskWithSubtasks(widget.taskWithSubtasksId!);
      _title = taskWithSubtasks.title;
      _color = taskWithSubtasks.color;
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
      if (_isStartDateUndefined &&
          _isEndDateUndefined &&
          _isStartTimeUndefined &&
          _isEndTimeUndefined) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            content: Text('Please enter at least one date'),
          ),
        );
      } else {
        final startDate = !_isStartDateUndefined
            ? DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .parse(_startDateController.text)
            : null;
        final endDate = !_isEndDateUndefined
            ? DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .parse(_endDateController.text)
            : null;
        final startTime = !_isStartTimeUndefined
            ? TimeOfDay.fromDateTime(
                DateFormat('HH:mm').parse(_startTimeController.text))
            : null;
        final endTime = !_isEndTimeUndefined
            ? TimeOfDay.fromDateTime(
                DateFormat('HH:mm').parse(_endTimeController.text))
            : null;
        final timeInterval = TimeInterval(
          taskId: widget.taskId,
          measurableTaskId: widget.measurableTaskId,
          taskWithSubtasksId: widget.taskWithSubtasksId,
          color: _color,
          title: _title,
          isCompleted: _isCompleted,
          description: _description,
          location: _location,
          subtasks: _subtasks,
          targetType: _targetType,
          unit: _unit,
          targetAtLeast: _targetAtLeast,
          targetAtMost: _targetAtMost,
          howMuchHasBeenDone: _howMuchHasBeenDone,
          startDate: startDate,
          endDate: endDate,
          startTime: startTime,
          endTime: endTime,
          isStartDateUndefined: startDate == null || _isStartDateUndefined,
          isEndDateUndefined: endDate == null || _isEndDateUndefined,
          isStartTimeUndefined: startTime == null || _isStartTimeUndefined,
          isEndTimeUndefined: endTime == null || _isEndTimeUndefined,
        );
        if (timeInterval.startTimestamp != null &&
            timeInterval.endTimestamp != null &&
            timeInterval.startTimestamp! > timeInterval.endTimestamp!) {
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
          //_onSaveTimeInterval(timeInterval);
          await _databaseManager.insertTimeInterval(timeInterval);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('has been scheduled'),
            ),
          );
        }
        setState(() {
          //_timeIntervals.add(timeInterval);
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    String languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      controller: _startDateController,
                      readOnly: _isStartDateUndefined,
                      onTap: () async {
                        if (!_isStartDateUndefined) {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            _startDateController.text =
                                DateFormat('EEE, dd MMM, yyyy', languageCode)
                                    .format(date);
                          }
                        }
                      },
                      validator: (value) {
                        if (!_isStartDateUndefined && value!.isEmpty) {
                          return 'Please enter a start date';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        suffixIcon: Checkbox(
                          value: _isStartDateUndefined,
                          onChanged: (value) {
                            setState(() {
                              _isStartDateUndefined = value!;
                              if (_isStartDateUndefined) {
                                _startDateController.text = 'undefined';
                                _isStartTimeUndefined = true;
                                _startTimeController.text = 'undefined';
                              } else {
                                _startDateController.clear();
                              }
                            });
                          },
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'Start date',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  // Expanded(
                  //   flex: 1,
                  //   child: TextFormField(
                  //     readOnly: _isStartTimeUndefined,
                  //     maxLines: 1,
                  //     controller: _startTimeController,
                  //     onTap: () async {
                  //       if (!_isStartTimeUndefined) {
                  //         final time = await showTimePicker(
                  //           context: context,
                  //           initialTime: TimeOfDay(
                  //               hour: TimeOfDay.now().hour, minute: 0),
                  //         );
                  //         if (time != null) {
                  //           _startTimeController.text =
                  //               '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  //         }
                  //       }
                  //     },
                  //     validator: (value) {
                  //       if (!_isStartTimeUndefined && value!.isEmpty) {
                  //         return 'Please enter a start time';
                  //       }
                  //       return null;
                  //     },
                  //     decoration: InputDecoration(
                  //       suffixIcon: Checkbox(
                  //         value: _isStartTimeUndefined,
                  //         onChanged: _isStartDateUndefined
                  //             ? null
                  //             : (value) {
                  //                 setState(() {
                  //                   _isStartTimeUndefined = value!;
                  //                   if (_isStartTimeUndefined) {
                  //                     _startTimeController.text = 'undefined';
                  //                   } else {
                  //                     _startTimeController.clear();
                  //                   }
                  //                 });
                  //               },
                  //       ),
                  //       border: OutlineInputBorder(),
                  //       labelText: 'Start time',
                  //       floatingLabelBehavior: FloatingLabelBehavior.auto,
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      controller: _endDateController,
                      readOnly: _isEndDateUndefined,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _endDateController.text =
                              DateFormat('EEE, dd MMM, yyyy', languageCode)
                                  .format(date);
                        }
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an end date';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        suffixIcon: Checkbox(
                          value: _isEndDateUndefined,
                          onChanged: (value) {
                            setState(() {
                              _isEndDateUndefined = value!;
                              if (_isEndDateUndefined) {
                                _endDateController.text = 'undefined';
                                _isEndTimeUndefined = true;
                                _endTimeController.text = 'undefined';
                              } else {
                                _endDateController.clear();
                              }
                            });
                          },
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'End date',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  // Expanded(
                  //   flex: 2,
                  //   child: TextFormField(
                  //     maxLines: 1,
                  //     controller: _endDateController,
                  //     readOnly: _isEndDateUndefined,
                  //     onTap: () async {
                  //       final date = await showDatePicker(
                  //         context: context,
                  //         initialDate: DateTime.now(),
                  //         firstDate: DateTime(1900),
                  //         lastDate: DateTime(2100),
                  //       );
                  //       if (date != null) {
                  //         _endDateController.text =
                  //             DateFormat('EEE, dd MMM, yyyy', languageCode)
                  //                 .format(date);
                  //       }
                  //     },
                  //     validator: (value) {
                  //       if (value!.isEmpty) {
                  //         return 'Please enter an end date';
                  //       }
                  //       return null;
                  //     },
                  //     decoration: InputDecoration(
                  //       suffixIcon: Checkbox(
                  //         value: _isEndDateUndefined,
                  //         onChanged: (value) {
                  //           setState(() {
                  //             _isEndDateUndefined = value!;
                  //             if (_isEndDateUndefined) {
                  //               _endDateController.text = 'undefined';
                  //               _isEndTimeUndefined = true;
                  //               _endTimeController.text = 'undefined';
                  //             } else {
                  //               _endDateController.clear();
                  //             }
                  //           });
                  //         },
                  //       ),
                  //       border: OutlineInputBorder(),
                  //       labelText: 'End date',
                  //       floatingLabelBehavior: FloatingLabelBehavior.auto,
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                      readOnly: _isStartTimeUndefined,
                      maxLines: 1,
                      controller: _startTimeController,
                      onTap: () async {
                        if (!_isStartTimeUndefined) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: TimeOfDay.now().hour, minute: 0),
                          );
                          if (time != null) {
                            _startTimeController.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        }
                      },
                      validator: (value) {
                        if (!_isStartTimeUndefined && value!.isEmpty) {
                          return 'Please enter a start time';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        suffixIcon: Checkbox(
                          value: _isStartTimeUndefined,
                          onChanged: _isStartDateUndefined
                              ? null
                              : (value) {
                                  setState(() {
                                    _isStartTimeUndefined = value!;
                                    if (_isStartTimeUndefined) {
                                      _startTimeController.text = 'undefined';
                                    } else {
                                      _startTimeController.clear();
                                    }
                                  });
                                },
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'Start time',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      style: const TextStyle(
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      controller: _endTimeController,
                      readOnly: _isEndTimeUndefined,
                      onTap: (() async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: TimeOfDay.now().hour, minute: 0),
                        );
                        if (time != null) {
                          _endTimeController.text =
                              '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
                        }
                      }),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an end time';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        suffixIcon: Checkbox(
                          value: _isEndTimeUndefined,
                          onChanged: _isEndDateUndefined
                              ? null
                              : (value) {
                                  setState(() {
                                    _isEndTimeUndefined = value!;
                                    if (_isEndTimeUndefined) {
                                      _endTimeController.text = 'undefined';
                                    } else {
                                      _endTimeController.clear();
                                    }
                                  });
                                },
                        ),
                        border: OutlineInputBorder(),
                        labelText: 'End time',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 08,
              ),
              const Divider(
                height: 4,
              ),
              RepeatListTile(),
              AlarmListTile(),
              TimezoneListTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class RepeatListTile extends StatefulWidget {
  @override
  _RepeatListTileState createState() => _RepeatListTileState();
}

class _RepeatListTileState extends State<RepeatListTile> {
  bool _showRepeatOptions = false;
  bool _showCustomOptions = false;
  String _selectedOption = 'Does not repeat';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.repeat_outlined),
          title: Text('Repeat?'),
          onTap: () {
            setState(() {
              _showRepeatOptions = !_showRepeatOptions;
            });
          },
        ),
        if (_showRepeatOptions)
          Column(
            children: [
              RadioListTile(
                title: const Text('Does not repeat'),
                value: 'Does not repeat',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every day'),
                value: 'Every day',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every week'),
                value: 'Every week',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every month'),
                value: 'Every month',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every year'),
                value: 'Every year',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Custom'),
                value: 'Custom',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = true;
                  });
                },
              ),
            ],
          ),
        if (_showCustomOptions) RepeatEveryListTile(),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}

class RepeatEveryListTile extends StatefulWidget {
  @override
  _RepeatEveryListTileState createState() => _RepeatEveryListTileState();
}

class _RepeatEveryListTileState extends State<RepeatEveryListTile> {
  int _repeatValue = 1;
  String _repeatType = 'day';
  String _selectedEndOption = 'Never';
  bool _showWeekDaysOptions = false;
  Map<String, bool> _selectedDays = {
    'Mon': false,
    'Tue': false,
    'Wen': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };
  bool _showMonthOptions = false;
  String _selectedMonthOption = 'Monthly on the same day';
  DateTime _selectedDate = DateTime.now();
  int _occurrence = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Text('Repeats every'),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  initialValue: '$_repeatValue',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setState(() {
                      _repeatValue = int.parse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _repeatType,
                  items: ['day', 'week', 'month', 'year'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_repeatValue > 1 ? value + 's' : value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _repeatType = newValue!;
                      _showWeekDaysOptions = (_repeatType == 'week');
                      _showMonthOptions = (_repeatType == 'month');
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showWeekDaysOptions)
          Wrap(
            spacing: 8.0, // gap between adjacent chips
            runSpacing: 4.0, // gap between lines
            children: _selectedDays.keys.map((day) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDays[day] = !_selectedDays[day]!;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        _selectedDays[day]! ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                        color: Colors.blue, width: _selectedDays[day]! ? 0 : 1),
                  ),
                  child: Text(day),
                ),
              );
            }).toList(),
          ),
        if (_showMonthOptions)
          ListTile(
            title: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              value: _selectedMonthOption,
              items: [
                'Monthly on the same day',
                'Monthly on the same day of week'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMonthOption = newValue!;
                });
              },
            ),
          ),
        ListTile(
          title: Text('Ends'),
          subtitle: Column(
            children: [
              RadioListTile(
                title: const Text('Never'),
                value: 'Never',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
              RadioListTile(
                title: Row(
                  children: [
                    const Text('On day '),
                    Expanded(
                      child: TextFormField(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        initialValue:
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ],
                ),
                value: 'On day',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
              RadioListTile(
                title: Row(
                  children: [
                    const Text('After '),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_occurrence',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          setState(() {
                            _occurrence = int.parse(value);
                          });
                        },
                      ),
                    ),
                    const Text(' occurrence'),
                  ],
                ),
                value: 'After x occurrence',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AlarmListTile extends StatefulWidget {
  @override
  _AlarmListTileState createState() => _AlarmListTileState();
}

class _AlarmListTileState extends State<AlarmListTile> {
  List<String> alarms = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.alarm_outlined),
          title: Text('Alarm'),
          onTap: () {
            if (alarms.length < 5) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Choose an alarm'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                          title: const Text('5 minutes before'),
                          value: '5 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('10 minutes before'),
                          value: '10 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('15 minutes before'),
                          value: '15 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('30 minutes before'),
                          value: '30 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('1 hour before'),
                          value: '1 hour before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('1 day before'),
                          value: '1 day before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('Custom...'),
                          value: 'custom',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
        const Divider(
          height: 4,
        ),
        for (var alarm in alarms)
          ListTile(
            title: Text(alarm),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  alarms.remove(alarm);
                });
              },
            ),
          ),
      ],
    );
  }
}

class TimezoneListTile extends StatefulWidget {
  @override
  _TimezoneListTileState createState() => _TimezoneListTileState();
}

class _TimezoneListTileState extends State<TimezoneListTile> {
  String _selectedTimezone = 'Timezone của thiết bị';

  // Danh sách tất cả các timezone theo IANA
  List<String> _timezones = [
    'Timezone 1',
    'Timezone 2',
    // Thêm tất cả các timezone khác vào đây
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.public_outlined),
      title: Text(_selectedTimezone),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Chọn timezone'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _timezones.map((timezone) {
                    return RadioListTile(
                      title: Text(timezone),
                      value: timezone,
                      groupValue: _selectedTimezone,
                      onChanged: (value) {
                        setState(() {
                          _selectedTimezone = value as String;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
