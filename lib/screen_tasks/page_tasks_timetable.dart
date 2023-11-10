import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/calendar_controller_provider.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/controller_event.dart';
import 'package:my_time_manager/screen_calendar/view_weekly.dart';
import '../data/database/database_manager.dart';

class TasksTimetablePage extends StatefulWidget {
  //final GlobalKey<WeekViewState>? state;

  //final double? width;
  const TasksTimetablePage({
    Key? key,
    //this.state
  }) : super(key: key);

  @override
  _TasksTimetablePageState createState() => _TasksTimetablePageState();
}

class _TasksTimetablePageState extends State<TasksTimetablePage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];

  @override
  void initState() {
    super.initState();
    _init();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('This feature is still under development'),
    //     ),
    //   );
    // });
  }

  Future<void> _init() async {
    final timeIntervals = await _databaseManager.timeIntervals();
    for (final timeInterval in timeIntervals) {
      if (timeInterval.taskId != null) {
        final task = await _databaseManager.task(timeInterval.taskId!);
        timeInterval.color = task.color;
        timeInterval.title = task.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      } else if (timeInterval.measurableTaskId != null) {
        final measurableTask = await _databaseManager
            .measurableTask(timeInterval.measurableTaskId!);
        timeInterval.color = measurableTask.color;
        timeInterval.title = measurableTask.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      } else if (timeInterval.taskWithSubtasksId != null) {
        final taskWithSubtasks = await _databaseManager
            .taskWithSubtasks(timeInterval.taskWithSubtasksId!);
        timeInterval.color = taskWithSubtasks.color;
        timeInterval.title = taskWithSubtasks.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      }
      //await timeInterval.init();
    }
    setState(() => _timeIntervals = timeIntervals);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return CalendarControllerProvider<TimeInterval>(
      controller: EventController<TimeInterval>()..addAll(_timeIntervals),
      child: Expanded(
        child: WeekView<TimeInterval>(
          //key: widget.state,
          width: width,
        ),
      ),
    );
  }
}















