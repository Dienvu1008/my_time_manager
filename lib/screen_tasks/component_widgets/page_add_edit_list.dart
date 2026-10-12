import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:my_time_manager/shared/appflowy_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description_editor.dart';
import 'package:uuid/uuid.dart';

class AddOrEditTaskListPage extends StatefulWidget {
  const AddOrEditTaskListPage({Key? key, this.taskList}) : super(key: key);
  final TaskList? taskList;

  @override
  _AddOrEditTaskListPageState createState() => _AddOrEditTaskListPageState();
}

class _AddOrEditTaskListPageState extends State<AddOrEditTaskListPage> {
  final TextEditingController _titleController = TextEditingController();
  late final EditorState _descriptionEditorState;
  late final TaskListRepository _taskListRepository =
      context.read<TaskListRepository>();
  String _id = '';

  Future<void> _onSave() async {
    final id = _id;
    final title = _titleController.text;
    final description =
        AppFlowyDescription.extractPlainText(_descriptionEditorState);
    final descriptionDoc =
        AppFlowyDescription.encodeDoc(_descriptionEditorState);

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.notification),
          content: Text(AppLocalizations.of(context)!.enterTitleForList),
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

    widget.taskList == null
        ? await _taskListRepository.createTaskList(TaskList(
            id: id,
            title: title,
            description: description,
            descriptionDoc: descriptionDoc))
        : await _taskListRepository.updateTaskList(
            TaskList(
              id: widget.taskList?.id,
              title: title,
              description: description,
              descriptionDoc: descriptionDoc,
            ),
          );

    final TaskList taskList = TaskList(
      id: id,
      title: title,
      description: description,
      descriptionDoc: descriptionDoc,
    );

    Navigator.pop(context, taskList);
  }

  @override
  void initState() {
    super.initState();
    if (widget.taskList != null) {
      _id = widget.taskList!.id;
      _titleController.text = widget.taskList!.title;
      _descriptionEditorState = AppFlowyDescription.buildEditorState(
        docJson: widget.taskList!.descriptionDoc,
        plainText: widget.taskList!.description,
      );
    } else {
      _id = const Uuid().v4();
      _descriptionEditorState = AppFlowyDescription.buildEditorState(
        docJson: '',
        plainText: '',
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionEditorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: widget.taskList == null
              ? Text(localizations!.addNewList)
              : Text(localizations!.editThisList),
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
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: localizations.title,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 16.0),
                DescriptionEditorTile(
                  editorState: _descriptionEditorState,
                ),
              ],
            ),
          ),
        ));
  }
}
