import 'package:flutter/material.dart';
import 'package:my_time_manager/home/timeintervaltest.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database_manager.dart';
import '../data/models/models.dart';
import '../utils/constants.dart';

class TasksOverviewPage extends StatefulWidget {
  const TasksOverviewPage({Key? key}) : super(key: key);

  @override
  _TasksOverviewPageState createState() => _TasksOverviewPageState();
}

class _TasksOverviewPageState extends State<TasksOverviewPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;
  List<TaskList>? _taskLists;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final taskLists = await _databaseManager.taskLists();
    final order = _prefs.getStringList('taskListOrder');
    if (order != null) {
      taskLists
          .sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }
    setState(() => _taskLists = taskLists);
  }

  void _reorderTaskLists(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final taskList = _taskLists!.removeAt(oldIndex);
      _taskLists!.insert(newIndex, taskList);
      final order = _taskLists!.map((b) => b.id.toString()).toList();
      _prefs.setStringList('taskListOrder', order);
    });
  }

  Future<void> _onTaskListDelete(TaskList taskList) async {
    await _databaseManager.deleteTaskList(taskList.id);
    _taskLists!.remove(taskList.id);
    await _saveOrder();
    setState(() {});
  }

  Future<void> _deleteDatabase() async {
    await _databaseManager.deleteDatabase();
    setState(() {});
  }

  Future<void> _addTaskList(TaskList taskList) async {
    setState(() => _taskLists!.insert(0, taskList));
    await _saveOrder();
  }

  Future<void> _saveOrder() async {
    final order = _taskLists!.map((taskList) => taskList.id).toList();
    await _prefs.setStringList('taskListOrder', order);
  }

  @override
  Widget build(BuildContext context) {
    if (_taskLists == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return Expanded(
        child: Scaffold(
      body: TaskListsHolder(
        onReorder: _reorderTaskLists,
        taskLists: _taskLists ?? [],
        onTaskListDelete: (value) async {
          _onTaskListDelete(value);
        },
        onTaskListEdit: (TaskList taskList) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOrEditTaskListPage(taskList: taskList),
              fullscreenDialog: false,
            ),
          );
          final updatedTaskLists = await _databaseManager.taskLists();
          final order = _prefs.getStringList('taskListOrder');
          if (order != null) {
            updatedTaskLists.sort(
                (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
          }
          setState(() => _taskLists = updatedTaskLists);
        },
      ),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: () async {
            final taskList = await showDialog<TaskList>(
              context: context,
              builder: (context) => AddOrEditTaskListPage(),
            );
            if (taskList != null) {
              await _addTaskList(taskList);
            }
          },
          heroTag: 'addTaskList',
          child: const Icon(Icons.add),
        ),
        const SizedBox(
          width: 10.0,
          height: 20.0,
        ),
        FloatingActionButton(
          onPressed: _deleteDatabase,
          child: const Icon(Icons.delete),
        ),
      ]),
    ));
  }
}

class TaskListsHolder extends StatefulWidget {
  const TaskListsHolder({
    Key? key,
    required this.onTaskListDelete,
    required this.onTaskListEdit,
    required this.onReorder,
    required this.taskLists,
  }) : super(key: key);

  final Function(TaskList) onTaskListDelete;
  final Function(TaskList) onTaskListEdit;
  final Function(int, int) onReorder;
  final List<TaskList> taskLists;

  @override
  _TaskListsHolderState createState() => _TaskListsHolderState();
}

class _TaskListsHolderState extends State<TaskListsHolder> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: widget.onReorder,
      children: List.generate(widget.taskLists.length, (index) {
        final taskList = widget.taskLists[index];
        return TaskListCard(
          key: ValueKey(taskList),
          taskList: taskList,
          onTaskListDelete: (TaskList taskList) async {
            widget.onTaskListDelete(taskList);
            setState(() => widget.taskLists.remove(taskList));
          },
          onTaskListEdit: widget.onTaskListEdit,
        );
      }),
    );
  }
}

class TaskListCard extends StatefulWidget {
  const TaskListCard({
    Key? key,
    required this.taskList,
    required this.onTaskListEdit,
    required this.onTaskListDelete,
  }) : super(key: key);

  final TaskList taskList;
  final Function(TaskList) onTaskListEdit;
  final Function(TaskList) onTaskListDelete;

  @override
  _TaskListCardState createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;
  bool _isExpanded = false;
  List<Task>? _tasks;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final tasks = await _databaseManager.tasksOfTaskList(widget.taskList.id);
    final order = _prefs.getStringList('taskOrder');
    if (order != null) {
      tasks.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }
    setState(() => {
          _tasks = tasks,
          _isExpanded =
              _prefs.getBool('${widget.taskList.id}_isExpanded') ?? false
        });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() => {
    //         _tasks = tasks,
    //         _isExpanded =
    //             _prefs.getBool('${widget.taskList.id}_isExpanded') ?? false
    //       });
    // });
  }

  // Future<List<Task>> _loadtasksOfTaskList(String taskListId) async {
  //   return await _databaseManager.tasksOfTaskList(taskListId);
  // }

  // Future<void> _onTaskEdit(Task task) async {
  //   await _databaseManager.updateTask(task);
  //   setState(() {});
  // }

  Future<void> _onTaskToggleCompleted(Task task) async {
    Task _task = Task(
        color: task.color,
        description: task.description,
        taskListId: task.taskListId,
        title: task.title,
        isCompleted: !task.isCompleted,
        id: task.id);
    await _databaseManager.updateTask(_task);
    // final updatedTasks =
    //     await _databaseManager.tasksOfTaskList(widget.taskList.id);
    // setState(() => _tasks = updatedTasks);
    _init();

    //_init();
    //setState(() {});
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final task = _tasks!.removeAt(oldIndex);
      _tasks!.insert(newIndex, task);
      final order = _tasks!.map((b) => b.id.toString()).toList();
      _prefs.setStringList('taskOrder', order);
    });
  }

  Future<void> _onTaskDelete(Task task) async {
    await _databaseManager.deleteTask(task.id);
    _tasks!.remove(task.id);
    await _saveOrder();
    setState(() {});
  }

  Future<void> _addTask(Task task) async {
    setState(() => _tasks!.insert(0, task));
    await _saveOrder();
    _init();
  }

  Future<void> _saveOrder() async {
    final order = _tasks!.map((task) => task.id).toList();
    await _prefs.setStringList('taskOrder', order);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(
            children: [
              IconButton(
                icon:
                    Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right),
                onPressed: () =>
                    //     WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   setState(() {
                    //     _isExpanded = !_isExpanded;
                    //     _prefs.setBool(
                    //         '${widget.taskList.id}_isExpanded', _isExpanded);
                    //   });
                    // }),
                    setState(() {
                  _isExpanded = !_isExpanded;
                  _prefs.setBool(
                      '${widget.taskList.id}_isExpanded', _isExpanded);
                }),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTaskListEdit(widget.taskList),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.taskList.title, style: textTheme.titleMedium),
                      const SizedBox(height: 4.0),
                      if (_isExpanded && widget.taskList.description.isNotEmpty)
                        Text(widget.taskList.description),
                    ],
                  ),
                ),
              ),
              TaskListCardOptions(
                taskList: widget.taskList,
                onTaskListDelete: () =>
                    widget.onTaskListDelete(widget.taskList),
                onTaskListEdit: () => widget.onTaskListEdit(widget.taskList),
                addTask: (value) => _addTask(value),
              ),
            ],
          ),
          if (_isExpanded)
            TasksHolder(
              onTaskDelete: _onTaskDelete,
              onReorder: _reorderTasks,
              tasks: _tasks ?? [],
              onTaskEdit: (Task task) async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddOrEditTaskPage(
                      task: task,
                      taskList: widget.taskList,
                    ),
                    fullscreenDialog: false,
                  ),
                );
                final updatedTasks =
                    await _databaseManager.tasksOfTaskList(widget.taskList.id);
                final order = _prefs.getStringList('taskOrder');
                if (order != null) {
                  updatedTasks.sort((a, b) =>
                      order.indexOf(a.id).compareTo(order.indexOf(b.id)));
                }
                setState(() => _tasks = updatedTasks);
              },
              onTaskToggleComplete: _onTaskToggleCompleted,
            ),
        ]),
      ),
    );
  }
}

class TaskListCardOptions extends StatelessWidget {
  const TaskListCardOptions(
      {super.key,
      required this.onTaskListEdit,
      required this.onTaskListDelete,
      required this.taskList,
      required this.addTask});

  final Function() onTaskListEdit;
  final Function() onTaskListDelete;
  final Function(Task) addTask;
  final TaskList taskList;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: () async {
                final task = await showDialog<Task>(
                  context: context,
                  builder: (context) => AddOrEditTaskPage(
                    taskList: taskList,
                  ),
                );
                if (task != null) {
                  await addTask(task);
                }
              },
              child: const Text('Add nomal task'),
            ),
            MenuItemButton(
              onPressed: () {},
              child: const Text('Add measureable task'),
            ),
            MenuItemButton(
              onPressed: () {},
              child: const Text('Add task with sub-task'),
            ),
          ],
          child: const Row(
            children: [
              Icon(Icons.add),
              SizedBox(
                width: 5,
              ),
              Text('Add new task to this to do list')
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListEdit,
          child: const Row(
            children: [
              Icon(Icons.edit),
              SizedBox(
                width: 5,
              ),
              Text('Edit this to do list')
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListDelete,
          child: const Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(
                width: 5,
              ),
              Text('Delete this to do list')
            ],
          ),
        ),
      ],
    );
  }
}

class TasksHolder extends StatefulWidget {
  const TasksHolder({
    Key? key,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.tasks,
    required this.onReorder,
    required this.onTaskToggleComplete,
  }) : super(key: key);

  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  final List<Task> tasks;
  final Function(int, int) onReorder;

  @override
  _TasksHolderState createState() => _TasksHolderState();
}

class _TasksHolderState extends State<TasksHolder> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: widget.onReorder,
      children: List.generate(widget.tasks.length, (index) {
        final task = widget.tasks[index];
        return TaskCard(
          key: ValueKey(task),
          task: task,
          onTaskDelete: (Task task) async {
            widget.onTaskDelete(task);
            setState(() => widget.tasks.remove(task));
          },
          //onTaskEdit: widget.onTaskEdit,
          onTaskEdit: (Task task) async {
            widget.onTaskEdit(task);
            setState(() {});
          },
          onTaskToggleComplete: (Task task) async {
            widget.onTaskToggleComplete(task);
            setState(() {});
          },
        );
      }),
    );
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskToggleComplete,
  }) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
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
    final taskColor = widget.task.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskColor)
        : ColorScheme.light(primary: taskColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTaskEdit(widget.task),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (widget.task.description.isNotEmpty)
                      Text(widget.task.description,
                          style: TextStyle(color: labelColor)),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: labelColor),
              onSelected: (String result) {
                if (result == 'option1') {
                  widget.onTaskEdit(widget.task);
                } else if (result == 'option2') {
                  widget.onTaskDelete(widget.task);
                } else if (result == 'option3') {
                  widget.onTaskToggleComplete(widget.task);
                } else if (result == 'option4') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimeIntervalPage(task: widget.task)),
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'option3',
                  child: Row(
                    children: [
                      Icon(widget.task.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                      const SizedBox(width: 8),
                      widget.task.isCompleted
                          ? const Text('Mark as incompleted')
                          : const Text('Mark as completed'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'option4',
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty),
                      const SizedBox(width: 8),
                      Text('Add time interval'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'option1',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      const SizedBox(width: 8),
                      Text('Edit Task'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'option2',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      const SizedBox(width: 8),
                      Text('Delete Task'),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

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

  Future<void> _onSave() async {
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Tiêu đề của tasklist không được phép rỗng.'),
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
        ? await _databaseManager
            .insertTaskList(TaskList(title: title, description: description))
        : await _databaseManager.updateTaskList(
            TaskList(
              id: widget.taskList?.id,
              title: title,
              description: description,
            ),
          );

    final TaskList taskList = TaskList(
      title: title,
      description: description,
    );

    Navigator.pop(context, taskList);
  }

  @override
  void initState() {
    super.initState();
    if (widget.taskList != null) {
      _titleController.text = widget.taskList!.title;
      _descriptionController.text = widget.taskList!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.taskList == null
            ? const Text('Add a new tasklist')
            : const Text('Edit tasklist'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter title of the tasklist here',
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
                hintText: 'Enter description about the tasklist here',
                labelText: 'Description',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 45.0,
              child: ElevatedButton(
                onPressed: _onSave,
                child: const Text(
                  'Save the tasklist',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddOrEditTaskPage extends StatefulWidget {
  const AddOrEditTaskPage({Key? key, this.task, required this.taskList})
      : super(key: key);
  final TaskList taskList;
  final Task? task;

  @override
  _AddOrEditTaskPageState createState() => _AddOrEditTaskPageState();
}

class _AddOrEditTaskPageState extends State<AddOrEditTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseManager _databaseManager = DatabaseManager();

  Color _taskColor = ColorSeed.baseColor.color;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      widget.task?.title != null
          ? _titleController.text = widget.task!.title
          : _titleController.text = '';
      widget.task?.description != null
          ? _descriptionController.text = widget.task!.description
          : _descriptionController.text = '';
      _taskColor = widget.task!.color;
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    final isCompleted = widget.task == null ? false : widget.task!.isCompleted;
    final color = _taskColor;
    final taskListId = widget.taskList.id;

    // Add save code here
    widget.task == null
        ? await _databaseManager.insertTask(
            Task(
                title: title,
                description: description,
                isCompleted: isCompleted,
                color: color,
                taskListId: taskListId),
          )
        : await _databaseManager.updateTask(
            Task(
              id: widget.task!.id,
              title: title,
              description: description,
              isCompleted: isCompleted,
              color: color,
              taskListId: taskListId,
            ),
          );

    final Task task = widget.task == null
        ? Task(
            title: title,
            isCompleted: isCompleted,
            description: description,
            color: color,
            taskListId: taskListId,
          )
        : Task(
            id: widget.task!.id,
            title: title,
            description: description,
            isCompleted: isCompleted,
            color: color,
            taskListId: taskListId,
          );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.task == null ? Text('Add new task') : Text('Edit task'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter title of the task here',
                      labelText: 'Title',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 40,
                  //height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: ColorSeedButton(
                      colorSelected: ColorSeed.values.firstWhere(
                        (e) => e.color == _taskColor,
                        orElse: () => ColorSeed.baseColor,
                      ),
                      handleColorSelect: (index) {
                        setState(() {
                          _taskColor = ColorSeed.values[index].color;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              maxLines: null,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description of the task here',
                  labelText: 'Description',
                  floatingLabelBehavior: FloatingLabelBehavior.auto),
            ),
            const SizedBox(height: 24.0),
            Text(widget.taskList.title),
            const SizedBox(height: 24.0),
            SizedBox(
              height: 45.0,
              child: ElevatedButton(
                onPressed: _onSave,
                child: const Text(
                  'Save the task data',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSeedButton extends StatelessWidget {
  const ColorSeedButton({
    required this.handleColorSelect,
    required this.colorSelected,
  });

  final void Function(int) handleColorSelect;
  final ColorSeed colorSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.palette_outlined,
        color: colorSelected.color,
      ),
      tooltip: 'Select a seed color',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(ColorSeed.values.length, (index) {
          ColorSeed currentColor = ColorSeed.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentColor != colorSelected,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    currentColor == colorSelected
                        ? Icons.color_lens
                        : Icons.color_lens_outlined,
                    color: currentColor.color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(currentColor.label),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleColorSelect,
    );
  }
}

// class TaskListSelector extends StatelessWidget {
//   const TaskListSelector({
//     Key? key,
//     required this.taskListsTitle,
//     required this.selectedIndex,
//     required this.onChanged,
//   }) : super(key: key);
//   final List<String> taskListsTitle;
//   final int selectedIndex;
//   final Function(int) onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select tasklist',
//           style: TextStyle(
//             fontSize: 16.0,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: 12.0),
//         Container(
//           height: 40.0,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: taskListsTitle.length,
//             itemBuilder: (context, index) {
//               return GestureDetector(
//                 onTap: () => onChanged(index),
//                 child: Container(
//                   height: 40.0,
//                   padding: EdgeInsets.symmetric(horizontal: 12.0),
//                   margin: const EdgeInsets.only(right: 12.0),
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8.0),
//                     border: Border.all(
//                       width: 3.0,
//                       color:
//                           selectedIndex == index ? Colors.teal : Colors.black,
//                     ),
//                   ),
//                   child: Text(taskListsTitle[index]),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
