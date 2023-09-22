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
                        //title: Text('Planned'),
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
      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });
      setState(() => _timeIntervals = timeIntervals);
    } else if (widget.measurableTaskId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfMeasureableTask(widget.measurableTaskId!);
      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });
      setState(() => _timeIntervals = timeIntervals);
    } else if (widget.taskWithSubtasksId != null) {
      final timeIntervals = await _databaseManager
          .timeIntervalsOfTaskWithSubtasks(widget.taskWithSubtasksId!);
      timeIntervals.sort((a, b) {
        final aTimestamp = a.startTimestamp ?? a.endTimestamp;
        final bTimestamp = b.startTimestamp ?? b.endTimestamp;

        if (aTimestamp != null && bTimestamp != null) {
          return aTimestamp.compareTo(bTimestamp);
        } else if (aTimestamp != null) {
          return -1;
        } else if (bTimestamp != null) {
          return 1;
        } else {
          return 0;
        }
      });
      setState(() => _timeIntervals = timeIntervals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      //physics: NeverScrollableScrollPhysics(),
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0, // khoảng cách giữa các Chip
                children: <Widget>[
                  if (timeInterval.isGone == true)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(5), // bo tròn viền tại đây
                      ),
                      child: const Text(
                        'gone',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  if (timeInterval.isInProgress == true)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(5), // bo tròn viền tại đây
                      ),
                      child: const Text(
                        'in progress',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  if (timeInterval.isToday == true)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(5), // bo tròn viền tại đây
                      ),
                      child: const Text(
                        'today',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: timeInterval.isCompleted
                      ? textTheme.titleMedium!
                          .copyWith(decoration: TextDecoration.lineThrough)
                      : textTheme.titleMedium,
                  text: _formattedStartDate == _formattedEndDate
                      ? 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndTime'
                      : 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndDate: $_formattedEndTime',
                ),
              ),
              const Divider(
                height: 4,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              //color: labelColor
            ),
            onSelected: (String result) {
              if (result == 'option1') {
                //onTimeIntervalEdit(timeInterval);
              } else if (result == 'option2') {
                //widget.onTimeIntervalDelete(timeInterval);
              } else if (result == 'option3') {
                //widget.onTimeIntervalToggleComplete(timeInterval);
              } else if (result == 'option4') {
                // showModalBottomSheet(
                //   context: context,
                //   isScrollControlled: true,
                //   showDragHandle: true,
                //   builder: (BuildContext context) => SetTimeIntervalBottomSheet(
                //     measurableTaskId: widget.measurableTask.id,
                //   ),
                // );
              } else if (result == 'option6') {
                // setState(() => _isExpanded = !_isExpanded);
                // _saveIsExpanded();
              } else if (result == 'planned') {
                // showModalBottomSheet(
                //   context: context,
                //   isScrollControlled: true,
                //   showDragHandle: true,
                //   builder: (BuildContext context) =>
                //       ShowTimeIntervalsBottomSheet(
                //     measurableTaskId: widget.measurableTask.id,
                //   ),
                // );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // PopupMenuItem<String>(
              //   value: 'option6',
              //   child: Row(
              //     children: [
              //       Icon(_isExpanded ? Icons.chevron_right : Icons.expand_more),
              //       const SizedBox(width: 8),
              //       _isExpanded
              //           ? const Text('Hide target infor')
              //           : const Text('Show target infor'),
              //     ],
              //   ),
              // ),
              PopupMenuItem<String>(
                  value: 'option3',
                  child: Row(
                    children: [
                      Icon(timeInterval.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(timeInterval.isCompleted
                            ? 'Mark as incompleted in this time interval'
                            : 'Mark as completed in this time interval'),
                      ),
                    ],
                  )),
              const PopupMenuItem<String>(
                value: 'option1',
                child: Row(
                  children: [
                    Icon(Icons.copy_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child:
                          Text('Sync details from task to this time interval'),
                    )
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'option1',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Edit details in this time interval'),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'option2',
                child: Row(
                  children: [
                    Icon(Icons.delete_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Delete this time interval'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
