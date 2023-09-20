import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:uuid/uuid.dart';

class AddOrEditTaskListPage extends StatefulWidget {
  const AddOrEditTaskListPage({Key? key, this.taskList}) : super(key: key);
  final TaskList? taskList;

  @override
  _AddOrEditTaskListPageState createState() => _AddOrEditTaskListPageState();
}

class _AddOrEditTaskListPageState extends State<AddOrEditTaskListPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseManager _databaseManager = DatabaseManager();
  String _id = '';

  Future<void> _onSave() async {
    final id = _id;
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Bạn chưa nhập tiêu đề cho danh sách'),
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

    widget.taskList == null
        ? await _databaseManager.insertTaskList(
            TaskList(id: id, title: title, description: description))
        : await _databaseManager.updateTaskList(
            TaskList(
              id: widget.taskList?.id,
              title: title,
              description: description,
            ),
          );

    final TaskList taskList = TaskList(
      id: id,
      title: title,
      description: description,
    );

    Navigator.pop(context, taskList);
  }

  @override
  void initState() {
    super.initState();
    if (widget.taskList != null) {
      _id = widget.taskList!.id;
      _titleController.text = widget.taskList!.title;
      _descriptionController.text = widget.taskList!.description;
    } else {
      _id = const Uuid().v4();
    }
  }

  @override
  Widget build(BuildContext context) {
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: widget.taskList == null
              ? const Text('Add a new list')
              : const Text('Edit this list'),
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
            padding:
                EdgeInsets.only(left: 12, right: 12, top: 12, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Title',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
