import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';
import 'package:calendar_widgets/calendar_widgets.dart';

class TasksDayView extends StatefulWidget {
  //final GlobalKey<WeekViewState>? state;
  //final double? width;
  const TasksDayView({
    Key? key,
    //this.state
  }) : super(key: key);

  @override
  _TasksDayViewState createState() => _TasksDayViewState();
}

class _TasksDayViewState extends State<TasksDayView> {
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
      //await timeInterval.init();
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
        child: DayViewWidget(
          //key: widget.state,
          width: width,
        ),
      ),
    );
  }
}

class DayViewWidget extends StatelessWidget {
  final GlobalKey<DayViewState>? state;
  final double? width;

  const DayViewWidget({
    super.key,
    this.state,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return DayView(
      key: state,
      width: width,
      startDuration: Duration(hours: 8),
      showHalfHours: true,
      heightPerMinute: 3,
      leftSideHourIndicatorBuilder: _leftSideHourIndicatorBuilder,
      hourIndicatorSettings: HourIndicatorSettings(
        color: Theme.of(context).dividerColor,
      ),
      onEventTap: (events, date) {
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (_) => DetailsPage(
        //       event: events.first,
        //     ),
        //   ),
        // );
      },
      halfHourIndicatorSettings: HourIndicatorSettings(
        color: Theme.of(context).dividerColor,
        lineStyle: LineStyle.dashed,
      ),
    );
  }

  Widget _leftSideHourIndicatorBuilder(DateTime date) {
    //if (date.minute != 0) {
    final timeString = date.toString().substring(11, 16);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            timeString,
            //"${date.hour}:${date.minute}",
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

  //   final hour = ((date.hour - 1) % 12) + 1;
  //   return Stack(
  //     clipBehavior: Clip.none,
  //     children: [
  //       Positioned.fill(
  //         top: -8,
  //         right: 8,
  //         child: Text(
  //           "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}",
  //           textAlign: TextAlign.right,
  //           style: TextStyle(
  //             color: Colors.black.withAlpha(50),
  //             fontStyle: FontStyle.italic,
  //             fontSize: 8,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
