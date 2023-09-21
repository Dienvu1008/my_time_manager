import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';

class ShowTimeIntervalsBottomSheet extends StatefulWidget {
  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;
  const ShowTimeIntervalsBottomSheet({
    super.key,
    this.taskId,
    this.measurableTaskId,
    this.taskWithSubtasksId,
  });

  @override
  _ShowTimeIntervalsBottomSheetState createState() =>
      _ShowTimeIntervalsBottomSheetState();
}

class _ShowTimeIntervalsBottomSheetState
    extends State<ShowTimeIntervalsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            heightFactor: _animation.value,
            child: DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                maxChildSize: 1,
                minChildSize: 0.4,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Column(
                    children: <Widget>[
                      // Listener(
                      //   onPointerMove: (PointerMoveEvent event) {
                      //     if (event.delta.dy < 0) {
                      //       _controller.forward();
                      //     } else if (event.delta.dy > 0) {
                      //       _controller.reverse();
                      //     }
                      //   },
                      //   child: Container(
                      //     height: 60, // Set this to your desired height
                      //     width: double.infinity,
                      //     color: Colors.grey[300],
                      //     alignment: Alignment.center,
                      //     child: const Icon(Icons.horizontal_rule),
                      //   ),
                      // ),
                      //Không xóa, phần này sẽ được chỉnh sửa sau và thêm vào các chức năng như filter, search...
                      AppBar(
                        toolbarHeight: 40.0,
                        leading: IconButton(
                          icon: AnimatedBuilder(
                            animation: _controller,
                            builder: (BuildContext context, Widget? child) {
                              return Icon(
                                _controller.status == AnimationStatus.completed
                                    ? Icons.unfold_less
                                    : Icons.unfold_more,
                              );
                            },
                          ),
                          onPressed: () {
                            if (_controller.status ==
                                AnimationStatus.completed) {
                              _controller.reverse();
                            } else {
                              _controller.forward();
                            }
                          },
                        ),
                        title: Text('Planned'),
                        actions: <Widget>[
                          //Switch display between calendar and list of time intervals
                          IconButton(
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () {},
                          ),
                          //When you press this button, the calendar or list of time intervals will switch to the current day
                          //or the day closest to the current day.
                          IconButton(
                            icon: const Icon(Icons.today_outlined),
                            onPressed: () {},
                          ),
                          //This filter will screen to display time intervals that are completed, not completed,
                          //past, or have not yet occurred.
                          IconButton(
                            icon: const Icon(Icons.filter_list_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.search_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      Expanded(
                        child: TimeIntervalOfTaskOrEventPage(
                          taskId: widget.taskId,
                          measurableTaskId: widget.measurableTaskId,
                          taskWithSubtasksId: widget.taskWithSubtasksId,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        });
  }
}

class TimeIntervalOfTaskOrEventPage extends StatefulWidget {
  const TimeIntervalOfTaskOrEventPage(
      {super.key, this.taskId, this.measurableTaskId, this.taskWithSubtasksId});

  final String? taskId;
  final String? measurableTaskId;
  final String? taskWithSubtasksId;

  @override
  _TimeIntervalOfTaskOrEventPageState createState() =>
      _TimeIntervalOfTaskOrEventPageState();
}

class _TimeIntervalOfTaskOrEventPageState
    extends State<TimeIntervalOfTaskOrEventPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];
  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.taskId != null) {
      final timeIntervals =
          await _databaseManager.timeIntervalsOfTask(widget.taskId!);
      setState(() => _timeIntervals = timeIntervals);
    } else if (widget.measurableTaskId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfMeasureableTask(widget.measurableTaskId!);
      setState(() => _timeIntervals = timeIntervals);
    } else if (widget.taskWithSubtasksId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfTaskWithSubtasks(widget.taskWithSubtasksId!);
      setState(() => _timeIntervals = timeIntervals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _timeIntervals.length,
        itemBuilder: (context, index) {
          final timeInterval = _timeIntervals[index];
          final textTheme = Theme.of(context).textTheme;
          if (timeInterval.startDate != null) {
            _formattedStartDate = DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .format(timeInterval.startDate!);
          } else {
            _formattedStartDate = '--/--/----';
          }

          if (timeInterval.startTime != null) {
            _formattedStartTime = timeInterval.startTime!.format(context);
          } else {
            _formattedStartTime = '--:--';
          }

          if (timeInterval.endDate != null) {
            _formattedEndDate = DateFormat('EEE, dd MMM, yyyy',
                    Localizations.localeOf(context).languageCode)
                .format(timeInterval.endDate!);
          } else {
            _formattedEndDate = '--/--/----';
          }

          if (timeInterval.endTime != null) {
            _formattedEndTime = timeInterval.endTime!.format(context);
          } else {
            _formattedEndTime = '--:--';
          }

          return ListTile(
              title: RichText(
            text: TextSpan(
              style: textTheme.labelSmall,
              children: <TextSpan>[
                TextSpan(
                  text: timeInterval.isGone == true ? "gone  " : "",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: timeInterval.isInProgress == true
                      ? "in progress  "
                      : "",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: timeInterval.isToday == true ? "today  " : "",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: _formattedStartDate == _formattedEndDate
                      ? '$_formattedStartDate: $_formattedStartTime - $_formattedEndTime'
                      : '$_formattedStartDate: $_formattedStartTime - $_formattedEndDate: $_formattedEndTime',
                ),
              ],
            ),
          )

              //     Text(
              //   '${timeInterval.isGone == true ? "**is gone** " : ""}'
              //   '${timeInterval.isInProgress == true ? "**is in progress** " : ""}'
              //   '${timeInterval.isToday == true ? "**is today** " : ""}'
              //   '${_formattedStartDate == _formattedEndDate ? '$_formattedStartDate: $_formattedStartTime - $_formattedEndTime' : '$_formattedStartDate: $_formattedStartTime - $_formattedEndDate: $_formattedEndTime'}',
              //   style: textTheme.labelSmall,
              // )

              // (_formattedStartDate == _formattedEndDate)
              //     ? Text(
              //         '$_formattedStartDate: $_formattedStartTime - $_formattedEndTime',
              //         style: textTheme.labelSmall,
              //       )
              //     : Text(
              //         '$_formattedStartDate: $_formattedStartTime - $_formattedEndDate: $_formattedEndTime',
              //         style: textTheme.labelSmall,
              //       ),
              );
        });
  }
}
