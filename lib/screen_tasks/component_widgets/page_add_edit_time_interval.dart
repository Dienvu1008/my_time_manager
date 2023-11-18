import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_set_time_intervals_block.dart';
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
  bool _isImportant = false;
  String _id = '';

  // String _formattedStartDate = '--/--/----';
  // String _formattedStartTime = '--:--';
  // String _formattedEndDate = '--/--/----';
  // String _formattedEndTime = '--:--';

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
      _isImportant = widget.timeInterval!.isImportant;

      _isStartDateUndefined = widget.timeInterval!.isStartDateUndefined;
      _isStartTimeUndefined = widget.timeInterval!.isStartTimeUndefined;
      _isEndDateUndefined = widget.timeInterval!.isEndDateUndefined;
      _isEndTimeUndefined = widget.timeInterval!.isEndTimeUndefined;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.timeInterval?.startDate != null) {
          (
            _startDateController.text = DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .format(widget.timeInterval!.startDate!),
            //_isStartDateUndefined = false,
          );
        } else {
          _startDateController.text = 'undefined';
          //_isStartDateUndefined = true;
          //_isStartTimeUndefined = true;
        }

        if (widget.timeInterval?.endDate != null) {
          (
            _endDateController.text = DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .format(widget.timeInterval!.endDate!),
            //_isEndDateUndefined = false
          );
        } else {
          _endDateController.text = 'undefined';
          //_isEndDateUndefined = true;
          //_isEndTimeUndefined = true;
        }
        widget.timeInterval?.startTime != null
            ? (
                _startTimeController.text =
                    widget.timeInterval!.startTime!.format(context),
                //_isStartTimeUndefined = false,
                //_isStartDateUndefined = false
              )
            : (
                _startTimeController.text = 'undefined',
                //_isStartTimeUndefined = true
              );
        widget.timeInterval?.endTime != null
            ? (
                _endTimeController.text =
                    widget.timeInterval!.endTime!.format(context),
                //_isEndTimeUndefined = false,
                //_isEndDateUndefined = false
              )
            : (
                _endTimeController.text = 'undefined',
                //_isEndTimeUndefined = true
              );
      });
    } else {
      _id = const Uuid().v4();
    }
  }

  Future<void> _onSave() async {
    //if (_formKey.currentState!.validate()) {
    if (_isStartDateUndefined &&
        _isEndDateUndefined &&
        _isStartTimeUndefined &&
        _isEndTimeUndefined) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(AppLocalizations.of(context)!.enterAtLeastOneDate),
        ),
      );
    } else {
      final id = _id;
      final title = _titleController.text;
      final description = _descriptionController.text;
      final location = _locationController.text;
      final isCompleted = widget.timeInterval == null ? false : _isCompleted;
      final isImportant = widget.timeInterval == null ? false : _isImportant;
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
      if (_targetType == TargetType.atMost || _targetType == TargetType.about) {
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
            title: Text(AppLocalizations.of(context)!.notification),
            content: Text(
                AppLocalizations.of(context)!.minTargetGreaterThanMaxTarget),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
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

      // final startDate = !_isStartDateUndefined
      //     ? DateFormat('EEE, dd MMM, yyyy',
      //             Localizations.localeOf(context).languageCode)
      //         .parse(_startDateController.text)
      //     : null;
      // final endDate = !_isEndDateUndefined
      //     ? DateFormat('EEE, dd MMM, yyyy',
      //             Localizations.localeOf(context).languageCode)
      //         .parse(_endDateController.text)
      //     : null;
      // final startTime = !_isStartTimeUndefined
      //     ? TimeOfDay.fromDateTime(
      //         DateFormat('HH:mm').parse(_startTimeController.text))
      //     : null;
      // final endTime = !_isEndTimeUndefined
      //     ? TimeOfDay.fromDateTime(
      //         DateFormat('HH:mm').parse(_endTimeController.text))
      //     : null;

      final startDate = !_isStartDateUndefined
          ? (() {
              try {
                return DateFormat('EEE, dd MMM, yyyy',
                        Localizations.localeOf(context).languageCode)
                    .parse(_startDateController.text);
              } catch (_) {
                // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                return null;
              }
            })()
          : null;
      final endDate = !_isEndDateUndefined
          ? (() {
              try {
                return DateFormat('EEE, dd MMM, yyyy',
                        Localizations.localeOf(context).languageCode)
                    .parse(_endDateController.text);
              } catch (_) {
                // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                return null;
              }
            })()
          : null;
      final startTime = !_isStartTimeUndefined
          ? (() {
              try {
                return TimeOfDay.fromDateTime(
                    DateFormat('HH:mm').parse(_startTimeController.text));
              } catch (_) {
                // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                return null;
              }
            })()
          : null;
      final endTime = !_isEndTimeUndefined
          ? (() {
              try {
                return TimeOfDay.fromDateTime(
                    DateFormat('HH:mm').parse(_endTimeController.text));
              } catch (_) {
                // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                return null;
              }
            })()
          : null;

      final TimeInterval timeInterval = TimeInterval(
          id: id,
          title: title,
          isCompleted: isCompleted,
          isImportant: isImportant,
          description: description,
          location: location,
          color: color,
          subtasks: subtasks,
          targetType: targetType,
          targetAtLeast: targetAtLeast,
          targetAtMost: targetAtMost,
          unit: unit,
          // isEndDateUndefined: _isEndDateUndefined,
          // isEndTimeUndefined: _isEndTimeUndefined,
          // isStartDateUndefined: _isStartDateUndefined,
          // isStartTimeUndefined: _isStartTimeUndefined,
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
      if ((timeInterval.startTimestamp != null &&
              timeInterval.endTimestamp != null &&
              timeInterval.startTimestamp! > timeInterval.endTimestamp!) ||
          (timeInterval.startDate != null &&
              timeInterval.endDate != null &&
              timeInterval.startDate!.isAfter(timeInterval.endDate!)) ||
          (timeInterval.startDate != null &&
              timeInterval.endDate != null &&
              timeInterval.startDate!.isAtSameMomentAs(timeInterval.endDate!) &&
              timeInterval.startTime != null &&
              timeInterval.endTime != null &&
              (timeInterval.startTime!.hour * 60 +
                      timeInterval.startTime!.minute) >
                  (timeInterval.startTime!.hour * 60 +
                      timeInterval.startTime!.minute))) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.error),
              content: Text(
                  AppLocalizations.of(context)!.startTimeAfterEndTime),
              actions: <Widget>[
                TextButton(
                  child: Text(AppLocalizations.of(context)!.close),
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
    //}
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
    final localizations = AppLocalizations.of(context);
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
    String languageCode = Localizations.localeOf(context).languageCode;

    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: widget.timeInterval == null
              ? Text('Add new time interval')
              : Text(localizations!.editThisTimeInterval),
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
                          if (widget.timeInterval!.isImportant == true)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                    5), // bo tròn viền tại đây
                              ),
                              child: Text(
                                localizations!.important,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          if (widget.timeInterval!.isGone == true)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                    5), // bo tròn viền tại đây
                              ),
                              child: Text(
                                localizations!.gone,
                                style: const TextStyle(
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
                              child: Text(
                                localizations!.inProgress,
                                style: const TextStyle(
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
                              child: Text(
                                localizations!.today,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
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
                      hintText: localizations!.title,
                      filled:
                          true, // This is important, it enables the color fill
                      fillColor:
                          _timeIntervalColor, // This sets the background color
                      border:
                          OutlineInputBorder(), // This adds a border around the TextField
                    ),
                  ),
                ),

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
                  formKey: _formKey,
                ),
                const SizedBox(
                  height: 08,
                ),

                DescriptionListTile(
                    descriptionController: _descriptionController),
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
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  const SizedBox(height: 12.0),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  ..._subtasks.reversed.map((subtask) => CheckboxListTile(
                        dense: true,
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
                                  title: Text(localizations.editSubtask),
                                  content: TextField(
                                    controller: _controller,
                                    decoration:
                                        InputDecoration(labelText: localizations.title),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(localizations.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          context, _controller.text),
                                      child: Text(localizations.save),
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
                const SizedBox(height: 12.0),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  Row(children: [
                    ElevatedButton(
                      onPressed: () => _showAddSubtaskDialog(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add),
                          const SizedBox(width: 4),
                          Text(localizations.addSubtask),
                        ],
                      ),
                    ),
                  ]),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  const SizedBox(height: 12),
                if (widget.timeInterval!.taskWithSubtasksId != null)
                  const Divider(
                    height: 4,
                  ),
                LocationListTile(locationController: _locationController),
                CompletionListTile(
                  isUsedForTimeInterval: true,
                  isCompleted: _isCompleted,
                  onCompletionChanged: (bool? newValue) {
                    setState(() {
                      _isCompleted = newValue!;
                    });
                  },
                ),
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
        title: Text(AppLocalizations.of(context)!.addSubtask),
        content: TextField(
          controller: _subtaskTitleController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }
}
