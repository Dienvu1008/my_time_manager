import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/data/models/models.dart';
import 'package:my_time_manager/screen_tasks/tasks_overview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/database_manager.dart';

class TaskListsHolderBloc extends Bloc<TaskListsHolderEvent, TaskListsHolderState> {
  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;

  TaskListsHolderBloc() : super(TaskListsHolderState(taskLists: [], isLoading: true)) {
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


class BlocTasksOverviewPage extends StatelessWidget {
  const BlocTasksOverviewPage({Key? key}) : super(key: key);

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
                  context.read<TaskListsHolderBloc>().add(ReorderTaskListsEvent(oldIndex: oldIndex, newIndex: newIndex));
                },
                taskLists: state.taskLists,
                onTaskListDelete: (value) async {
                  context.read<TaskListsHolderBloc>().add(DeleteTaskListEvent(id: value.id));
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
                      context.read<TaskListsHolderBloc>().add(AddTaskListEvent(taskList: taskList));
                      context.read<TaskListsHolderBloc>().add(LoadTaskListsEvent());
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
                  onPressed: () async {
                    await DatabaseManager().deleteDatabase();
                    context.read<TaskListsHolderBloc>().add(LoadTaskListsEvent());
                  },
                  child: const Icon(Icons.delete),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

