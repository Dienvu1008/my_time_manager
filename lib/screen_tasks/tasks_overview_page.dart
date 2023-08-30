import 'package:flutter/material.dart';
import 'package:my_time_manager/home/test.dart';
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
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final tasks = await _databaseManager.tasksOfTaskList(widget.taskList.id);
    final measurableTasks =
        await _databaseManager.measurableTasksOfTaskList(widget.taskList.id);
    final tasksWithSubtasks =
        await _databaseManager.tasksWithSubtasksOfTaskList(widget.taskList.id);
    final events = await _databaseManager.eventsOfTaskList(widget.taskList.id);
    final List<dynamic> items = [
      ...tasks,
      ...measurableTasks,
      ...tasksWithSubtasks,
      ...events,
    ];

    final order = _prefs.getStringList('itemsOrder');
    if (order != null) {
      items.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }

    if (mounted) {
      setState(() => {
            _items = items,
            _isExpanded =
                _prefs.getBool('${widget.taskList.id}_isExpanded') ?? false,
          });
    }
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      final order = _items.map((b) => b.id.toString()).toList();
      _prefs.setStringList('itemsOrder', order);
    });
  }

  Future<void> _onTaskToggleCompleted(Task task) async {
    Task _task = Task(
        color: task.color,
        description: task.description,
        taskListId: task.taskListId,
        title: task.title,
        isCompleted: !task.isCompleted,
        id: task.id);
    await _databaseManager.updateTask(_task);
    final updatedTask = await _databaseManager.task(task.id);
    final index = _items.indexWhere((item) => item.id == updatedTask.id);
    if (index != -1) {
      setState(() {
        _items[index] = updatedTask;
      });
    }
  }

  Future<void> _onMeasurableTaskToggleCompleted(
      MeasurableTask measurableTask) async {
    MeasurableTask _measurableTask = MeasurableTask(
        color: measurableTask.color,
        description: measurableTask.description,
        taskListId: measurableTask.taskListId,
        title: measurableTask.title,
        isCompleted: !measurableTask.isCompleted,
        id: measurableTask.id,
        targetAtLeast: measurableTask.targetAtLeast,
        targetAtMost: measurableTask.targetAtMost,
        targetType: measurableTask.targetType,
        unit: measurableTask.unit);
    await _databaseManager.updateMeasurableTask(_measurableTask);
    final updatedMeasurableTask =
        await _databaseManager.measurableTask(measurableTask.id);
    final index =
        _items.indexWhere((item) => item.id == updatedMeasurableTask.id);
    if (index != -1) {
      setState(() {
        _items[index] = updatedMeasurableTask;
      });
    }
  }

  Future<void> _onTaskWithSubtasksToggleCompleted(
      TaskWithSubtasks taskWithSubtasks) async {
    TaskWithSubtasks _taskWithSubtasks = TaskWithSubtasks(
      color: taskWithSubtasks.color,
      description: taskWithSubtasks.description,
      taskListId: taskWithSubtasks.taskListId,
      title: taskWithSubtasks.title,
      isCompleted: !taskWithSubtasks.isCompleted,
      id: taskWithSubtasks.id,
      subtasks: taskWithSubtasks.subtasks,
    );
    await _databaseManager.updateTaskWithSubtasks(_taskWithSubtasks);
    final updatedTaskWithSubtasks =
        await _databaseManager.taskWithSubtasks(taskWithSubtasks.id);
    final index =
        _items.indexWhere((item) => item.id == updatedTaskWithSubtasks.id);
    if (index != -1) {
      setState(() {
        _items[index] = updatedTaskWithSubtasks;
      });
    }
  }

  Future<void> _onSubtasksChanged(TaskWithSubtasks taskWithSubtasks) async {
    TaskWithSubtasks _taskWithSubtasks = TaskWithSubtasks(
      color: taskWithSubtasks.color,
      description: taskWithSubtasks.description,
      taskListId: taskWithSubtasks.taskListId,
      title: taskWithSubtasks.title,
      //isCompleted: taskWithSubtasks.isCompleted,
      id: taskWithSubtasks.id,
      subtasks: taskWithSubtasks.subtasks,
    );
    await _databaseManager.updateTaskWithSubtasks(_taskWithSubtasks);
    final updatedTaskWithSubtasks =
        await _databaseManager.taskWithSubtasks(taskWithSubtasks.id);
    final index =
        _items.indexWhere((item) => item.id == updatedTaskWithSubtasks.id);
    if (index != -1) {
      setState(() {
        _items[index] = updatedTaskWithSubtasks;
      });
    }
    //_init();
  }

  Future<void> _onTaskDelete(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _databaseManager.deleteTask(task.id);
      setState(() {
        _items.remove(task);
      });
      await _saveOrder();
    }
  }

  Future<void> _onMeasurableTaskDelete(MeasurableTask measurableTask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _databaseManager.deleteMeasurableTask(measurableTask.id);
      setState(() {
        _items.remove(measurableTask);
      });
      await _saveOrder();
    }
  }

  Future<void> _onTaskWithSubtasksDelete(
      TaskWithSubtasks taskWithSubtasks) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await _databaseManager.deleteTaskWithSubtasks(taskWithSubtasks.id);
      setState(() {
        _items.remove(taskWithSubtasks);
      });
      await _saveOrder();
    }
  }

  Future<void> _addTask(Task task) async {
    setState(() => _items.insert(0, task));
    await _saveOrder();
    _init();
  }

  Future<void> _addMeasurableTask(MeasurableTask measurableTask) async {
    setState(() => _items.insert(0, measurableTask));
    await _saveOrder();
    _init();
  }

  Future<void> _addTaskWithSubtasks(TaskWithSubtasks taskWithSubtasks) async {
    setState(() => _items.insert(0, taskWithSubtasks));
    await _saveOrder();
    _init();
  }

  Future<void> _saveOrder() async {
    final order = _items.map((item) => item.id as String).toList();
    await _prefs.setStringList('itemsOrder', order);
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
                onPressed: () => setState(() {
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
                addMeasurableTask: (value) => _addMeasurableTask(value),
                addTaskWithSubtasks: (value) => _addTaskWithSubtasks(value),
              ),
            ],
          ),
          if (_isExpanded)
            ItemsHolder(
              onReorder: _reorderItems,
              items: _items,
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
                final updatedTask = await _databaseManager.task(task.id);
                final index =
                    _items.indexWhere((item) => item.id == updatedTask.id);
                if (index != -1) {
                  setState(() {
                    _items[index] = updatedTask;
                  });
                }
              },
              onTaskToggleComplete: _onTaskToggleCompleted,
              onTaskDelete: _onTaskDelete,
              onMeasurableTaskEdit: (MeasurableTask measurableTask) async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddOrEditMeasurableTaskPage(
                      measurableTask: measurableTask,
                      taskList: widget.taskList,
                    ),
                    fullscreenDialog: false,
                  ),
                );
                final updatedMeasurableTask =
                    await _databaseManager.measurableTask(measurableTask.id);
                final index = _items
                    .indexWhere((item) => item.id == updatedMeasurableTask.id);
                if (index != -1) {
                  setState(() {
                    _items[index] = updatedMeasurableTask;
                  });
                }
              },
              onMeasurableTaskToggleComplete: _onMeasurableTaskToggleCompleted,
              onMeasurableTaskDelete: _onMeasurableTaskDelete,
              onTaskWithSubtasksEdit:
                  (TaskWithSubtasks taskWithSubtasks) async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddOrEditTaskWithSubtasksPage(
                      taskWithSubtasks: taskWithSubtasks,
                      taskList: widget.taskList,
                    ),
                    fullscreenDialog: false,
                  ),
                );
                final updatedTaskWithSubtasks = await _databaseManager
                    .taskWithSubtasks(taskWithSubtasks.id);
                final index = _items.indexWhere(
                    (item) => item.id == updatedTaskWithSubtasks.id);
                if (index != -1) {
                  setState(() {
                    _items[index] = updatedTaskWithSubtasks;
                  });
                }
              },
              onTaskWithSubtasksToggleComplete:
                  _onTaskWithSubtasksToggleCompleted,
              onTaskWithSubtasksDelete: _onTaskWithSubtasksDelete,
              onSubtasksChanged: _onSubtasksChanged,
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
      required this.addTask,
      required this.addMeasurableTask,
      required this.addTaskWithSubtasks});

  final Function() onTaskListEdit;
  final Function() onTaskListDelete;
  final Function(Task) addTask;
  final Function(MeasurableTask) addMeasurableTask;
  final Function(TaskWithSubtasks) addTaskWithSubtasks;
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
          icon: const Icon(Icons.more_vert_outlined),
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
              onPressed: () async {
                final measurableTask = await showDialog<MeasurableTask>(
                  context: context,
                  builder: (context) => AddOrEditMeasurableTaskPage(
                    taskList: taskList,
                  ),
                );
                if (measurableTask != null) {
                  await addMeasurableTask(measurableTask);
                }
              },
              child: const Text('Add measureable task'),
            ),
            MenuItemButton(
              onPressed: () async {
                final taskWithSubtasks = await showDialog<TaskWithSubtasks>(
                  context: context,
                  builder: (context) => AddOrEditTaskWithSubtasksPage(
                    taskList: taskList,
                  ),
                );
                if (taskWithSubtasks != null) {
                  await addTaskWithSubtasks(taskWithSubtasks);
                }
              },
              child: const Text('Add task with sub-tasks'),
            ),
            MenuItemButton(
              onPressed: () async {
                final taskWithSubtasks = await showDialog<TaskWithSubtasks>(
                  context: context,
                  builder: (context) => AddOrEditTaskWithSubtasksPage(
                    taskList: taskList,
                  ),
                );
                //if (taskWithSubtasks != null) {
                //await addTask(taskWithSubtasks);
                //}
              },
              child: const Text('Add event'),
            ),
          ],
          child: const Row(
            children: [
              Icon(Icons.add_outlined),
              SizedBox(
                width: 5,
              ),
              Text('Add to this list')
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListEdit,
          child: const Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(
                width: 5,
              ),
              Text('Edit this list')
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
              Text('Delete this list')
            ],
          ),
        ),
      ],
    );
  }
}

class ItemsHolder extends StatefulWidget {
  const ItemsHolder({
    Key? key,
    required this.items,
    required this.onReorder,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskToggleComplete,
    required this.onMeasurableTaskEdit,
    required this.onMeasurableTaskDelete,
    required this.onMeasurableTaskToggleComplete,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
  }) : super(key: key);

  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  final Function(MeasurableTask) onMeasurableTaskEdit;
  final Function(MeasurableTask) onMeasurableTaskDelete;
  final Function(MeasurableTask) onMeasurableTaskToggleComplete;

  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  final List<dynamic> items;
  final Function(int, int) onReorder;

  @override
  _ItemsHolderState createState() => _ItemsHolderState();
}

class _ItemsHolderState extends State<ItemsHolder> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: widget.onReorder,
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        if (item is Task) {
          return TaskCard(
            key: ValueKey(item),
            task: item,
            onTaskDelete: (Task task) async {
              widget.onTaskDelete(task);
              widget.items.remove(task);
            },
            onTaskEdit: (Task task) async {
              widget.onTaskEdit(task);
            },
            onTaskToggleComplete: (Task task) async {
              widget.onTaskToggleComplete(task);
            },
          );
        } else if (item is MeasurableTask) {
          return MeasurableTaskCard(
            key: ValueKey(item),
            measurableTask: item,
            onMeasurableTaskDelete: (MeasurableTask measurableTask) async {
              widget.onMeasurableTaskDelete(measurableTask);
              widget.items.remove(measurableTask);
            },
            onMeasurableTaskEdit: (MeasurableTask measurableTask) async {
              widget.onMeasurableTaskEdit(measurableTask);
            },
            onMeasurableTaskToggleComplete:
                (MeasurableTask measurableTask) async {
              widget.onMeasurableTaskToggleComplete(measurableTask);
            },
          );
        } else if (item is TaskWithSubtasks) {
          return TaskWithSubtasksCard(
            key: ValueKey(item),
            taskWithSubtasks: item,
            onTaskWithSubtasksDelete:
                (TaskWithSubtasks taskWithSubtasks) async {
              widget.onTaskWithSubtasksDelete(taskWithSubtasks);
              widget.items.remove(taskWithSubtasks);
            },
            onTaskWithSubtasksEdit: (TaskWithSubtasks taskWithSubtasks) async {
              widget.onTaskWithSubtasksEdit(taskWithSubtasks);
            },
            onTaskWithSubtasksToggleComplete:
                (TaskWithSubtasks taskWithSubtasks) async {
              widget.onTaskWithSubtasksToggleComplete(taskWithSubtasks);
            },
            onSubtasksChanged: (TaskWithSubtasks taskWithSubtasks) {
              widget.onSubtasksChanged(taskWithSubtasks);
            },
          );
        } else if (item is Event) {
        } else {
          return const SizedBox();
        }
        throw '';
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
        child: Row(
          children: [
            // Expanded(
            //     flex: 1,
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: backgroundColor,
            //       ),
            //     )),
            Expanded(
              //flex: 19,
              child: GestureDetector(
                onTap: () => widget.onTaskEdit(widget.task),
                child: ListTile(
                    title: Text(
                      widget.task.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: widget.task.description.isNotEmpty
                        ? Text(
                            widget.task.description,
                            style: TextStyle(color: labelColor),
                          )
                        : null,
                    trailing: PopupMenuButton<String>(
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
                            MaterialPageRoute(
                                builder: (context) =>
                                    TimeIntervalPage(task: widget.task)),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                              SizedBox(width: 8),
                              Text('Add time interval'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option5',
                          child: Row(
                            children: [
                              Icon(Icons.timelapse_outlined),
                              SizedBox(width: 8),
                              Text('Focus right now?'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit Task'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option2',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined),
                              SizedBox(width: 8),
                              Text('Delete Task'),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          ],
        ));
  }
}

class MeasurableTaskCard extends StatefulWidget {
  final MeasurableTask measurableTask;
  final Function(MeasurableTask) onMeasurableTaskEdit;
  final Function(MeasurableTask) onMeasurableTaskDelete;
  final Function(MeasurableTask) onMeasurableTaskToggleComplete;

  const MeasurableTaskCard({
    Key? key,
    required this.measurableTask,
    required this.onMeasurableTaskEdit,
    required this.onMeasurableTaskDelete,
    required this.onMeasurableTaskToggleComplete,
  }) : super(key: key);

  @override
  _MeasurableTaskCardState createState() => _MeasurableTaskCardState();
}

class _MeasurableTaskCardState extends State<MeasurableTaskCard> {
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
    final measurableTaskColor = widget.measurableTask.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: measurableTaskColor)
        : ColorScheme.light(primary: measurableTaskColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    // final _hasBeenDoneController = TextEditingController(
    //   text: widget.measurableTask.howMuchHasBeenDone.toString(),
    // );

    return Card(
      color: backgroundColor,
      child: Row(
        children: [
          // Expanded(
          //     flex: 1,
          //     child: Container(
          //       decoration: BoxDecoration(
          //         color: backgroundColor,
          //       ),
          //     )),
          Expanded(
            //flex: 19,
            child: GestureDetector(
              onTap: () => widget.onMeasurableTaskEdit(widget.measurableTask),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    //isThreeLine: true,
                    title: Text(
                      widget.measurableTask.title,
                      style: TextStyle(
                        color: labelColor,
                        decoration: widget.measurableTask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.measurableTask.description.isNotEmpty)
                          Text(
                            widget.measurableTask.description,
                            style: TextStyle(color: labelColor),
                          ),
                        if (widget.measurableTask.targetType ==
                            TargetType.about)
                          Text(
                              'Target: about ${widget.measurableTask.targetAtLeast} to ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                              style: TextStyle(color: labelColor)),
                        if (widget.measurableTask.targetType ==
                            TargetType.atLeast)
                          Text(
                            'Target: at least ${widget.measurableTask.targetAtLeast} ${widget.measurableTask.unit}',
                            style: TextStyle(color: labelColor),
                          ),
                        if (widget.measurableTask.targetType ==
                            TargetType.atMost)
                          Text(
                            'Target: at most ${widget.measurableTask.targetAtMost} ${widget.measurableTask.unit}',
                            style: TextStyle(color: labelColor),
                          ),
                        if (widget.measurableTask.howMuchHasBeenDone != 0)
                          Text(
                            'Has been done: ${widget.measurableTask.howMuchHasBeenDone} ${widget.measurableTask.unit}',
                            style: TextStyle(color: labelColor),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: labelColor),
                      onSelected: (String result) {
                        if (result == 'option1') {
                          widget.onMeasurableTaskEdit(widget.measurableTask);
                        } else if (result == 'option2') {
                          widget.onMeasurableTaskDelete(widget.measurableTask);
                        } else if (result == 'option3') {
                          widget.onMeasurableTaskToggleComplete(
                              widget.measurableTask);
                        } else if (result == 'option4') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TimeIntervalPage(
                                    measurableTask: widget.measurableTask)),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'option3',
                          child: Row(
                            children: [
                              Icon(widget.measurableTask.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank),
                              const SizedBox(width: 8),
                              widget.measurableTask.isCompleted
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
                              SizedBox(width: 8),
                              Text('Add time interval'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option5',
                          child: Row(
                            children: [
                              Icon(Icons.timelapse_outlined),
                              SizedBox(width: 8),
                              Text('Focus right now?'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option1',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit Task'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'option2',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined),
                              SizedBox(width: 8),
                              Text('Delete Task'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskWithSubtasksCard extends StatefulWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  const TaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
  }) : super(key: key);

  @override
  _TaskWithSubtasksCardState createState() => _TaskWithSubtasksCardState();
}

class _TaskWithSubtasksCardState extends State<TaskWithSubtasksCard> {
  static Color contrastColor(Color color) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    switch (brightness) {
      case Brightness.dark:
        return Colors.white;
      case Brightness.light:
        return Colors.black;
    }
  }

  bool _isExpanded = true;
  //bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIsExpanded();
  }



  // void _loadIsExpanded() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   if (mounted) {
  //     setState(() {
  //       _isExpanded =
  //           prefs.getBool('isExpanded_${widget.taskWithSubtasks.id}') ?? true;
  //     });
  //   }
  // }
  void _loadIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isExpanded =
        prefs.getBool('isExpanded_${widget.taskWithSubtasks.id}') ?? true;
    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
        //_isLoading = false;
      });
    }
  }

  void _saveIsExpanded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isExpanded_${widget.taskWithSubtasks.id}', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final taskWithSubtasksColor = widget.taskWithSubtasks.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskWithSubtasksColor)
        : ColorScheme.light(primary: taskWithSubtasksColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);
    //if (_isLoading) {
      // Hiển thị widget loading
      // ...
      //return const CircularProgressIndicator();
    //} else {
      return Card(
        color: backgroundColor,
        child: Row(
          children: [
            // Expanded(
            //     flex: 1,
            //     child: Container(
            //       decoration: BoxDecoration(
            //         color: backgroundColor,
            //       ),
            //     )),
            Expanded(
              //flex: 19,
              child: GestureDetector(
                onTap: () =>
                    widget.onTaskWithSubtasksEdit(widget.taskWithSubtasks),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        widget.taskWithSubtasks.title,
                        style: TextStyle(
                          color: labelColor,
                          decoration: widget.taskWithSubtasks.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: widget.taskWithSubtasks.description.isNotEmpty
                          ? Text(
                              widget.taskWithSubtasks.description,
                              style: TextStyle(color: labelColor),
                            )
                          : null,
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_outlined, color: labelColor),
                        onSelected: (String result) {
                          if (result == 'option1') {
                            widget.onTaskWithSubtasksEdit(
                                widget.taskWithSubtasks);
                          } else if (result == 'option2') {
                            widget.onTaskWithSubtasksDelete(
                                widget.taskWithSubtasks);
                          } else if (result == 'option3') {
                            widget.onTaskWithSubtasksToggleComplete(
                                widget.taskWithSubtasks);
                          } else if (result == 'option4') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TimeIntervalPage(
                                      taskWithSubtasks:
                                          widget.taskWithSubtasks)),
                            );
                          } else if (result == 'option5') {
                            setState(() => _isExpanded = !_isExpanded);
                            _saveIsExpanded();
                            //widget.onSubtasksDisplayChanged;
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'option5',
                            child: Row(
                              children: [
                                Icon(_isExpanded
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded
                                    ? const Text('Hide sub-tasks')
                                    : const Text('Show sub-tasks'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'option3',
                            child: Row(
                              children: [
                                Icon(widget.taskWithSubtasks.isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank),
                                const SizedBox(width: 8),
                                widget.taskWithSubtasks.isCompleted
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
                                SizedBox(width: 8),
                                Text('Add time interval'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'option6',
                            child: Row(
                              children: [
                                Icon(Icons.timelapse_outlined),
                                SizedBox(width: 8),
                                Text('Focus right now?'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'option1',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Text('Edit Task'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'option2',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outlined),
                                SizedBox(width: 8),
                                Text('Delete Task'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isExpanded)
                      ...widget.taskWithSubtasks.subtasks.map(
                        (subtask) => CheckboxListTile(
                          side: BorderSide(
                            color: labelColor,
                          ),
                          activeColor: labelColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: subtask.isSubtaskCompleted,
                          onChanged: (value) {
                            //_isLoading = false;
                            subtask.isSubtaskCompleted = value ?? false;
                            widget.onSubtasksChanged(widget.taskWithSubtasks);
                          },
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isSubtaskCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: labelColor,
                            ),
                          ),
                          secondary: IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: labelColor,
                            ),
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Delete Subtask'),
                                    content: Text(
                                        'Are you sure you want to delete this subtask?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result == true) {
                                //setState(() {
                                  //_isLoading = false;
                                widget.taskWithSubtasks.subtasks
                                    .remove(subtask);
                                //});
                                widget
                                    .onSubtasksChanged(widget.taskWithSubtasks);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    //}
    //;
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
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: widget.taskList == null
              ? const Text('Add a new tasklist')
              : const Text('Edit tasklist'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Padding(
            //padding: const EdgeInsets.all(12.0),
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
        ));
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
  final TextEditingController _locationController = TextEditingController();
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
      widget.task?.location != null
          ? _locationController.text = widget.task!.location
          : _locationController.text = '';
      _taskColor = widget.task!.color;
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final isCompleted = widget.task == null ? false : widget.task!.isCompleted;
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

    // Add save code here
    widget.task == null
        ? await _databaseManager.insertTask(
            Task(
                title: title,
                description: description,
                location: location,
                isCompleted: isCompleted,
                color: color,
                taskListId: taskListId),
          )
        : await _databaseManager.updateTask(
            Task(
              id: widget.task!.id,
              title: title,
              description: description,
              location: location,
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
            location: location,
            color: color,
            taskListId: taskListId,
          )
        : Task(
            id: widget.task!.id,
            title: title,
            description: description,
            location: location,
            isCompleted: isCompleted,
            color: color,
            taskListId: taskListId,
          );

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
          title: widget.task == null
              ? const Text('Add new task')
              : const Text('Edit task'),
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
            //padding: const EdgeInsets.all(12.0),
            padding:
                EdgeInsets.only(left: 12, right: 12, top: 12, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('List: ${widget.taskList.title}',
                    style: textTheme.titleLarge!),
                const SizedBox(height: 24.0),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Title',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 50,
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
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                ),
                const SizedBox(height: 24.0),
                TextField(
                  controller: _locationController,
                  maxLines: null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Location',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ));
  }
}

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
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final isCompleted = widget.measurableTask == null
        ? false
        : widget.measurableTask!.isCompleted;
    final color = _measurableTaskColor;
    final taskListId = widget.taskList.id;
    final howMuchHasBeenDone =  _hasBeenDoneController.text == ''? double.parse('0.0') : double.parse( _hasBeenDoneController.text);
        //: widget.measurableTask!.howMuchHasBeenDone;
    // final targetAtLeast =
    //     (_targetType == TargetType.atLeast || _targetType == TargetType.about)
    //         ? double.parse(_targetAtLeastController.text)
    //         : double.negativeInfinity;
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
    // final targetAtMost =
    //     (_targetType == TargetType.atMost || _targetType == TargetType.about)
    //         ? double.parse(_targetAtMostController.text)
    //         : double.infinity;
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
    // double? howMuchHasBeenDone = 0.0;
    // howMuchHasBeenDone = double.tryParse(_hasBeenDoneController.text);
    // if (howMuchHasBeenDone == null) {
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: Text('Error'),
    //       content: Text('Invalid value for "has been done"'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.pop(context),
    //           child: Text('OK'),
    //         ),
    //       ],
    //     ),
    //   );
    //   return;
    //}

    final targetType = _targetType;
    final unit = _unitController.text;

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

    // Add save code here
    widget.measurableTask == null
        ? await _databaseManager.insertMeasurableTask(
            MeasurableTask(
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              taskListId: taskListId,
              targetAtLeast: targetAtLeast,
              targetAtMost: targetAtMost,
              targetType: targetType,
              unit: unit,
              howMuchHasBeenDone: howMuchHasBeenDone,
            ),
          )
        : await _databaseManager.updateMeasurableTask(
            MeasurableTask(
              id: widget.measurableTask!.id,
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              taskListId: taskListId,
              targetAtLeast: targetAtLeast,
              targetAtMost: targetAtMost,
              targetType: targetType,
              unit: unit,
              howMuchHasBeenDone: howMuchHasBeenDone,
            ),
          );

    final MeasurableTask measurableTask = widget.measurableTask == null
        ? MeasurableTask(
            title: title,
            isCompleted: isCompleted,
            description: description,
            location: location,
            color: color,
            taskListId: taskListId,
            targetAtLeast: targetAtLeast,
            targetAtMost: targetAtMost,
            targetType: targetType,
            unit: unit,
            howMuchHasBeenDone: howMuchHasBeenDone,
          )
        : MeasurableTask(
            id: widget.measurableTask!.id,
            title: title,
            description: description,
            location: location,
            isCompleted: isCompleted,
            color: color,
            taskListId: taskListId,
            targetAtLeast: targetAtLeast,
            targetAtMost: targetAtMost,
            targetType: targetType,
            unit: unit,
            howMuchHasBeenDone: howMuchHasBeenDone,
          );

    Navigator.pop(context, measurableTask);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: widget.measurableTask == null
            ? Text('Add new measurable task')
            : Text('Edit measurable task'),
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
          //padding: const EdgeInsets.all(12.0),
          padding:
              EdgeInsets.only(left: 12, right: 12, top: 12, bottom: bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('List: ${widget.taskList.title}',
                  style: textTheme.titleLarge!),
              const SizedBox(height: 24.0),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Title',
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: ColorSeedButton(
                          colorSelected: ColorSeed.values.firstWhere(
                            (e) => e.color == _measurableTaskColor,
                            orElse: () => ColorSeed.baseColor,
                          ),
                          handleColorSelect: (index) {
                            setState(() {
                              _measurableTaskColor =
                                  ColorSeed.values[index].color;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description',
                    floatingLabelBehavior: FloatingLabelBehavior.auto),
              ),
              const SizedBox(height: 24.0),
              TextField(
                controller: _locationController,
                maxLines: null,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Location',
                    floatingLabelBehavior: FloatingLabelBehavior.auto),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TargetType>(
                      value: _targetType,
                      onChanged: (value) =>
                          setState(() => _targetType = value!),
                      items: TargetType.values
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e == TargetType.atLeast
                                    ? 'at least'
                                    : e == TargetType.atMost
                                        ? 'at most'
                                        : 'about'),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Target Type',
                          floatingLabelBehavior: FloatingLabelBehavior.auto),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a target type';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Unit',
                          floatingLabelBehavior: FloatingLabelBehavior.auto),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please input unit';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_targetType == TargetType.atLeast ||
                      _targetType == TargetType.about)
                    Expanded(
                      child: TextFormField(
                        controller: _targetAtLeastController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'min.',
                            floatingLabelBehavior: FloatingLabelBehavior.auto),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: false),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập giá trị ít nhất';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Vui lòng nhập số';
                          }
                          return null;
                        },
                      ),
                    ),
                  if (_targetType == TargetType.about)
                    const SizedBox(width: 12),
                  if (_targetType == TargetType.atMost ||
                      _targetType == TargetType.about)
                    Expanded(
                      child: TextFormField(
                        controller: _targetAtMostController,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'max.',
                            floatingLabelBehavior: FloatingLabelBehavior.auto),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: false),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập giá trị nhiều nhất';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Vui lòng nhập số';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hasBeenDoneController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Has been done',
                          floatingLabelBehavior: FloatingLabelBehavior.auto),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: false),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá trị';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Vui lòng nhập số';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddOrEditTaskWithSubtasksPage extends StatefulWidget {
  const AddOrEditTaskWithSubtasksPage(
      {Key? key, this.taskWithSubtasks, required this.taskList})
      : super(key: key);
  final TaskList taskList;
  final TaskWithSubtasks? taskWithSubtasks;

  @override
  _AddOrEditTaskWithSubtasksPageState createState() =>
      _AddOrEditTaskWithSubtasksPageState();
}

class _AddOrEditTaskWithSubtasksPageState
    extends State<AddOrEditTaskWithSubtasksPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final DatabaseManager _databaseManager = DatabaseManager();
  List<Subtask> _subtasks = [];

  Color _taskWithSubtasksColor = ColorSeed.baseColor.color;

  @override
  void initState() {
    super.initState();
    if (widget.taskWithSubtasks != null) {
      widget.taskWithSubtasks?.title != null
          ? _titleController.text = widget.taskWithSubtasks!.title
          : _titleController.text = '';
      widget.taskWithSubtasks?.description != null
          ? _descriptionController.text = widget.taskWithSubtasks!.description
          : _descriptionController.text = '';
      widget.taskWithSubtasks?.location != null
          ? _locationController.text = widget.taskWithSubtasks!.location
          : _locationController.text = '';
      widget.taskWithSubtasks?.subtasks != null
          ? _subtasks = widget.taskWithSubtasks!.subtasks
          : _subtasks = [];
      _taskWithSubtasksColor = widget.taskWithSubtasks!.color;
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    final location = _locationController.text;
    final isCompleted = widget.taskWithSubtasks == null
        ? false
        : widget.taskWithSubtasks!.isCompleted;
    final color = _taskWithSubtasksColor;
    final taskListId = widget.taskList.id;
    final subtasks = _subtasks;

    widget.taskWithSubtasks == null
        ? await _databaseManager.insertTaskWithSubtasks(
            TaskWithSubtasks(
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              taskListId: taskListId,
              subtasks: subtasks,
            ),
          )
        : await _databaseManager.updateTaskWithSubtasks(
            TaskWithSubtasks(
              id: widget.taskWithSubtasks!.id,
              title: title,
              description: description,
              location: location,
              isCompleted: isCompleted,
              color: color,
              taskListId: taskListId,
              subtasks: subtasks,
            ),
          );

    final TaskWithSubtasks taskWithSubtasks = widget.taskWithSubtasks == null
        ? TaskWithSubtasks(
            title: title,
            isCompleted: isCompleted,
            description: description,
            location: location,
            color: color,
            taskListId: taskListId,
            subtasks: subtasks,
          )
        : TaskWithSubtasks(
            id: widget.taskWithSubtasks!.id,
            title: title,
            description: description,
            location: location,
            isCompleted: isCompleted,
            color: color,
            taskListId: taskListId,
            subtasks: subtasks,
          );

    Navigator.pop(context, taskWithSubtasks);
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
          title: widget.taskWithSubtasks == null
              ? Text('Add new task')
              : Text('Edit task'),
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
                EdgeInsets.only(left: 12, right: 12, top: 12, bottom: bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('List: ${widget.taskList.title}',
                    style: textTheme.titleLarge!),
                const SizedBox(height: 24.0),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Title',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ColorSeedButton(
                            colorSelected: ColorSeed.values.firstWhere(
                              (e) => e.color == _taskWithSubtasksColor,
                              orElse: () => ColorSeed.baseColor,
                            ),
                            handleColorSelect: (index) {
                              setState(() {
                                _taskWithSubtasksColor =
                                    ColorSeed.values[index].color;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                ),
                const SizedBox(height: 24.0),
                TextField(
                  controller: _locationController,
                  maxLines: null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Location',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                ),
                const SizedBox(height: 24.0),
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

                      // Text(
                      //   subtask.title,
                      //   style: TextStyle(
                      //     decoration: subtask.isSubtaskCompleted
                      //         ? TextDecoration.lineThrough
                      //         : TextDecoration.none,
                      //   ),
                      // ),
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
