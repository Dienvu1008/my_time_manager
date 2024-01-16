import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';

class TasksMonthView extends StatefulWidget {
  //final GlobalKey<WeekViewState>? state;
  //final double? width;
  const TasksMonthView({
    Key? key,
    //this.state
  }) : super(key: key);

  @override
  _TasksMonthViewState createState() => _TasksMonthViewState();
}

class _TasksMonthViewState extends State<TasksMonthView> {
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
        child: MonthViewWidget(
          //key: widget.state,
          width: width,
        ),
      ),
    );
  }
}

class MonthViewWidget extends StatelessWidget {
  final GlobalKey<MonthViewState>? state;
  final double? width;

  const MonthViewWidget({
    super.key,
    this.state,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return MonthView(
      key: state,
      width: width,
      onEventTap: (event, date) {
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (_) => DetailsPage(
        //       event: event,
        //     ),
        //   ),
        // );
      },
    );
  }
}
