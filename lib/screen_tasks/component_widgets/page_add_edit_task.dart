import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_completion.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_description_editor.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_importance.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_notes_attachment.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_schedule.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_subtasks_block.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_target_block.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_tasklist.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_title.dart';
import 'package:my_time_manager/shared/appflowy_description.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

/// Trang thêm/sửa MỘT task hợp nhất. Người dùng có thể:
///  - bật "Đo lường" để đặt mục tiêu (target/đơn vị),
///  - thêm công việc con (mỗi công việc con có thể tự đo lường và lập kế hoạch).
class AddOrEditTaskPage extends StatefulWidget {
  const AddOrEditTaskPage({super.key, this.task, this.taskList});

  /// Danh sách chứa task. Null = tạo/sửa task "tự do" (không thuộc danh sách
  /// nào) — khi đó trang hiện ô chọn danh sách (có tùy chọn "Không thuộc danh
  /// sách nào").
  final TaskList? taskList;
  final Task? task;

  @override
  State<AddOrEditTaskPage> createState() => _AddOrEditTaskPageState();
}

class _AddOrEditTaskPageState extends State<AddOrEditTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  late final EditorState _descriptionEditorState;
  final TextEditingController _locationController = TextEditingController();

  // Các trường đo lường.
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _targetAtLeastController = TextEditingController();
  final TextEditingController _targetAtMostController = TextEditingController();
  final TextEditingController _hasBeenDoneController =
      TextEditingController(text: '0.0');
  TargetType _targetType = TargetType.about;

  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  late final TaskListRepository _taskListRepository =
      context.read<TaskListRepository>();
  String _id = '';

  Color _taskColor = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;
  bool _isMeasurable = false;
  List<String> _noteIds = [];
  List<Subtask> _subtasks = [];

  /// Danh sách được chọn cho task (null = không thuộc danh sách nào). Khởi tạo
  /// từ widget.taskList hoặc task.taskListId; người dùng có thể đổi qua dropdown.
  String? _selectedTaskListId;

  /// Các danh sách để chọn trong dropdown (nạp bất đồng bộ).
  List<TaskList> _availableLists = [];

  bool get _isEditing => widget.task != null;

  Future<void> _loadLists() async {
    final lists = await _taskListRepository.getTaskLists();
    if (mounted) setState(() => _availableLists = lists);
  }

  @override
  void initState() {
    super.initState();
    _selectedTaskListId = widget.task?.taskListId ?? widget.taskList?.id;
    _loadLists();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionEditorState = AppFlowyDescription.buildEditorState(
        docJson: task.descriptionDoc,
        plainText: task.description,
      );
      _locationController.text = task.location;
      _id = task.id;
      _taskColor = task.color;
      _isCompleted = task.isCompleted;
      _isImportant = task.isImportant;
      _isMeasurable = task.isMeasurable;
      _targetType = task.targetType;
      _unitController.text = task.unit;
      if (task.targetAtLeast.isFinite) {
        _targetAtLeastController.text = task.targetAtLeast.toString();
      }
      if (task.targetAtMost.isFinite) {
        _targetAtMostController.text = task.targetAtMost.toString();
      }
      _hasBeenDoneController.text = task.howMuchHasBeenDone.toString();
      _noteIds = List<String>.from(task.noteIds);
      _subtasks = task.subtasks.map((s) => s.copyWith()).toList();
    } else {
      _id = const Uuid().v4();
      _descriptionEditorState =
          AppFlowyDescription.buildEditorState(docJson: '', plainText: '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _unitController.dispose();
    _targetAtLeastController.dispose();
    _targetAtMostController.dispose();
    _hasBeenDoneController.dispose();
    _descriptionEditorState.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notification),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError(AppLocalizations.of(context)!.enterTaskTitle);
      return;
    }

    double targetAtLeast = double.negativeInfinity;
    double targetAtMost = double.infinity;
    double howMuchHasBeenDone = 0.0;
    if (_isMeasurable) {
      if (_targetType == TargetType.atLeast ||
          _targetType == TargetType.about) {
        final v = double.tryParse(_targetAtLeastController.text);
        if (v == null) {
          _showError('Giá trị "tối thiểu" không hợp lệ');
          return;
        }
        targetAtLeast = v;
      }
      if (_targetType == TargetType.atMost || _targetType == TargetType.about) {
        final v = double.tryParse(_targetAtMostController.text);
        if (v == null) {
          _showError('Giá trị "tối đa" không hợp lệ');
          return;
        }
        targetAtMost = v;
      }
      if (_targetType == TargetType.about && targetAtLeast > targetAtMost) {
        _showError(
            AppLocalizations.of(context)!.minTargetGreaterThanMaxTarget);
        return;
      }
      howMuchHasBeenDone = double.tryParse(_hasBeenDoneController.text) ?? 0.0;
    }

    final task = Task(
      id: _id,
      title: title,
      description: AppFlowyDescription.extractPlainText(_descriptionEditorState),
      descriptionDoc: AppFlowyDescription.encodeDoc(_descriptionEditorState),
      location: _locationController.text,
      isCompleted: _isEditing ? _isCompleted : false,
      isImportant: _isEditing ? _isImportant : false,
      color: _taskColor,
      taskListId: _selectedTaskListId,
      noteIds: _noteIds,
      isMeasurable: _isMeasurable,
      targetType: _targetType,
      targetAtLeast: targetAtLeast,
      targetAtMost: targetAtMost,
      unit: _isMeasurable ? _unitController.text : '',
      howMuchHasBeenDone: howMuchHasBeenDone,
      subtasks: _subtasks,
    );

    _isEditing
        ? await _taskRepository.updateTask(task)
        : await _taskRepository.createTask(task);

    if (!mounted) return;
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final double bottom = MediaQuery.of(context).viewInsets.bottom;

    // Task hiện tại (để dựng ô lập kế hoạch cho task cha khi đang sửa).
    final currentTask = Task(
      id: _id,
      title: _titleController.text,
      description: '',
      location: _locationController.text,
      color: _taskColor,
      taskListId: _selectedTaskListId,
      isMeasurable: _isMeasurable,
      targetType: _targetType,
      subtasks: _subtasks,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _isEditing
            ? const Text('')
            : Text(localizations!.addANewTask),
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
              // Chọn danh sách chứa task (hoặc "Không thuộc danh sách nào").
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Danh sách'),
                trailing: DropdownButton<String?>(
                  value: _availableLists.any((l) => l.id == _selectedTaskListId)
                      ? _selectedTaskListId
                      : null,
                  hint: const Text('Không thuộc danh sách nào'),
                  onChanged: (value) =>
                      setState(() => _selectedTaskListId = value),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Không thuộc danh sách nào'),
                    ),
                    ..._availableLists.map(
                      (l) => DropdownMenuItem<String?>(
                        value: l.id,
                        child: Text(
                          l.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
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
              DescriptionEditorTile(
                editorState: _descriptionEditorState,
              ),

              // Bật/tắt đo lường.
              SwitchListTile(
                secondary: const Icon(Icons.trending_up),
                title: const Text('Đo lường (đặt mục tiêu)'),
                value: _isMeasurable,
                onChanged: (v) => setState(() => _isMeasurable = v),
              ),
              if (_isMeasurable)
                TargetBlockListTile(
                  unitController: _unitController,
                  targetAtLeastController: _targetAtLeastController,
                  targetAtMostController: _targetAtMostController,
                  hasBeenDoneController: _hasBeenDoneController,
                  targetType: _targetType,
                  onTargetTypeChanged: (value) =>
                      setState(() => _targetType = value),
                ),

              // Công việc con.
              const ListTile(
                leading: Padding(
                  padding: EdgeInsets.only(left: 0.0, right: 4.0),
                  child: Icon(Icons.checklist_outlined),
                ),
                title: Text('Công việc con'),
              ),
              SubtasksListTile(
                subtasks: _subtasks,
                parentTask: currentTask,
                allowScheduling: _isEditing,
                onChanged: () => setState(() {}),
              ),

              // Lập kế hoạch cho task cha (chỉ khi đã lưu).
              if (_isEditing) ScheduleListTile(task: currentTask),

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
      ),
    );
  }
}
