import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_list.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_measurable_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_measurale_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_task_with_subtasks.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_time_interval.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/app_localizations.dart';
import '../data/database/database_manager.dart';
import '../data/models/models.dart';
import '../home/component_widgets/app_drawer.dart';
import '../home/component_widgets/button_brightness.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';
import '../home/component_widgets/button_material3.dart';
import '../home/component_widgets/button_select_calendar_mode.dart';
import '../home/component_widgets/button_show_timeline_calendar.dart';
import '../home/component_widgets/button_use_bottom_bar.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

class TasksOverviewPage extends StatefulWidget {
  final Function handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function(int) handleColorSelect;
  final bool useBottomBar;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;
  final bool showBrightnessButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;

  final bool isProVersion;

  const TasksOverviewPage({super.key,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleUsingBottomBarChange,
    required this.useBottomBar,
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.handleLanguageSelect,
    required this.languageSelected,
    required this.showBrightnessButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.isProVersion});

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
    //if(mounted)
    setState(() => _taskLists = taskLists);
    //_taskLists = taskLists;
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
    final localizations = AppLocalizations.of(context);
    //_init();
    if (_taskLists == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Expanded(
      child: Column(
        children: [
          AppBar(title: Text(localizations!.overview, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              actions: [
                MenuAnchor(
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
                    if (widget.showBrightnessButtonInAppBar)
                    BrightnessMenuItemButton(
                      handleBrightnessChange: widget.handleBrightnessChange,
                    ),
                    if (widget.showMaterialDesignButtonInAppBar)
                    Material3MenuItemButton(
                      handleMaterialVersionChange:
                      widget.handleMaterialVersionChange,
                    ),

                    UsingBottomBarMenuItemButton(
                        handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
                        useBottomBar: widget.useBottomBar),
                    if (widget.showColorSeedButtonInAppBar)
                    ColorSeedSubmenuButton(
                      handleColorSelect: widget.handleColorSelect,
                      colorSelected: widget.colorSelected,
                      colorSelectionMethod: widget.colorSelectionMethod,
                    ),
                    if (widget.showColorImageButtonInAppBar)
                    ColorImageSubmenuButton(
                      handleImageSelect: widget.handleImageSelect,
                      imageSelected: widget.imageSelected,
                      colorSelectionMethod: widget.colorSelectionMethod,
                    ),
                    if (widget.showLanguagesButtonInAppBar)
                    LanguageSubmenuButton(
                      handleLanguageSelect: widget.handleLanguageSelect,
                      languageSelected: widget.languageSelected,
                    ),
                  ],
                ),
              ]),
          Expanded(
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
                    updatedTaskLists.sort((a, b) =>
                        order.indexOf(a.id).compareTo(order.indexOf(b.id)));
                  }
                  setState(() => _taskLists = updatedTaskLists);
                },
                isProVersion: widget.isProVersion,
              ),
              floatingActionButton:
                  //Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  FloatingActionButton.small(
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

              // const SizedBox(
              //   width: 10.0,
              //   height: 20.0,
              // ),
              // FloatingActionButton(
              //   onPressed: _deleteDatabase,
              //   child: const Icon(Icons.delete),
              //),
              //]
              //),
            ),
          )
        ],
      ),
    );
  }
}

class TaskListsHolder extends StatefulWidget {
  const TaskListsHolder({
    Key? key,
    required this.onTaskListDelete,
    required this.onTaskListEdit,
    required this.onReorder,
    required this.taskLists,
    required this.isProVersion,
  }) : super(key: key);

  final Function(TaskList) onTaskListDelete;
  final Function(TaskList) onTaskListEdit;
  final Function(int, int) onReorder;
  final List<TaskList> taskLists;
  final bool isProVersion;

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
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete this list'),
                content: Text(
                    'Are you sure you want to delete this list and all its tasks and events?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              ),
            );

            if (shouldDelete ?? false) {
              widget.onTaskListDelete(taskList);
              setState(() => widget.taskLists.remove(taskList));
            }
          },
          onTaskListEdit: widget.onTaskListEdit,
          isProVersion: widget.isProVersion,
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
    required this.isProVersion,
  }) : super(key: key);

  final TaskList taskList;
  final Function(TaskList) onTaskListEdit;
  final Function(TaskList) onTaskListDelete;
  final bool isProVersion;

  @override
  _TaskListCardState createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;
  bool _isExpanded = false;
  final Map<String, bool> _isTaskWithSubtasksCardsExpanded = {};
  final Map<String, bool> _isMeasurableTaskCardsExpanded = {};
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

    for (var taskWithSubtasks in tasksWithSubtasks) {
      _isTaskWithSubtasksCardsExpanded[taskWithSubtasks.id] =
          _prefs.getBool('isExpanded_${taskWithSubtasks.id}') ?? false;
    }

    for (var measurableTask in measurableTasks) {
      _isMeasurableTaskCardsExpanded[measurableTask.id] =
          _prefs.getBool('isExpanded_${measurableTask.id}') ?? false;
    }

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
    Task _task = task.copyWith(
      isCompleted: !task.isCompleted,
    );
    final index = _items.indexWhere((item) => item.id == _task.id);
    if (index != -1) {
      setState(() {
        _items[index] = _task;
      });
    }

    await _databaseManager.updateTask(_task);
  }

  Future<void> _onMeasurableTaskToggleCompleted(
      MeasurableTask measurableTask) async {
    MeasurableTask _measurableTask = measurableTask.copyWith(
      isCompleted: !measurableTask.isCompleted,
    );
    final index = _items.indexWhere((item) => item.id == _measurableTask.id);
    if (index != -1) {
      setState(() {
        _items[index] = _measurableTask;
      });
    }
    await _databaseManager.updateMeasurableTask(_measurableTask);
  }

  Future<void> _onHasBeenDoneUpdate(MeasurableTask measurableTask) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: measurableTask.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.hasBeenDone),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              MeasurableTask _measurableTask = measurableTask.copyWith(
                  howMuchHasBeenDone:
                      double.parse(_hasBeenDoneController.text));
              final index =
                  _items.indexWhere((item) => item.id == _measurableTask.id);
              if (index != -1) {
                setState(() {
                  _items[index] = _measurableTask;
                });
              }
              await _databaseManager.updateMeasurableTask(_measurableTask);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  Future<void> _onTaskWithSubtasksToggleCompleted(
      TaskWithSubtasks taskWithSubtasks) async {
    TaskWithSubtasks _taskWithSubtasks =
        taskWithSubtasks.copyWith(isCompleted: !taskWithSubtasks.isCompleted);
    final index = _items.indexWhere((item) => item.id == _taskWithSubtasks.id);
    if (index != -1) {
      setState(() {
        _items[index] = _taskWithSubtasks;
      });
    }
    await _databaseManager.updateTaskWithSubtasks(_taskWithSubtasks);
  }

  Future<void> _onSubtasksChanged(TaskWithSubtasks taskWithSubtasks) async {
    TaskWithSubtasks _taskWithSubtasks = taskWithSubtasks;

    final index = _items.indexWhere((item) => item.id == _taskWithSubtasks.id);
    if (index != -1) {
      setState(() {
        _items[index] = _taskWithSubtasks;
      });
    }

    await _databaseManager.updateTaskWithSubtasks(_taskWithSubtasks);
  }

  Future<void> _onTaskDelete(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations!.deleteTask),
          content: Text(localizations.areYouSureYouWantToDeleteThisTask),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
    if (result == true) {
      setState(() {
        _items.remove(task);
      });
      await _saveOrder();
      await _databaseManager.deleteTask(task.id);
    }
  }

  Future<void> _onMeasurableTaskDelete(MeasurableTask measurableTask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations!.deleteTask),
          content: Text(localizations.areYouSureYouWantToDeleteThisTask),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
    if (result == true) {
      setState(() {
        _items.remove(measurableTask);
      });
      await _saveOrder();
      await _databaseManager.deleteMeasurableTask(measurableTask.id);
    }
  }

  Future<void> _onTaskWithSubtasksDelete(
      TaskWithSubtasks taskWithSubtasks) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations!.deleteTask),
          content: Text(localizations.areYouSureYouWantToDeleteThisTask),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
    if (result == true) {
      setState(() {
        _items.remove(taskWithSubtasks);
      });
      await _saveOrder();
      await _databaseManager.deleteTaskWithSubtasks(taskWithSubtasks.id);
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

  void _onTaskWithSubtasksCardExpanded(
      TaskWithSubtasks taskWithSubtasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isExpanded =
        _isTaskWithSubtasksCardsExpanded[taskWithSubtasks.id] ?? false;
    setState(() {
      _isTaskWithSubtasksCardsExpanded[taskWithSubtasks.id] = !isExpanded;
    });
    await prefs.setBool('isExpanded_${taskWithSubtasks.id}', !isExpanded);
  }

  void _onMeasurableTaskCardExpanded(MeasurableTask measurableTask) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isExpanded =
        _isMeasurableTaskCardsExpanded[measurableTask.id] ?? false;
    setState(() {
      _isMeasurableTaskCardsExpanded[measurableTask.id] = !isExpanded;
    });
    await prefs.setBool('isExpanded_${measurableTask.id}', !isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(0.0),
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

    //     ListTile(
    //       contentPadding: const EdgeInsets.only(right:0, left: 0),
    //     leading: IconButton(
    //     icon: Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right),
    //     onPressed: () => setState(() {
    //       _isExpanded = !_isExpanded;
    //       _prefs.setBool('${widget.taskList.id}_isExpanded', _isExpanded);
    //     }),
    //   ),
    //   title: GestureDetector(
    //     onTap: () => widget.onTaskListEdit(widget.taskList),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(widget.taskList.title, style: textTheme.titleMedium),
    //         const SizedBox(height: 4.0),
    //         if (_isExpanded && widget.taskList.description.isNotEmpty)
    //           Text(widget.taskList.description),
    //       ],
    //     ),
    //   ),
    //   trailing: TaskListCardOptions(
    //     taskList: widget.taskList,
    //     onTaskListDelete: () => widget.onTaskListDelete(widget.taskList),
    //     onTaskListEdit: () => widget.onTaskListEdit(widget.taskList),
    //     addTask: (value) => _addTask(value),
    //     addMeasurableTask: (value) => _addMeasurableTask(value),
    //     addTaskWithSubtasks: (value) => _addTaskWithSubtasks(value),
    //   ),
    // ),

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
              onHasBeenDoneUpdate: _onHasBeenDoneUpdate,
              isMeasurableTaskCardExpanded: (MeasurableTask measurableTask) {
                return _isMeasurableTaskCardsExpanded[measurableTask.id] ??
                    false;
              },
              onMeasurableTaskCardExpanded: (MeasurableTask measurableTask) {
                _onMeasurableTaskCardExpanded(measurableTask);
              },
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
              isTaskWithSubtasksCardExpanded:
                  (TaskWithSubtasks taskWithSubtasks) {
                return _isTaskWithSubtasksCardsExpanded[taskWithSubtasks.id] ??
                    false;
              },
              onTaskWithSubtasksCardExpanded:
                  (TaskWithSubtasks taskWithSubtasks) {
                _onTaskWithSubtasksCardExpanded(taskWithSubtasks);
              },
              isProVersion: widget.isProVersion,
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
    final localizations = AppLocalizations.of(context);
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
              child: Text(localizations!.addANewTask),
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
              child: Text(localizations.addANewMeasureableTask),
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
              child: Text(localizations
                  .addANewTaskWithSubTasks), //Text(localizations.addANewTaskWithSubtasks),
            ),
            MenuItemButton(
              onPressed: () => showComingSoonDialog(context),
              child: Text(localizations.addANewEvent),
            ),
          ],
          child: Row(
            children: [
              const Icon(Icons.add_outlined),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.addToThisList)
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListEdit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.editThisList)
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListDelete,
          child: Row(
            children: [
              const Icon(Icons.delete_outline),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.deleteThisList)
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
    required this.onHasBeenDoneUpdate,
    required this.isMeasurableTaskCardExpanded,
    required this.onMeasurableTaskCardExpanded,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
    required this.isTaskWithSubtasksCardExpanded,
    required this.onTaskWithSubtasksCardExpanded,
    required this.isProVersion,
  }) : super(key: key);

  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskToggleComplete;

  final Function(MeasurableTask) onMeasurableTaskEdit;
  final Function(MeasurableTask) onMeasurableTaskDelete;
  final Function(MeasurableTask) onMeasurableTaskToggleComplete;
  final Function(MeasurableTask) onHasBeenDoneUpdate;
  final bool Function(MeasurableTask) isMeasurableTaskCardExpanded;
  final Function(MeasurableTask) onMeasurableTaskCardExpanded;

  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;
  final bool Function(TaskWithSubtasks) isTaskWithSubtasksCardExpanded;
  final Function(TaskWithSubtasks) onTaskWithSubtasksCardExpanded;
  final List<dynamic> items;
  final Function(int, int) onReorder;
  final bool isProVersion;

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
            isProVersion: widget.isProVersion,
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
            onHasBeenDoneUpdate: (MeasurableTask measurableTask) async {
              widget.onHasBeenDoneUpdate(measurableTask);
            },
            isMeasurableTaskCardExpanded: widget.isMeasurableTaskCardExpanded,
            onMeasurableTaskCardExpanded: (MeasurableTask measurableTask) {
              widget.onMeasurableTaskCardExpanded(measurableTask);
            },
            isProVersion: widget.isProVersion,
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
            onTaskWithSubtasksCardExpanded:
                (TaskWithSubtasks taskWithSubtasks) {
              widget.onTaskWithSubtasksCardExpanded(taskWithSubtasks);
            },
            isTaskWithSubtasksCardExpanded:
                widget.isTaskWithSubtasksCardExpanded,
            isProVersion: widget.isProVersion,
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

class TaskWithSubtasksBloc
    extends Bloc<TaskWithSubtasksEvent, TaskWithSubtasksState> {
  final TaskWithSubtasks taskWithSubtasks;
  late SharedPreferences _prefs;

  TaskWithSubtasksBloc(this.taskWithSubtasks)
      : super(TaskWithSubtasksInitial()) {
    on<InitTaskWithSubtasks>((event, emit) async {
      _prefs = await SharedPreferences.getInstance();
      final isExpanded =
          _prefs.getBool('isExpanded_${taskWithSubtasks.id}') ?? true;
      emit(TaskWithSubtasksLoaded(isExpanded));
    });

    on<SaveIsExpanded>((event, emit) async {
      _prefs.setBool('isExpanded_${taskWithSubtasks.id}', event.isExpanded);
    });
  }
}

abstract class TaskWithSubtasksEvent {}

class InitTaskWithSubtasks extends TaskWithSubtasksEvent {}

class SaveIsExpanded extends TaskWithSubtasksEvent {
  final bool isExpanded;

  SaveIsExpanded(this.isExpanded);
}

abstract class TaskWithSubtasksState {}

class TaskWithSubtasksInitial extends TaskWithSubtasksState {}

class TaskWithSubtasksLoaded extends TaskWithSubtasksState {
  final bool isExpanded;

  TaskWithSubtasksLoaded(this.isExpanded);
}

class BlocTaskWithSubtasksCard extends StatelessWidget {
  final TaskWithSubtasks taskWithSubtasks;
  final Function(TaskWithSubtasks) onTaskWithSubtasksEdit;
  final Function(TaskWithSubtasks) onTaskWithSubtasksDelete;
  final Function(TaskWithSubtasks) onTaskWithSubtasksToggleComplete;
  final Function(TaskWithSubtasks) onSubtasksChanged;

  const BlocTaskWithSubtasksCard({
    Key? key,
    required this.taskWithSubtasks,
    required this.onTaskWithSubtasksEdit,
    required this.onTaskWithSubtasksDelete,
    required this.onTaskWithSubtasksToggleComplete,
    required this.onSubtasksChanged,
  }) : super(key: key);

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
    final taskWithSubtasksColor = taskWithSubtasks.color;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: taskWithSubtasksColor)
        : ColorScheme.light(primary: taskWithSubtasksColor);
    final backgroundColor = myColorScheme.primaryContainer;
    final labelColor = contrastColor(backgroundColor);

    return BlocProvider(
      create: (context) =>
          TaskWithSubtasksBloc(taskWithSubtasks)..add(InitTaskWithSubtasks()),
      child: BlocBuilder<TaskWithSubtasksBloc, TaskWithSubtasksState>(
        builder: (context, state) {
          if (state is TaskWithSubtasksInitial) {
            return const CircularProgressIndicator();
          } else if (state is TaskWithSubtasksLoaded) {
            return Card(
              color: backgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onTaskWithSubtasksEdit(taskWithSubtasks),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              taskWithSubtasks.title,
                              style: TextStyle(
                                color: labelColor,
                                decoration: taskWithSubtasks.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: taskWithSubtasks.description.isNotEmpty
                                ? Text(
                                    taskWithSubtasks.description,
                                    style: TextStyle(color: labelColor),
                                  )
                                : null,
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_outlined,
                                  color: labelColor),
                              onSelected: (String result) {
                                if (result == 'option1') {
                                  onTaskWithSubtasksEdit(taskWithSubtasks);
                                } else if (result == 'option2') {
                                  onTaskWithSubtasksDelete(taskWithSubtasks);
                                } else if (result == 'option3') {
                                  onTaskWithSubtasksToggleComplete(
                                      taskWithSubtasks);
                                } else if (result == 'option4') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => TimeIntervalPage(
                                            taskWithSubtasks:
                                                taskWithSubtasks)),
                                  );
                                } else if (result == 'option5') {
                                  final isExpanded = !state.isExpanded;
                                  context
                                      .read<TaskWithSubtasksBloc>()
                                      .add(SaveIsExpanded(isExpanded));
                                  context
                                      .read<TaskWithSubtasksBloc>()
                                      .add(InitTaskWithSubtasks());
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'option5',
                                  child: Row(
                                    children: [
                                      Icon(state.isExpanded
                                          ? Icons.chevron_right
                                          : Icons.expand_more),
                                      const SizedBox(width: 8),
                                      state.isExpanded
                                          ? const Text('Hide sub-tasks')
                                          : const Text('Show sub-tasks'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'option3',
                                  child: Row(
                                    children: [
                                      Icon(taskWithSubtasks.isCompleted
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank),
                                      const SizedBox(width: 8),
                                      taskWithSubtasks.isCompleted
                                          ? const Text('Mark as incompleted')
                                          : const Text('Mark as completed'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'option4',
                                  child: Row(
                                    children: [
                                      Icon(Icons.hourglass_empty_outlined),
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
                          if (state.isExpanded)
                            ...taskWithSubtasks.subtasks.map(
                              (subtask) => CheckboxListTile(
                                side: BorderSide(
                                  color: labelColor,
                                ),
                                activeColor: labelColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: subtask.isSubtaskCompleted,
                                onChanged: (value) {
                                  subtask.isSubtaskCompleted = value ?? false;
                                  onSubtasksChanged(taskWithSubtasks);
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
                                          title: const Text('Delete Subtask'),
                                          content: const Text(
                                              'Are you sure you want to delete this subtask?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result == true) {
                                      taskWithSubtasks.subtasks.remove(subtask);
                                      onSubtasksChanged(taskWithSubtasks);
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
          } else {
            // Handle other states or errors here
            return SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class BlocTasksOverviewPage extends StatelessWidget {
  const BlocTasksOverviewPage({Key? key, required this.isProVersion}) : super(key: key);
  final bool isProVersion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListsHolderBloc(),
      child: BlocBuilder<TaskListsHolderBloc, TaskListsHolderState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Expanded(
            child: Scaffold(
              body: TaskListsHolder(
                onReorder: (oldIndex, newIndex) {
                  context.read<TaskListsHolderBloc>().add(ReorderTaskListsEvent(
                      oldIndex: oldIndex, newIndex: newIndex));
                },
                taskLists: state.taskLists,
                // onTaskListDelete: (value) async {
                //   context
                //       .read<TaskListsHolderBloc>()
                //       .add(DeleteTaskListEvent(id: value.id));
                // },
                onTaskListDelete: (value) async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete this list'),
                      content: Text(
                          'Are you sure you want to delete this list and all its tasks and events?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete ?? false) {
                    context
                        .read<TaskListsHolderBloc>()
                        .add(DeleteTaskListEvent(id: value.id));
                  } else {}
                },

                onTaskListEdit: (TaskList taskList) async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddOrEditTaskListPage(taskList: taskList),
                      fullscreenDialog: false,
                    ),
                  );
                  context.read<TaskListsHolderBloc>().add(LoadTaskListsEvent());
                },
                isProVersion: isProVersion,
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
                      context
                          .read<TaskListsHolderBloc>()
                          .add(AddTaskListEvent(taskList: taskList));
                      context
                          .read<TaskListsHolderBloc>()
                          .add(LoadTaskListsEvent());
                    }
                  },
                  heroTag: 'addTaskList',
                  child: const Icon(Icons.add),
                ),
                // const SizedBox(
                //   width: 10.0,
                //   height: 20.0,
                // ),
                // FloatingActionButton(
                //   onPressed: () async {
                //     await DatabaseManager().deleteDatabase();
                //     context.read<TaskListsHolderBloc>().add(LoadTaskListsEvent());
                //   },
                //   child: const Icon(Icons.delete),
                // ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderBloc
class TaskListsHolderBloc
    extends Bloc<TaskListsHolderEvent, TaskListsHolderState> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;

  TaskListsHolderBloc()
      : super(TaskListsHolderState(taskLists: [], isLoading: true)) {
    _init();
    on<LoadTaskListsEvent>(_onLoadTaskListsEvent);
    on<ReorderTaskListsEvent>(_onReorderTaskListsEvent);
    on<DeleteTaskListEvent>(_onDeleteTaskListEvent);
    on<AddTaskListEvent>(_onAddTaskListEvent);
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    add(LoadTaskListsEvent());
  }

  Future<void> _onLoadTaskListsEvent(
      LoadTaskListsEvent event, Emitter<TaskListsHolderState> emit) async {
    emit(state.copyWith(isLoading: true));
    final taskLists = await _databaseManager.taskLists();
    final order = _prefs.getStringList('taskListOrder');
    if (order != null) {
      taskLists
          .sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }
    emit(state.copyWith(taskLists: taskLists, isLoading: false));
  }

  Future<void> _onReorderTaskListsEvent(
      ReorderTaskListsEvent event, Emitter<TaskListsHolderState> emit) async {
    final taskLists = state.taskLists;
    int newIndex = event.newIndex;
    if (event.oldIndex < newIndex) newIndex -= 1;
    final taskList = taskLists.removeAt(event.oldIndex);
    taskLists.insert(newIndex, taskList);
    await _saveOrder(taskLists);
    emit(state.copyWith(taskLists: taskLists));
  }

  Future<void> _onDeleteTaskListEvent(
      DeleteTaskListEvent event, Emitter<TaskListsHolderState> emit) async {
    await _databaseManager.deleteTaskList(event.id);
    final taskLists = state.taskLists..removeWhere((b) => b.id == event.id);
    await _saveOrder(taskLists);
    emit(state.copyWith(taskLists: taskLists));
  }

//   Future<void> _onDeleteTaskListEvent(
//   DeleteTaskListEvent event,
//   Emitter<TaskListsHolderState> emit,
//   Future<bool> Function() confirmDelete,
// ) async {
//   final shouldDelete = await confirmDelete();
//   if (shouldDelete) {
//     await _databaseManager.deleteTaskList(event.id);
//     final taskLists = state.taskLists..removeWhere((b) => b.id == event.id);
//     await _saveOrder(taskLists);
//     emit(state.copyWith(taskLists: taskLists));
//   }
// }

  Future<void> _onAddTaskListEvent(
      AddTaskListEvent event, Emitter<TaskListsHolderState> emit) async {
    final taskLists = state.taskLists..insert(0, event.taskList);
    await _saveOrder(taskLists);
    emit(state.copyWith(taskLists: taskLists));
  }

  Future<void> _saveOrder(List<TaskList> taskLists) async {
    final order = taskLists.map((taskList) => taskList.id).toList();
    await _prefs.setStringList('taskListOrder', order);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderEvent
class TaskListsHolderEvent {}

class LoadTaskListsEvent extends TaskListsHolderEvent {}

class ReorderTaskListsEvent extends TaskListsHolderEvent {
  final int oldIndex;
  final int newIndex;

  ReorderTaskListsEvent({required this.oldIndex, required this.newIndex});
}

class DeleteTaskListEvent extends TaskListsHolderEvent {
  final String id;

  DeleteTaskListEvent({required this.id});
}

class AddTaskListEvent extends TaskListsHolderEvent {
  final TaskList taskList;

  AddTaskListEvent({required this.taskList});
}

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderState
class TaskListsHolderState {
  final List<TaskList> taskLists;
  final bool isLoading;

  TaskListsHolderState({required this.taskLists, required this.isLoading});

  TaskListsHolderState copyWith({List<TaskList>? taskLists, bool? isLoading}) {
    return TaskListsHolderState(
      taskLists: taskLists ?? this.taskLists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
