import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/button_color_seed.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_target_block.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/model_time_interval.dart';

class AddOrEditTimeIntervalPage extends StatefulWidget {
  const AddOrEditTimeIntervalPage({
    Key? key,
    this.timeInterval,
    //required this.taskList
  }) : super(key: key);
  //final TaskList taskList;
  final TimeInterval? timeInterval;

  @override
  _AddOrEditTimeIntervalPageState createState() =>
      _AddOrEditTimeIntervalPageState();
}

class _AddOrEditTimeIntervalPageState extends State<AddOrEditTimeIntervalPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _hasBeenDoneController = TextEditingController();
  final TextEditingController _targetAtLeastController =
      TextEditingController();
  final TextEditingController _targetAtMostController = TextEditingController();
  final DatabaseManager _databaseManager = DatabaseManager();
  TargetType _targetType = TargetType.about;
  List<Subtask> _subtasks = [];
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;

  Color _timeIntervalColor = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  String _id = '';

  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';

  @override
  void initState() {
    super.initState();
    if (widget.timeInterval != null) {
      _id = widget.timeInterval!.id;
      widget.timeInterval?.title != null
          ? _titleController.text = widget.timeInterval!.title
          : _titleController.text = '';
      widget.timeInterval?.description != null
          ? _descriptionController.text = widget.timeInterval!.description
          : _descriptionController.text = '';
      widget.timeInterval?.location != null
          ? _locationController.text = widget.timeInterval!.location
          : _locationController.text = '';
      widget.timeInterval?.subtasks != null
          ? _subtasks = widget.timeInterval!.subtasks
          : _subtasks = [];
      _timeIntervalColor = widget.timeInterval!.color;
      widget.timeInterval?.unit != null
          ? _unitController.text = widget.timeInterval!.unit
          : _unitController.text = '';
      widget.timeInterval?.targetAtLeast != null
          ? _targetAtLeastController.text =
              widget.timeInterval!.targetAtLeast.toString()
          : _targetAtLeastController.text = '';
      widget.timeInterval?.targetAtMost != null
          ? _targetAtMostController.text =
              widget.timeInterval!.targetAtMost.toString()
          : _targetAtMostController.text = '';
      widget.timeInterval?.howMuchHasBeenDone != null
          ? _hasBeenDoneController.text =
              widget.timeInterval!.howMuchHasBeenDone.toString()
          : _hasBeenDoneController.text = '0.0';
      widget.timeInterval?.targetType != null
          ? _targetType = widget.timeInterval!.targetType
          : _targetType = TargetType.about;
      _isCompleted = widget.timeInterval!.isCompleted;
      _isStartDateUndefined = widget.timeInterval!.isStartDateUndefined;
      _isStartTimeUndefined = widget.timeInterval!.isStartTimeUndefined;
      _isEndDateUndefined = widget.timeInterval!.isEndDateUndefined;
      _isEndTimeUndefined = widget.timeInterval!.isEndTimeUndefined;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.timeInterval?.startDate != null) {
          _startDateController.text = DateFormat('EEE, dd MMM, yyyy',
                  Localizations.localeOf(context).languageCode)
              .format(widget.timeInterval!.startDate!);
        } else {
          _startDateController.text = 'undefined';
        }

        if (widget.timeInterval?.endDate != null) {
          _endDateController.text = DateFormat('EEE, dd MMM, yyyy',
                  Localizations.localeOf(context).languageCode)
              .format(widget.timeInterval!.endDate!);
        } else {
          _endDateController.text = 'undefined';
        }
        widget.timeInterval?.startTime != null
            ? _startTimeController.text =
                widget.timeInterval!.startTime!.format(context)
            : _startTimeController.text = 'undefined';
        widget.timeInterval?.endTime != null
            ? _endTimeController.text =
                widget.timeInterval!.endTime!.format(context)
            : _endTimeController.text = 'undefined';
      });
    } else {
      _id = const Uuid().v4();
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
        final id = _id;
        final title = _titleController.text;
        final description = _descriptionController.text;
        final location = _locationController.text;
        final isCompleted = widget.timeInterval == null ? false : _isCompleted;
        final color = _timeIntervalColor;
        final subtasks = _subtasks;

        final howMuchHasBeenDone = _hasBeenDoneController.text == ''
            ? double.parse('0.0')
            : double.parse(_hasBeenDoneController.text);
        double? targetAtLeast;
        if (_targetType == TargetType.atLeast ||
            _targetType == TargetType.about) {
          targetAtLeast = double.tryParse(_targetAtLeastController.text);
          if (targetAtLeast == null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error'),
                content: Text('Invalid value for "at least"'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        } else {
          targetAtLeast = double.negativeInfinity;
        }
        double? targetAtMost;
        if (_targetType == TargetType.atMost ||
            _targetType == TargetType.about) {
          targetAtMost = double.tryParse(_targetAtMostController.text);
          if (targetAtMost == null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error'),
                content: Text('Invalid value for "at most"'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        } else {
          targetAtMost = double.infinity;
        }

        final targetType = _targetType;
        if (targetType == TargetType.about && (targetAtLeast > targetAtMost)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thông báo'),
              content: const Text(
                  'Bạn đang nhập dữ liệu mục tiêu nhỏ nhất lớn hơn mục tiêu lớn nhất'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
          return;
        }
        final unit = _unitController.text;

        // final isStartDateUndefined = _isStartDateUndefined;
        // final isStartTimeUndefined = _isStartTimeUndefined;
        // final isEndDateUndefined = _isEndDateUndefined;
        // final isEndTimeUndefined = _isEndTimeUndefined;
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

        final TimeInterval timeInterval = TimeInterval(
            id: id,
            title: title,
            isCompleted: isCompleted,
            description: description,
            location: location,
            color: color,
            subtasks: subtasks,
            targetType: targetType,
            targetAtLeast: targetAtLeast,
            targetAtMost: targetAtMost,
            unit: unit,
            // isEndDateUndefined: isEndDateUndefined,
            // isEndTimeUndefined: isEndTimeUndefined,
            // isStartDateUndefined: isStartDateUndefined,
            // isStartTimeUndefined: isStartTimeUndefined,
            howMuchHasBeenDone: howMuchHasBeenDone,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            isStartDateUndefined: startDate == null || _isStartDateUndefined,
            isEndDateUndefined: endDate == null || _isEndDateUndefined,
            isStartTimeUndefined: startTime == null || _isStartTimeUndefined,
            isEndTimeUndefined: endTime == null || _isEndTimeUndefined,
            taskId: widget.timeInterval!.taskId,
            measurableTaskId: widget.timeInterval!.measurableTaskId,
            taskWithSubtasksId: widget.timeInterval!.taskWithSubtasksId);
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
          widget.timeInterval == null
              ? await _databaseManager.insertTimeInterval(timeInterval)
              : await _databaseManager.updateTimeInterval(timeInterval);

          Navigator.pop(context, timeInterval);
          setState(() {});
        }
      }
    }
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
    // final textTheme = Theme.of(context)
    //     .textTheme
    //     .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    final timeIntervalColor = widget.timeInterval!.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: timeIntervalColor)
        : ColorScheme.light(primary: timeIntervalColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    final textTheme = Theme.of(context).textTheme.apply(bodyColor: labelColor);

    if (widget.timeInterval!.startDate != null) {
      _formattedStartDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval!.startDate!);
    } else {
      _formattedStartDate = '--/--/----';
    }

    if (widget.timeInterval!.startTime != null) {
      _formattedStartTime = widget.timeInterval!.startTime!.format(context);
    } else {
      _formattedStartTime = '--:--';
    }

    if (widget.timeInterval!.endDate != null) {
      _formattedEndDate = DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(widget.timeInterval!.endDate!);
    } else {
      _formattedEndDate = '--/--/----';
    }

    if (widget.timeInterval!.endTime != null) {
      _formattedEndTime = widget.timeInterval!.endTime!.format(context);
    } else {
      _formattedEndTime = '--:--';
    }
    double bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: widget.timeInterval == null
              ? Text('Add new time interval')
              : Text(''),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _onSave,
            ),
          ],
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Padding(
            //padding: const EdgeInsets.all(12.0),
            padding:
                EdgeInsets.only(left: 08, right: 08, top: 08, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.0, // khoảng cách giữa các Chip
                        children: <Widget>[
                          if (widget.timeInterval!.isGone == true)
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
                          if (widget.timeInterval!.isInProgress == true)
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
                          if (widget.timeInterval!.isToday == true)
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
                      // RichText(
                      //   text: TextSpan(
                      //     style: textTheme.labelMedium,
                      //     text: _formattedStartDate == _formattedEndDate
                      //         ? '$_formattedStartDate: $_formattedStartTime - $_formattedEndTime'
                      //         : '$_formattedStartDate: $_formattedStartTime - $_formattedEndDate: $_formattedEndTime',
                      //   ),
                      // ),
                    ],
                  ),
                ),
                ListTile(
                  title: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      decoration: _isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: labelColor,
                    ),
                    maxLines: null,
                    enabled: false, // This disables the TextField
                    decoration: InputDecoration(
                      hintText: 'Title',
                      filled:
                          true, // This is important, it enables the color fill
                      fillColor:
                          _timeIntervalColor, // This sets the background color
                      border:
                          OutlineInputBorder(), // This adds a border around the TextField
                    ),
                  ),
                ),
                const Divider(
                  height: 4,
                ),
                const SizedBox(height: 10),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                                    _startDateController.text = DateFormat(
                                            'EEE, dd MMM, yyyy',
                                            Localizations.localeOf(context)
                                                .languageCode)
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
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
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
                                  _endDateController.text = DateFormat(
                                          'EEE, dd MMM, yyyy',
                                          Localizations.localeOf(context)
                                              .languageCode)
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
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
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
                                              _startTimeController.text =
                                                  'undefined';
                                            } else {
                                              _startTimeController.clear();
                                            }
                                          });
                                        },
                                ),
                                border: OutlineInputBorder(),
                                labelText: 'Start time',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
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
                                  initialTime: TimeOfDay(
                                      hour: TimeOfDay.now().hour, minute: 0),
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
                                              _endTimeController.text =
                                                  'undefined';
                                            } else {
                                              _endTimeController.clear();
                                            }
                                          });
                                        },
                                ),
                                border: OutlineInputBorder(),
                                labelText: 'End time',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 08,
                ),
                const Divider(
                  height: 4,
                ),
                DescriptionListTile(
                    descriptionController: _descriptionController),
                CompletionListTile(
                  isCompleted: _isCompleted,
                  onCompletionChanged: (bool? newValue) {
                    setState(() {
                      _isCompleted = newValue!;
                    });
                  },
                ),
                LocationListTile(locationController: _locationController),
                if (widget.timeInterval!.measurableTaskId != null)
                  TargetBlockListTile(
                    unitController: _unitController,
                    targetAtLeastController: _targetAtLeastController,
                    targetAtMostController: _targetAtMostController,
                    hasBeenDoneController: _hasBeenDoneController,
                    targetType: _targetType,
                    onTargetTypeChanged: (value) =>
                        setState(() => _targetType = value),
                  ),
                const SizedBox(height: 12.0),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  ..._subtasks.map((subtask) => CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: subtask.isSubtaskCompleted,
                        onChanged: (value) => setState(
                            () => subtask.isSubtaskCompleted = value ?? false),
                        title: GestureDetector(
                          onTap: () async {
                            final TextEditingController _controller =
                                TextEditingController();
                            _controller.text = subtask.title;
                            final newTitle = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Edit Subtask'),
                                  content: TextField(
                                    controller: _controller,
                                    decoration:
                                        InputDecoration(labelText: 'Title'),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          context, _controller.text),
                                      child: Text('Save'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (newTitle != null) {
                              setState(() {
                                subtask.title = newTitle;
                              });
                            }
                          },
                          child: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isSubtaskCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _subtasks.remove(subtask);
                            });
                          },
                        ),
                      )),
                const SizedBox(height: 24.0),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  Row(children: [
                    ElevatedButton(
                      onPressed: () => _showAddSubtaskDialog(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 4),
                          Text('Add Subtask'),
                        ],
                      ),
                    )
                  ]),
              ],
            ),
          ),
        ));
  }

  void _showAddSubtaskDialog(BuildContext context) {
    final TextEditingController _subtaskTitleController =
        TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm subtask'),
        content: TextField(
          controller: _subtaskTitleController,
          decoration: InputDecoration(labelText: 'Tiêu đề'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _subtasks.add(Subtask(
                  isSubtaskCompleted: false,
                  title: _subtaskTitleController.text,
                ));
              });
              Navigator.pop(context);
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
