import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';

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
                      Expanded(
                        child: TimeIntervalOfTaskOrEventPage(
                          taskId: widget.taskId,
                          measurableTaskId: widget.measurableTaskId,
                          taskWithSubtasksId: widget.taskWithSubtasksId, 
                          selectedTimeIntervals: 'today',
                    
                        ),
                      ),
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
                    ],
                  );
                },
              ),
            ),
          );
        });
  }
}

