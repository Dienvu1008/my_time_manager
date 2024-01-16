import 'dart:async';
import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';
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
    }
    setState(() => _timeIntervals = timeIntervals);
  }

  @override
  Widget build(BuildContext context) {
    List<CalendarTimeIntervalData> _calendarTimeIntervals =
        _timeIntervals.toCalendarData();
    ;
    final width = MediaQuery.of(context).size.width;
    return CalendarControllerProvider(
      controller: TimeIntervalController()..addAll(_calendarTimeIntervals),
      child: Expanded(
        child: WeekViewWidget(
          //key: widget.state,
          width: width,
        ),
      ),
    );
  }
}

class WeekViewWidget extends StatelessWidget {
  final GlobalKey<WeekViewState>? state;
  final double? width;

  const WeekViewWidget({super.key, this.state, this.width});

  @override
  Widget build(BuildContext context) {
    return WeekView(
      key: state,
      width: width,
      onTimeIntervalTileTap: (events, date) {
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (_) => DetailsPage(
        //       event: events.first,
        //     ),
        //   ),
        // );
      },
      leftSideHourIndicatorBuilder: _leftSideHourIndicatorBuilder,
    );
  }

  Widget _leftSideHourIndicatorBuilder(DateTime date) {
    final timeString = date.toString().substring(11, 16);
    //if (date.minute != 0) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            //"${date.hour}:${date.minute}",
            timeString,
            textAlign: TextAlign.right,
            style: TextStyle(
              //color: Colors.black.withAlpha(50),
              //fontStyle: FontStyle.italic,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
