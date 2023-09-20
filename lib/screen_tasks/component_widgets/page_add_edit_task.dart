import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_set_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_time_intervals.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_importance.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_schedule.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_tasklist.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_title.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_time_interval.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

class AddOrEditTaskPage extends StatefulWidget {
  const AddOrEditTaskPage({Key? key, this.task, required this.taskList});
  final TaskList taskList;
  final Task? task;
  //final Color taskColor;

  @override
  _AddOrEditTaskPageState createState() => _AddOrEditTaskPageState();
}

class _AddOrEditTaskPageState extends State<AddOrEditTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final DatabaseManager _databaseManager = DatabaseManager();
  String _id = '';

  Color _taskColor = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;

  @override
  void initState() {
    if (widget.task != null) {
      widget.task?.title != null
          ? _titleController.text = widget.task!.title
          : _titleController.text = '';
      widget.task?.description != null
          ? _descriptionController.text = widget.task!.description
          : _descriptionController.text = '';
      widget.task?.location != null
          ? _locationController.text = widget.task!.location
          : _locationController.text = '';
      _id = widget.task!.id;
      _taskColor = widget.task!.color;
      _isCompleted = widget.task!.isCompleted;
      _isImportant = widget.task!.isImportant;
    } else {
      _id = const Uuid().v4();
    }
    super.initState();
  }

  Future<void> _onSave() async {
    final id = _id;
    final title = _titleController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final isCompleted = widget.task == null ? false : _isCompleted;
    final isImportant = widget.task == null ? false : _isImportant;
    final color = _taskColor;
    final taskListId = widget.taskList.id;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Bạn chưa nhập tiêu đề của nhiệm vụ'),
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

    final task = Task(
      id: id,
      title: title,
      description: description,
      location: location,
      isCompleted: isCompleted,
      isImportant: isImportant,
      color: color,
      taskListId: taskListId,
    );

    // Add save code here
    widget.task == null
        ? await _databaseManager.insertTask(task)
        : await _databaseManager.updateTask(task);

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title:
              widget.task == null ? const Text('Add new task') : const Text(''),
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
            padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TaskListListTile(
                  title: widget.taskList.title,
                  style: textTheme.titleMedium!,
                ),
                TitleListTile(
                  itemColor: _taskColor,
                  titleController: _titleController,
                  isCompleted: _isCompleted,
                  handleColorSelect: (index) {
                    setState(() {
                      _taskColor = ColorSeed.values[index].color;
                    });
                  },
                ),
                DescriptionListTile(
                  descriptionController: _descriptionController,
                ),
                LocationListTile(
                  locationController: _locationController,
                ),
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
                ListTile(
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 0.0, right: 4.0),
                    child: Icon(Icons.attach_file_outlined),
                  ),
                  title: Text('Attach File'),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const ListTile(
                              title: Text('Upload from'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.folder_open_outlined),
                              title: Text('Device files'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Thêm mã để xử lý khi người dùng chọn "Device files"
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles();
                                if (result != null) {
                                  PlatformFile file = result.files.first;
                                  print(
                                      file.path); // Đường dẫn đến tệp được chọn
                                  print(file.name); // Tên tệp được chọn
                                  print(file.size); // Kích thước tệp được chọn
                                  print(file
                                      .extension); // Phần mở rộng của tệp được chọn
                                  print(
                                      file.bytes); // Nội dung của tệp được chọn
                                } else {
                                  // Người dùng hủy bỏ việc chọn tệp
                                }
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.camera_alt_outlined),
                              title: Text('Camera'),
                              onTap: () async {
                                Navigator.pop(context);
                                // Thêm mã để xử lý khi người dùng chọn "Camera"
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                    source: ImageSource.camera);
                                if (pickedFile != null) {
                                  final file = File(pickedFile.path);
                                  print(file.uri); // Uri của ảnh được chụp
                                } else {
                                  // Người dùng hủy bỏ việc chụp ảnh
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const Divider(
                  height: 4,
                ),
                // ListTile(
                //   leading: const Padding(
                //     padding: EdgeInsets.only(left: 0.0, right: 4.0),
                //     child: Icon(Icons.calendar_month_outlined),
                //   ),
                //   title: Text('Schedule'),
                //   onTap: () {
                //     showModalBottomSheet(
                //       context: context,
                //       isScrollControlled: true,
                //       builder: (BuildContext context) =>
                //           SetTimeIntervalBottomSheet(),
                //     );
                //   },
                //   trailing: ElevatedButton(
                //     child: Text('Planned'),
                //     onPressed: () => {
                //       showModalBottomSheet(
                //         context: context,
                //         isScrollControlled: true,
                //         showDragHandle: true,
                //         builder: (BuildContext context) =>
                //             ShowTimeIntervalsBottomSheet(id: _id),
                //       ),
                //     },
                //   ),
                // ),
                // const Divider(
                //   height: 4,
                // ),
                ScheduleListTile(taskId: _id,)
              ],
            ),
          ),
        ));
  }
}
