import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:my_time_manager/shared/appflowy_description.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description_editor.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_importance.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_notes_attachment.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_schedule.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_tasklist.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_title.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

class AddOrEditTaskWithSubtasksPage extends StatefulWidget {
  const AddOrEditTaskWithSubtasksPage(
      {Key? key, this.taskWithSubtasks, required this.taskList})
      : super(key: key);
  final TaskList taskList;
  final Task? taskWithSubtasks;

  @override
  _AddOrEditTaskWithSubtasksPageState createState() =>
      _AddOrEditTaskWithSubtasksPageState();
}

class _AddOrEditTaskWithSubtasksPageState
    extends State<AddOrEditTaskWithSubtasksPage> {
  final TextEditingController _titleController = TextEditingController();
  late final EditorState _descriptionEditorState;
  final TextEditingController _locationController = TextEditingController();
  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  List<Subtask> _subtasks = [];
  String _id = '';

  Color _taskWithSubtasksColor = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;
  List<String> _noteIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.taskWithSubtasks != null) {
      widget.taskWithSubtasks?.title != null
          ? _titleController.text = widget.taskWithSubtasks!.title
          : _titleController.text = '';
      _descriptionEditorState = AppFlowyDescription.buildEditorState(
        docJson: widget.taskWithSubtasks!.descriptionDoc,
        plainText: widget.taskWithSubtasks!.description,
      );
      widget.taskWithSubtasks?.location != null
          ? _locationController.text = widget.taskWithSubtasks!.location
          : _locationController.text = '';
      widget.taskWithSubtasks?.subtasks != null
          ? _subtasks = widget.taskWithSubtasks!.subtasks
          : _subtasks = [];
      _taskWithSubtasksColor = widget.taskWithSubtasks!.color;
      _id = widget.taskWithSubtasks!.id;
      _isCompleted = widget.taskWithSubtasks!.isCompleted;
      _isImportant = widget.taskWithSubtasks!.isImportant;
      _noteIds = List<String>.from(widget.taskWithSubtasks!.noteIds);
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
    _locationController.dispose();
    _descriptionEditorState.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final id = _id;
    final title = _titleController.text;
    final description =
        AppFlowyDescription.extractPlainText(_descriptionEditorState);
    final descriptionDoc =
        AppFlowyDescription.encodeDoc(_descriptionEditorState);
    final location = _locationController.text;
    final isCompleted = widget.taskWithSubtasks == null ? false : _isCompleted;
    final isImportant = widget.taskWithSubtasks == null ? false : _isImportant;
    final color = _taskWithSubtasksColor;
    final taskListId = widget.taskList.id;
    final subtasks = _subtasks;

    final taskWithSubtasks = Task(
      id: id,
      title: title,
      description: description,
      descriptionDoc: descriptionDoc,
      location: location,
      isCompleted: isCompleted,
      isImportant: isImportant,
      color: color,
      taskListId: taskListId,
      subtasks: subtasks,
      noteIds: _noteIds,
    );

    widget.taskWithSubtasks == null
        ? await _taskRepository.createTask(taskWithSubtasks)
        : await _taskRepository.updateTask(taskWithSubtasks);
    Navigator.pop(context, taskWithSubtasks);
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
          title: widget.taskWithSubtasks == null
              ? Text(localizations!.addANewTask)
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
            padding:
                EdgeInsets.only(left: 08, right: 08, top: 08, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TaskListListTile(
                  title: widget.taskList.title,
                  style: textTheme.titleLarge!,
                ),
                TitleListTile(
                  titleController: _titleController,
                  itemColor: _taskWithSubtasksColor,
                  isCompleted: _isCompleted,
                  handleColorSelect: (index) {
                    setState(() {
                      _taskWithSubtasksColor = ColorSeed.values[index].color;
                    });
                  },
                ),
                const SizedBox(height: 12.0),
                ..._subtasks.reversed.map((subtask) => CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: subtask.isCompleted,
                      onChanged: (value) => setState(
                          () => subtask.isCompleted = value ?? false),
                      title: GestureDetector(
                        onTap: () async {
                          final TextEditingController _controller =
                              TextEditingController();
                          _controller.text = subtask.title;
                          final newTitle = await showDialog<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(localizations!.editSubtask),
                                content: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                      labelText: localizations.title),
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
                            decoration: subtask.isCompleted
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
                Row(children: [
                  TextButton(
                    onPressed: () => _showAddSubtaskDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add),
                        const SizedBox(width: 4),
                        Text(localizations!.addSubtask),
                      ],
                    ),
                  )
                ]),
                const SizedBox(height: 12),
                const Divider(height: 4),
                DescriptionEditorTile(
                  editorState: _descriptionEditorState,
                ),
                if (widget.taskWithSubtasks != null)
                  ScheduleListTile(
                      task: widget.taskWithSubtasks!),
                NotesAttachmentListTile(
                  noteIds: _noteIds,
                  onChanged: (ids) => setState(() => _noteIds = ids),
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
          decoration:
              InputDecoration(labelText: AppLocalizations.of(context)!.title),
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
                  isCompleted: false,
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
