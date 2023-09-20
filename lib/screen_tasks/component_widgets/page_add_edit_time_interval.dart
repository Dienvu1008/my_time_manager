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
  //bool _isImportant = false;

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
      widget.timeInterval?.startDate != null
          ? _startDateController.text =
              widget.timeInterval!.startDate.toString()
          : _startDateController.text = '--/--/----';
      widget.timeInterval?.endDate != null
          ? _endDateController.text = widget.timeInterval!.endDate.toString()
          : _endDateController.text = '--/--/----';
      widget.timeInterval?.startTime != null
          ? _startTimeController.text =
              widget.timeInterval!.startTime.toString()
          : _startTimeController.text = '--:--';
      widget.timeInterval?.endTime != null
          ? _endTimeController.text =
              widget.timeInterval!.endTime.toString()
          : _endTimeController.text = '--:--';
    } else {
      _id = const Uuid().v4();
    }
  }

  Future<void> _onSave() async {
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

    // if (title.isEmpty) {
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: const Text('Thông báo'),
    //       content: const Text('Bạn chưa nhập tiêu đề của nhiệm vụ'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: const Text('Đóng'),
    //         ),
    //       ],
    //     ),
    //   );
    //   return;
    // }

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

    final isStartDateUndefined = _isStartDateUndefined;
    final isStartTimeUndefined = _isStartTimeUndefined;
    final isEndDateUndefined = _isEndDateUndefined;
    final isEndTimeUndefined = _isEndTimeUndefined;

    final TimeInterval timeInterval = widget.timeInterval == null
        ? TimeInterval(
            title: title,
            isCompleted: isCompleted,
            description: description,
            location: location,
            color: color,
            subtasks: subtasks,
          )
        : TimeInterval(
            id: widget.timeInterval!.id,
            title: title,
            description: description,
            location: location,
            isCompleted: isCompleted,
            color: color,
            subtasks: subtasks,
          );

    widget.timeInterval == null
        ? await _databaseManager.insertTimeInterval(
            TimeInterval(
              id: id,
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              subtasks: subtasks,
            ),
          )
        : await _databaseManager.updateTimeInterval(
            TimeInterval(
              id: widget.timeInterval!.id,
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              subtasks: subtasks,
            ),
          );

    Navigator.pop(context, timeInterval);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    final String formattedStartDate = widget.timeInterval!.startDate != null
        ? DateFormat.yMMMd().format(widget.timeInterval!.startDate!)
        : '--/--/----';
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
                // Text('List: ${widget.taskList.title}',
                //     style: textTheme.titleLarge!),
                // const SizedBox(height: 24.0),
                ListTile(
                  // title: Text(
                  //   widget.timeInterval.title,
                  //   style: TextStyle(
                  //     color: labelColor,
                  //     decoration: widget.timeInterval.isCompleted
                  //         ? TextDecoration.lineThrough
                  //         : null,
                  //   ),
                  // ),
                  // subtitle: widget.timeInterval.description.isNotEmpty
                  //     ? Text(
                  //         widget.timeInterval.description,
                  //         style: TextStyle(color: labelColor),
                  //       )
                  //     : null,(
                  title: Text(
                    '$formattedStartDate: ${widget.timeInterval!.startTime!.format(context)} - ${widget.timeInterval!.endTime!.format(context)}',
                    style: textTheme.labelSmall,
                  ),
                ),
                ListTile(
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: 0.0, right: 0.0),
                    child: ColorSeedButton(
                      colorSelected: ColorSeed.values.firstWhere(
                        (e) => e.color.value == _timeIntervalColor.value,
                        orElse: () => ColorSeed.baseColor,
                      ),
                      handleColorSelect: (index) {
                        setState(() {
                          _timeIntervalColor = ColorSeed.values[index].color;
                        });
                      },
                    ),
                  ),
                  title: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      decoration: _isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Divider(
                  height: 4,
                ),
                // ListTile(
                //   leading: const Padding(
                //     padding: EdgeInsets.only(left: 0.0, right: 4.0),
                //     child: Icon(Icons.description_outlined),
                //   ),
                //   title: TextField(
                //     controller: _descriptionController,
                //     maxLines: null,
                //     decoration: const InputDecoration(
                //       hintText: 'Description',
                //       border: InputBorder.none,
                //     ),
                //   ),
                // ),
                // const Divider(
                //   height: 4,
                // ),
                DescriptionListTile(
                    descriptionController: _descriptionController),
                // ListTile(
                //   leading: Padding(
                //     padding: EdgeInsets.only(left: 0.0, right: 4.0),
                //     child: Icon(
                //       _isCompleted
                //           ? Icons.check_box
                //           : Icons.check_box_outline_blank,
                //     ),
                //   ),
                //   title: DropdownButtonHideUnderline(
                //     child: DropdownButton<bool>(
                //       isDense: true,
                //       value: _isCompleted,
                //       onChanged: (bool? newValue) {
                //         setState(() {
                //           _isCompleted = newValue!;
                //         });
                //       },
                //       items: <bool>[true, false]
                //           .map<DropdownMenuItem<bool>>((bool value) {
                //         return DropdownMenuItem<bool>(
                //           value: value,
                //           child: Text(value ? 'Completed' : 'Incompleted'),
                //         );
                //       }).toList(),
                //     ),
                //   ),
                // ),
                // const Divider(
                //   height: 4,
                // ),
                CompletionListTile(
                  isCompleted: _isCompleted,
                  onCompletionChanged: (bool? newValue) {
                    setState(() {
                      _isCompleted = newValue!;
                    });
                  },
                ),
                // ListTile(
                //   leading: Padding(
                //     padding: EdgeInsets.only(left: 0.0, right: 4.0),
                //     child: Icon(
                //       _isImportant ? Icons.star : Icons.star_border,
                //     ),
                //   ),
                //   title: DropdownButtonHideUnderline(
                //     child: DropdownButton<bool>(
                //       isDense: true,
                //       value: _isImportant,
                //       onChanged: (bool? newValue) {
                //         setState(() {
                //           _isImportant = newValue!;
                //         });
                //       },
                //       items: <bool>[true, false]
                //           .map<DropdownMenuItem<bool>>((bool value) {
                //         return DropdownMenuItem<bool>(
                //           value: value,
                //           child: Text(value ? 'Important' : 'Not Important'),
                //         );
                //       }).toList(),
                //     ),
                //   ),
                // ),
                // const Divider(
                //   height: 4,
                // ),
                // ListTile(
                //   leading: const Padding(
                //     padding: EdgeInsets.only(left: 0.0, right: 4.0),
                //     child: Icon(Icons.location_on_outlined),
                //   ),
                //   title: TextField(
                //     controller: _locationController,
                //     maxLines: null,
                //     decoration: const InputDecoration(
                //       hintText: 'Location',
                //       border: InputBorder.none,
                //     ),
                //   ),
                //   trailing: ElevatedButton(
                //     child: const Text('MAP'),
                //     onPressed: () => {
                //       launchURL(Uri.parse(
                //           'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_locationController.text)}')),
                //     },
                //   ),
                // ),
                // const Divider(
                //   height: 4,
                // ),
                LocationListTile(locationController: _locationController),
                // const SizedBox(height: 12.0),

                // Row(
                //   children: [
                //     Expanded(
                //       child: DropdownButtonFormField<TargetType>(
                //         value: _targetType,
                //         onChanged: (value) =>
                //             setState(() => _targetType = value!),
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
                //               floatingLabelBehavior:
                //                   FloatingLabelBehavior.auto),
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
                //               floatingLabelBehavior:
                //                   FloatingLabelBehavior.auto),
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
