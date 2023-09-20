import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';

class TimeIntervalPage extends StatefulWidget {
  const TimeIntervalPage(
      {super.key, 
      this.task, 
      this.measurableTask, 
      this.taskWithSubtasks, 
      this.taskId, 
      this.measurableTaskId, 
      this.taskWithSubtasksId});
  final Task? task;
  final MeasurableTask? measurableTask;
  final TaskWithSubtasks? taskWithSubtasks;
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;

  @override
  _TimeIntervalPageState createState() => _TimeIntervalPageState();
}

class _TimeIntervalPageState extends State<TimeIntervalPage> {
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
  List<TimeInterval> _timeIntervals = [];
  bool _isAscending = true;

  Future<void> _onSaveTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.insertTimeInterval(timeInterval);
  }

  @override
  Widget build(BuildContext context) {
    String languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Time Interval'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 10),
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      maxLines: 1,
                      controller: _startDateController,
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
                                DateFormat('EEE, dd MMM, yyyy', languageCode).format(date);
                          }
                        }
                      },
                      validator: (value) {
                        if (!_isStartDateUndefined && value!.isEmpty) {
                          return 'Please enter a start date';
                        }
                        return null;
                      },
                      // decoration: const InputDecoration(
                      //   border: OutlineInputBorder(),
                      //   labelText: 'Start date',
                      //   floatingLabelBehavior: FloatingLabelBehavior.always,
                      // ),
                      enabled: !_isStartDateUndefined,
                    ),
                  ),
                  Checkbox(
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
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
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
                      // decoration: const InputDecoration(
                      //   border: OutlineInputBorder(),
                      //   labelText: 'Start time',
                      //   floatingLabelBehavior: FloatingLabelBehavior.always,
                      // ),
                      enabled: !_isStartTimeUndefined,
                    ),
                  ),
                  Checkbox(
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
                ],
              ),
            ),
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      maxLines: 1,
                      controller: _endDateController,
                      enabled: !_isEndDateUndefined,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _endDateController.text =
                              DateFormat('EEE, dd MMM, yyyy', languageCode).format(date);
                        }
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an end date';
                        }
                        return null;
                      },
                      // decoration: const InputDecoration(
                      //   border: OutlineInputBorder(),
                      //   labelText: 'End date',
                      //   floatingLabelBehavior: FloatingLabelBehavior.always,
                      // ),
                    ),
                  ),
                  Checkbox(
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
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      maxLines: 1,
                      controller: _endTimeController,
                      enabled: !_isEndTimeUndefined,
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
                      // decoration: const InputDecoration(
                      //   border: OutlineInputBorder(),
                      //   labelText: 'End time',
                      //   floatingLabelBehavior: FloatingLabelBehavior.always,
                      // ),
                    ),
                  ),
                  Checkbox(
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
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
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
                              ? DateFormat('EEE, dd MMM, yyyy', languageCode)
                                  .parse(_startDateController.text)
                              : null;
                          final endDate = !_isEndDateUndefined
                              ? DateFormat('EEE, dd MMM, yyyy', languageCode)
                                  .parse(_endDateController.text)
                              : null;
                          final startTime = !_isStartTimeUndefined
                              ? TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                  .parse(_startTimeController.text))
                              : null;
                          final endTime = !_isEndTimeUndefined
                              ? TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                  .parse(_endTimeController.text))
                              : null;
                          final timeInterval = TimeInterval(
                            taskId: widget.task?.id,
                            measurableTaskId: widget.measurableTask?.id,
                            taskWithSubtasksId: widget.taskWithSubtasks?.id,
                            color: widget.task != null
                                ? widget.task!.color
                                : widget.measurableTask != null
                                    ? widget.measurableTask!.color
                                    : widget.taskWithSubtasks != null
                                        ? widget.taskWithSubtasks!.color
                                        : const Color(0xff000000),
                            title: widget.task != null
                                ? widget.task!.title
                                : widget.measurableTask != null
                                    ? widget.measurableTask!.title
                                    : widget.taskWithSubtasks != null
                                        ? widget.taskWithSubtasks!.title
                                        : '',
                            startDate: startDate,
                            endDate: endDate,
                            startTime: startTime,
                            endTime: endTime,
                            isStartDateUndefined:
                                startDate == null || _isStartDateUndefined,
                            isEndDateUndefined:
                                endDate == null || _isEndDateUndefined,
                            isStartTimeUndefined:
                                startTime == null || _isStartTimeUndefined,
                            isEndTimeUndefined:
                                endTime == null || _isEndTimeUndefined,
                            subtasks: widget.taskWithSubtasks != null
                                ? widget.taskWithSubtasks!.subtasks
                                    .map((subtask) => Subtask(
                                          isSubtaskCompleted: false,
                                          title: subtask.title,
                                        ))
                                    .toList()
                                : null,
                            targetType: widget.measurableTask != null
                                ? widget.measurableTask!.targetType
                                : null,
                            targetAtLeast: widget.measurableTask != null
                                ? widget.measurableTask!.targetAtLeast
                                : null,
                            targetAtMost: widget.measurableTask != null
                                ? widget.measurableTask!.targetAtMost
                                : null,
                            unit: widget.measurableTask != null
                                ? widget.measurableTask!.unit
                                : null,
                            howMuchHasBeenDone:
                                widget.measurableTask != null ? 0.0 : null,
                          );
                          if (timeInterval.startTimestamp != null &&
                              timeInterval.endTimestamp != null &&
                              timeInterval.startTimestamp! >
                                  timeInterval.endTimestamp!) {
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
                            await _databaseManager
                                .insertTimeInterval(timeInterval);
                          }
                          setState(() {
                            _timeIntervals.add(timeInterval);
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
                    },
                    child: Text('Submit'),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _timeIntervals.sort((a, b) =>
                            (_isAscending ? 1 : -1) *
                            ((a.startTimestamp ?? a.endTimestamp)! -
                                        (b.startTimestamp ?? b.endTimestamp)! <
                                    0
                                ? -1
                                : 1));
                        _isAscending = !_isAscending;
                      });
                    },
                    child: Text(
                        _isAscending ? 'Sort Descending' : 'Sort Ascending'),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
                child: CustomScrollView(
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final timeInterval = _timeIntervals[index];
                      return ListTile(
                        // shape: RoundedRectangleBorder(
                        //   side: BorderSide(color: Colors.black, width: 2),
                        //   borderRadius: BorderRadius.circular(10),
                        // ),
                        title: Wrap(children: [
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      maxLines: 1,
                                      initialValue: timeInterval.startDate !=
                                              null
                                          ? DateFormat('EEE,dd MMM, yyyy', languageCode)
                                              .format(timeInterval.startDate!)
                                          : 'undefined',
                                      // decoration: const InputDecoration(
                                      //   border: OutlineInputBorder(),
                                      //   labelText: 'Start date',
                                      //   floatingLabelBehavior:
                                      //       FloatingLabelBehavior.always,
                                      // ),
                                      enabled: false,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      maxLines: 1,
                                      initialValue: timeInterval.startTime !=
                                              null
                                          ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}'
                                          : 'undefined',
                                      // decoration: const InputDecoration(
                                      //   border: OutlineInputBorder(),
                                      //   labelText: 'Start time',
                                      //   floatingLabelBehavior:
                                      //       FloatingLabelBehavior.always,
                                      // ),
                                      enabled: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      maxLines: 1,
                                      initialValue: timeInterval.endDate != null
                                          ? DateFormat('EEE, dd MMM, yyyy', languageCode)
                                              .format(timeInterval.endDate!)
                                          : 'undefined',
                                      // decoration: const InputDecoration(
                                      //   border: OutlineInputBorder(),
                                      //   labelText: 'End date',
                                      //   floatingLabelBehavior:
                                      //       FloatingLabelBehavior.always,
                                      // ),
                                      enabled: false,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      maxLines: 1,
                                      initialValue: timeInterval.endTime != null
                                          ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}'
                                          : 'undefined',
                                      // decoration: const InputDecoration(
                                      //   border: OutlineInputBorder(),
                                      //   labelText: 'End time',
                                      //   floatingLabelBehavior:
                                      //       FloatingLabelBehavior.always,
                                      // ),
                                      enabled: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ]),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            // Handle selected option
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'Mark completed',
                              child: Text('Mark completed'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Mark incompleted',
                              child: Text('Mark incompleted'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Edit time interval',
                              child: Text('Edit time interval'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Delete time interval',
                              child: Text('Delete time interval'),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _timeIntervals.length,
                  ),
                )
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}
