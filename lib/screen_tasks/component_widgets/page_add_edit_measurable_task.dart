import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_importance.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_schedule.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_target_block.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_tasklist.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_title.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

class AddOrEditMeasurableTaskPage extends StatefulWidget {
  const AddOrEditMeasurableTaskPage(
      {Key? key, this.measurableTask, required this.taskList})
      : super(key: key);
  final TaskList taskList;
  final MeasurableTask? measurableTask;

  @override
  _AddOrEditMeasurableTaskPageState createState() =>
      _AddOrEditMeasurableTaskPageState();
}

class _AddOrEditMeasurableTaskPageState
    extends State<AddOrEditMeasurableTaskPage> {
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

  Color _measurableTaskColor = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;
  String _id = '';

  @override
  void initState() {
    super.initState();
    if (widget.measurableTask != null) {
      widget.measurableTask?.title != null
          ? _titleController.text = widget.measurableTask!.title
          : _titleController.text = '';
      widget.measurableTask?.description != null
          ? _descriptionController.text = widget.measurableTask!.description
          : _descriptionController.text = '';
      widget.measurableTask?.location != null
          ? _locationController.text = widget.measurableTask!.location
          : _locationController.text = '';
      widget.measurableTask?.unit != null
          ? _unitController.text = widget.measurableTask!.unit
          : _unitController.text = '';
      widget.measurableTask?.targetAtLeast != null
          ? _targetAtLeastController.text =
              widget.measurableTask!.targetAtLeast.toString()
          : _targetAtLeastController.text = '';
      widget.measurableTask?.targetAtMost != null
          ? _targetAtMostController.text =
              widget.measurableTask!.targetAtMost.toString()
          : _targetAtMostController.text = '';
      widget.measurableTask?.howMuchHasBeenDone != null
          ? _hasBeenDoneController.text =
              widget.measurableTask!.howMuchHasBeenDone.toString()
          : _hasBeenDoneController.text = '0.0';
      widget.measurableTask?.targetType != null
          ? _targetType = widget.measurableTask!.targetType
          : _targetType = TargetType.about;
      _measurableTaskColor = widget.measurableTask!.color;
      _id = widget.measurableTask!.id;
      _isCompleted = widget.measurableTask!.isCompleted;
      _isImportant = widget.measurableTask!.isImportant;
    } else {
      _id = const Uuid().v4();
    }
  }

  Future<void> _onSave() async {
    final id = _id;
    final title = _titleController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final isCompleted = widget.measurableTask == null ? false : _isCompleted;
    final isImportant = widget.measurableTask == null ? false : _isImportant;
    final color = _measurableTaskColor;
    final taskListId = widget.taskList.id;
    final howMuchHasBeenDone = _hasBeenDoneController.text == ''
        ? double.parse('0.0')
        : double.parse(_hasBeenDoneController.text);
    double? targetAtLeast;
    if (_targetType == TargetType.atLeast || _targetType == TargetType.about) {
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
    final unit = _unitController.text;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.notification),
          content: Text(AppLocalizations.of(context)!.enterTaskTitle),
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

    if (targetType == TargetType.about && (targetAtLeast > targetAtMost)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.notification),
          content:
              Text(AppLocalizations.of(context)!.minTargetGreaterThanMaxTarget),
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

    final MeasurableTask measurableTask = MeasurableTask(
      id: id,
      title: title,
      isCompleted: isCompleted,
      isImportant: isImportant,
      description: description,
      location: location,
      color: color,
      taskListId: taskListId,
      targetAtLeast: targetAtLeast,
      targetAtMost: targetAtMost,
      targetType: targetType,
      unit: unit,
      howMuchHasBeenDone: howMuchHasBeenDone,
    );

    // Add save code here
    widget.measurableTask == null
        ? await _databaseManager.insertMeasurableTask(measurableTask)
        : await _databaseManager.updateMeasurableTask(measurableTask);
    Navigator.pop(context, measurableTask);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: widget.measurableTask == null
            ? Text(localizations!.addANewMeasureableTask)
            : Text(''),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _onSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Padding(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskListListTile(
                title: widget.taskList.title,
                style: textTheme.titleLarge!,
              ),
              TitleListTile(
                titleController: _titleController,
                isCompleted: _isCompleted,
                itemColor: _measurableTaskColor,
                handleColorSelect: (index) {
                  setState(() {
                    _measurableTaskColor = ColorSeed.values[index].color;
                  });
                },
              ),

              TargetBlockListTile(
                unitController: _unitController,
                targetAtLeastController: _targetAtLeastController,
                targetAtMostController: _targetAtMostController,
                hasBeenDoneController: _hasBeenDoneController,
                targetType: _targetType,
                onTargetTypeChanged: (value) =>
                    setState(() => _targetType = value),
              ),
              DescriptionListTile(
                  descriptionController: _descriptionController),
              if (widget.measurableTask != null)
                ScheduleListTile(
                  title: widget.measurableTask!.title,
                  color: widget.measurableTask!.color,
                  description: widget.measurableTask!.description,
                  location: widget.measurableTask!.location,
                  targetAtLeast: widget.measurableTask!.targetAtLeast,
                  targetAtMost: widget.measurableTask!.targetAtMost,
                  targetType: widget.measurableTask!.targetType,
                  unit: widget.measurableTask!.unit,
                  subtasks: [],
                  measurableTaskId: _id,
                ),
              LocationListTile(locationController: _locationController),
              CompletionListTile(
                isCompleted: _isCompleted,
                onCompletionChanged: (bool? newValue) {
                  setState(() {
                    _isCompleted = newValue!;
                  });
                },
              ),
              ImportanceListTile(
                isImportant: _isImportant,
                onImportanceChanged: (bool? newValue) {
                  setState(() {
                    _isImportant = newValue!;
                  });
                },
              ),

              // Row(
              //   children: [
              //     Expanded(
              //       child: DropdownButtonFormField<TargetType>(
              //         value: _targetType,
              //        onChanged: (value) =>
              //            setState(() => _targetType = value!),
              //         items: TargetType.values
              //             .map((e) => DropdownMenuItem(
              //                   value: e,
              //                   child: Text(e == TargetType.atLeast
              //                       ? 'at least'
              //                       : e == TargetType.atMost
              //                           ? 'at most'
              //                           : 'about'),
              //                 ))
              //             .toList(),
              //         decoration: const InputDecoration(
              //             border: OutlineInputBorder(),
              //             labelText: 'Target Type',
              //             floatingLabelBehavior: FloatingLabelBehavior.auto),
              //         validator: (value) {
              //           if (value == null) {
              //             return 'Please select a target type';
              //           }
              //           return null;
              //         },
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: TextFormField(
              //         controller: _unitController,
              //         decoration: const InputDecoration(
              //             border: OutlineInputBorder(),
              //             labelText: 'Unit',
              //             floatingLabelBehavior: FloatingLabelBehavior.auto),
              //         validator: (value) {
              //           if (value == null || value.isEmpty) {
              //             return 'Please input unit';
              //           }
              //           return null;
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 12),
              // Row(
              //   children: [
              //     if (_targetType == TargetType.atLeast ||
              //         _targetType == TargetType.about)
              //       Expanded(
              //         child: TextFormField(
              //           controller: _targetAtLeastController,
              //           decoration: const InputDecoration(
              //               border: OutlineInputBorder(),
              //               labelText: 'min.',
              //               floatingLabelBehavior: FloatingLabelBehavior.auto),
              //           keyboardType: const TextInputType.numberWithOptions(
              //               decimal: true, signed: false),
              //           validator: (value) {
              //             if (value == null || value.isEmpty) {
              //               return 'Vui lòng nhập giá trị ít nhất';
              //             }
              //             if (double.tryParse(value) == null) {
              //               return 'Vui lòng nhập số';
              //             }
              //             return null;
              //           },
              //         ),
              //       ),
              //     if (_targetType == TargetType.about)
              //       const SizedBox(width: 12),
              //     if (_targetType == TargetType.atMost ||
              //         _targetType == TargetType.about)
              //       Expanded(
              //         child: TextFormField(
              //           controller: _targetAtMostController,
              //           decoration: const InputDecoration(
              //               border: OutlineInputBorder(),
              //               labelText: 'max.',
              //               floatingLabelBehavior: FloatingLabelBehavior.auto),
              //           keyboardType: const TextInputType.numberWithOptions(
              //               decimal: true, signed: false),
              //           validator: (value) {
              //             if (value == null || value.isEmpty) {
              //               return 'Vui lòng nhập giá trị nhiều nhất';
              //             }
              //             if (double.tryParse(value) == null) {
              //               return 'Vui lòng nhập số';
              //             }
              //             return null;
              //           },
              //         ),
              //       ),
              //   ],
              // ),
              // const SizedBox(height: 12),
              // Row(
              //   children: [
              //     Expanded(
              //       child: TextFormField(
              //         controller: _hasBeenDoneController,
              //         decoration: const InputDecoration(
              //             border: OutlineInputBorder(),
              //             labelText: 'Has been done',
              //             floatingLabelBehavior: FloatingLabelBehavior.auto),
              //         keyboardType: const TextInputType.numberWithOptions(
              //             decimal: true, signed: false),
              //         validator: (value) {
              //           if (value == null || value.isEmpty) {
              //             return 'Vui lòng nhập giá trị';
              //           }
              //           if (double.tryParse(value) == null) {
              //             return 'Vui lòng nhập số';
              //           }
              //           return null;
              //         },
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
