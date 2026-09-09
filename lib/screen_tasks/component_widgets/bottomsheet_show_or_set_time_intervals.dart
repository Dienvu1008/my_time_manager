import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/home/data_controller_provider.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_alarm.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_repeat.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/repeat_rule.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_set_time_intervals_block.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_timezone.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_time_interval_of_task_or_event.dart';
import 'package:my_time_manager/utils/constants.dart';

import '../../home/component_widgets/button_show_timeline_calendar.dart';
import '../../utils/utils.dart';

class ShowOrSetTimeIntervalsBottomSheet extends StatefulWidget {
  const ShowOrSetTimeIntervalsBottomSheet(
      {super.key,
      this.taskId,
      this.subtaskId,
      required this.isSetTimeIntervalPage,
      required this.title,
      required this.color,
      required this.description,
      required this.location,
      required this.targetType,
      required this.targetAtLeast,
      required this.targetAtMost,
      required this.subtasks,
      required this.unit,
      this.initialStart,
      this.initialEnd});

  final String? taskId;
  final String? subtaskId;
  final bool isSetTimeIntervalPage;
  final String title;
  final Color color;
  final String description;
  final String location;
  final TargetType targetType;
  final double targetAtLeast;
  final double targetAtMost;
  final String unit;
  final List<Subtask> subtasks;

  /// Ngày/giờ bắt đầu điền sẵn khi mở trực tiếp vào trang tạo mới (ví dụ khi
  /// người dùng nhấn vào một ô trống trên lịch).
  final DateTime? initialStart;

  /// Ngày/giờ kết thúc điền sẵn. Nếu null, mặc định là [initialStart] + 1 giờ.
  final DateTime? initialEnd;

  @override
  _ShowOrSetTimeIntervalsBottomSheetState createState() =>
      _ShowOrSetTimeIntervalsBottomSheetState();
}

class _ShowOrSetTimeIntervalsBottomSheetState
    extends State<ShowOrSetTimeIntervalsBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSetTimeIntervalPage = false;
  // ValueNotifier<String> _selectedTimeIntervalsNotifier =
  //     ValueNotifier<String>('all');

  final GlobalKey<_SetTimeIntervalPageState> key = GlobalKey();
  final DatabaseManager _databaseManager = DatabaseManager();
  bool _isExpanded = false;
  bool _showCalendar = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    _isSetTimeIntervalPage = widget.isSetTimeIntervalPage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color labelColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final myColorScheme = Theme.of(context).brightness == Brightness.dark
        ? ColorScheme.dark(primary: widget.color)
        : ColorScheme.light(primary: widget.color);
    final backgroundColor = myColorScheme.primaryContainer;
    final titleTextColor = contrastColor(backgroundColor);
    return SafeArea( child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FractionallySizedBox(
            heightFactor: _animation.value,
            child: DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                maxChildSize: 1,
                minChildSize: 0.6,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Scaffold(
                    body: Column(
                      children: <Widget>[
                        Container(
                          color: widget.color,
                          child: GestureDetector(
                            child: ListTile(
                              title: Center(child: Text(
                                widget.title,
                                style: TextStyle(color: titleTextColor),
                              ),),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: widget.color,
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text(
                                              widget.title,
                                              style: TextStyle(
                                                  color: titleTextColor),
                                            ),
                                          ),
                                          if (widget.description.isNotEmpty)
                                            ListTile(
                                              dense: true,
                                              leading: Icon(
                                                  Icons.description_outlined,
                                                  color: titleTextColor),
                                              title: Text(
                                                widget.description,
                                                style: TextStyle(
                                                    color: titleTextColor),
                                              ),
                                            ),
                                          if (widget.location.isNotEmpty)
                                            ListTile(
                                              dense: true,
                                              leading: Icon(
                                                  Icons.location_on_outlined,
                                                  color: titleTextColor),
                                              title: Text(
                                                widget.location,
                                                style: TextStyle(
                                                    color: titleTextColor),
                                              ),
                                            ),
                                          if (widget.unit.isNotEmpty)
                                            ListTile(
                                              dense: true,
                                              title: Column(
                                                children: [
                                                  if (widget.targetType ==
                                                      TargetType.about)
                                                    Text(
                                                      'Target: about ${widget.targetAtLeast} to ${widget.targetAtMost} ${widget.unit}',
                                                      style: TextStyle(
                                                          color:
                                                              titleTextColor),
                                                    ),
                                                  if (widget.targetType ==
                                                      TargetType.atLeast)
                                                    Text(
                                                      'Target: at least ${widget.targetAtLeast} ${widget.unit}',
                                                      style: TextStyle(
                                                          color:
                                                              titleTextColor),
                                                    ),
                                                  if (widget.targetType ==
                                                      TargetType.atMost)
                                                    Text(
                                                      'Target: at most ${widget.targetAtMost} ${widget.unit}',
                                                      style: TextStyle(
                                                          color:
                                                              titleTextColor),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          if (widget.subtasks.isNotEmpty)
                                            ...widget.subtasks.map(
                                              (subtask) => ListTile(
                                                  dense: true,
                                                  leading: Icon(
                                                      subtask.isCompleted
                                                          ? Icons.check_box
                                                          : Icons
                                                              .check_box_outline_blank,
                                                      color: titleTextColor),
                                                  title: Text(
                                                    subtask.title,
                                                    style: TextStyle(
                                                        color: titleTextColor),
                                                  )),
                                            )
                                        ],
                                      ),
                                      //),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _isSetTimeIntervalPage
                              ? SetTimeIntervalPage(
                                  key: key,
                                  taskId: widget.taskId,
                                  subtaskId: widget.subtaskId,
                                  initialStart: widget.initialStart,
                                  initialEnd: widget.initialEnd,
                                )
                              : FutureBuilder(
                                  future: widget.subtaskId != null
                                      ? _databaseManager
                                          .timeIntervalsOfSubtask(
                                              widget.subtaskId!)
                                      : widget.taskId != null
                                          ? _databaseManager
                                              .timeIntervalsOfTask(
                                                  widget.taskId!)
                                          : null,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      List<TimeInterval> timeIntervals =
                                          snapshot.data ?? [];
                                      return TimeIntervalOfTaskOrEventPageNew(
                                        taskId: widget.taskId,
                                        subtaskId: widget.subtaskId,
                                        showCalendar: _showCalendar,
                                        timeIntervalsOfThisTask: timeIntervals,
                                      );
                                    }
                                  }),
                        )
                      ],
                    ),
                    floatingActionButton: Column(
                      children: [
                        const Spacer(),
                        if (!_isSetTimeIntervalPage)
                          FloatingActionButton.small(
                              onPressed: () {
                                setState(() {
                                  _isSetTimeIntervalPage = true;
                                });
                              },
                              child: const Icon(Icons.add)),
                        if (_isSetTimeIntervalPage)
                          FloatingActionButton.small(
                              onPressed: () {
                                key.currentState!._onSave();
                              },
                              child: const Icon(Icons.save_outlined)),
                        if (_isSetTimeIntervalPage) const SizedBox(height: 10),
                        if (_isSetTimeIntervalPage)
                          FloatingActionButton.small(
                              onPressed: () {
                                setState(() {
                                  _isSetTimeIntervalPage = false;
                                });
                              },
                              child: const Icon(Icons.calendar_month_outlined)),
                        if (!_isSetTimeIntervalPage) const SizedBox(height: 10),
                        if (!_isSetTimeIntervalPage)
                          FloatingActionButton.small(
                            onPressed: () {},
                            child: MenuAnchor(
                              builder: (context, controller, child) {
                                return IconButton(
                                  onPressed: () {
                                    if (controller.isOpen) {
                                      controller.close();
                                    } else {
                                      controller.open();
                                    }
                                  },
                                  icon: const Icon(Icons.visibility_outlined),
                                );
                              },
                              menuChildren: [
                                ShowHideCalendarMenuItemButton(
                                  handleCalendarVisibilityChange: () =>
                                      setState(() {
                                    _showCalendar = !_showCalendar;
                                  }),
                                  showCalendar: _showCalendar,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }));
  }
}

class SetTimeIntervalPage extends StatefulWidget {
  const SetTimeIntervalPage({
    super.key,
    this.taskId,
    this.subtaskId,
    this.initialStart,
    this.initialEnd,
  });

  final String? taskId;
  final String? subtaskId;

  /// Ngày/giờ bắt đầu điền sẵn (dùng khi mở từ việc nhấn ô trống trên lịch).
  final DateTime? initialStart;

  /// Ngày/giờ kết thúc điền sẵn. Nếu null sẽ mặc định là [initialStart] + 1 giờ.
  final DateTime? initialEnd;

  @override
  _SetTimeIntervalPageState createState() => _SetTimeIntervalPageState();
}

class _SetTimeIntervalPageState extends State<SetTimeIntervalPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  final _formKey = GlobalKey<FormState>();
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();
  TextEditingController _startTimeController = TextEditingController();
  TextEditingController _endTimeController = TextEditingController();
  // Quy tắc lặp hiện tại (mặc định không lặp), cập nhật qua RepeatListTile.
  RepeatRule _repeatRule = RepeatRule.none;
  // Các mốc nhắc (số phút trước), cập nhật qua AlarmListTile.
  List<int> _reminderMinutes = [];
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _title = '';
  String _description = '';
  String _location = '';

  Color _color = ColorSeed.baseColor.color;
  bool _isCompleted = false;
  bool _isImportant = false;
  List<Subtask>? _subtasks = [];
  TargetType? _targetType = TargetType.about;
  double? _targetAtLeast = double.negativeInfinity;
  double? _targetAtMost = double.infinity;
  double? _howMuchHasBeenDone = 0.0;
  String? _unit = '';

  Future<void> _init() async {
    if (widget.taskId == null) return;
    final Task task = await _databaseManager.task(widget.taskId!);
    if (widget.subtaskId != null) {
      // Lập kế hoạch cho MỘT công việc con: tiêu đề/mục tiêu lấy từ subtask,
      // còn mô tả/vị trí/màu/quan trọng lấy từ task cha.
      final Subtask st = task.subtasks.firstWhere(
        (s) => s.id == widget.subtaskId,
        orElse: () => Subtask(title: task.title),
      );
      _title = st.title;
      _color = task.color;
      _isImportant = task.isImportant;
      _description = task.description;
      _location = task.location;
      if (st.isMeasurable) {
        _targetType = st.targetType;
        _targetAtLeast = st.targetAtLeast;
        _targetAtMost = st.targetAtMost;
        _unit = st.unit;
      }
      // Một subtask không có sub-subtask.
      _subtasks = [];
    } else {
      // Lập kế hoạch cho chính task.
      _title = task.title;
      _color = task.color;
      _isImportant = task.isImportant;
      _description = task.description;
      _location = task.location;
      if (task.isMeasurable) {
        _targetType = task.targetType;
        _targetAtLeast = task.targetAtLeast;
        _targetAtMost = task.targetAtMost;
        _unit = task.unit;
      }
      _subtasks = task.subtasks
          .map((subtask) => Subtask(
                title: subtask.title,
                isCompleted: false,
                isMeasurable: subtask.isMeasurable,
                targetType: subtask.targetType,
                targetAtLeast: subtask.targetAtLeast,
                targetAtMost: subtask.targetAtMost,
                unit: subtask.unit,
                howMuchHasBeenDone: subtask.howMuchHasBeenDone,
              ))
          .toList();
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      if ((_isStartDateUndefined &&
              _isEndDateUndefined &&
              _isStartTimeUndefined &&
              _isEndTimeUndefined) ||
          (_startDateController.text.isEmpty &&
              _endDateController.text.isEmpty) ||
          (_startDateController.text == 'undefined' &&
              _endDateController.text == 'undefined')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(AppLocalizations.of(context)!.enterAtLeastOneDate),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        if (_isStartDateUndefined) {
          _isStartTimeUndefined = true;
          _startDate = null;
          _startTime = null;
        } else {
          if (_startDateController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text('Please enter start date'),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          } else {
            _startDate = !_isStartDateUndefined
                ? (() {
                    try {
                      if (_startDateController.text == 'undefined') {
                        return null;
                      } else if (_startDateController.text == 'undefined') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text('Please enter start date'),
                            actions: [
                              TextButton(
                                child: Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      } else {
                        return DateFormat('EEE, dd MMM, yyyy',
                                Localizations.localeOf(context).languageCode)
                            .parse(_startDateController.text);
                      }
                    } catch (_) {
                      // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                      return null;
                    }
                  })()
                : null;

            if (_isStartTimeUndefined) {
              _startTime = null;
            } else {
              if (_startTimeController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text('Please enter start time'),
                    actions: [
                      TextButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // _startTime = TimeOfDay.fromDateTime(
                //     DateFormat('HH:mm').parse(_startTimeController.text));
                _startTime = !_isStartTimeUndefined
                    ? (() {
                        try {
                          if (_startTimeController.text == 'undefined') {
                            return null;
                          } else {
                            return TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                .parse(_startTimeController.text));
                          }
                        } catch (_) {
                          // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                          return null;
                        }
                      })()
                    : null;
              }
            }
          }
        }

        if (_isEndDateUndefined) {
          _isEndTimeUndefined = true;
          _endDate = null;
          _endTime = null;
        } else {
          if (_endDateController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text('Please enter end date'),
                actions: [
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          } else {
            // _endDate = DateFormat('EEE, dd MMM, yyyy',
            //         Localizations.localeOf(context).languageCode)
            //     .parse(_endDateController.text);
            _endDate = !_isEndDateUndefined
                ? (() {
                    try {
                      if (_endDateController.text == 'undefined') {
                        return null;
                      } else {
                        return DateFormat('EEE, dd MMM, yyyy',
                                Localizations.localeOf(context).languageCode)
                            .parse(_endDateController.text);
                      }
                    } catch (_) {
                      // Chuỗi ngày không hợp lệ hoặc không thể phân tích được, trả về null
                      return null;
                    }
                  })()
                : null;
            if (_isEndTimeUndefined) {
              _endTime = null;
            } else {
              if (_endTimeController.text.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text('Please enter end time'),
                    actions: [
                      TextButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // _endTime = TimeOfDay.fromDateTime
                //     DateFormat('HH:mm').parse(_endTimeController.text));
                _endTime = !_isEndTimeUndefined
                    ? (() {
                        try {
                          if (_endTimeController.text == 'undefined') {
                            return null;
                          } else {
                            return TimeOfDay.fromDateTime(DateFormat('HH:mm')
                                .parse(_endTimeController.text));
                          }
                        } catch (_) {
                          // Chuỗi thời gian không hợp lệ hoặc không thể phân tích được, trả về null
                          return null;
                        }
                      })()
                    : null;
              }
            }
          }
        }

        final timeInterval = TimeInterval(
          taskId: widget.taskId,
          subtaskId: widget.subtaskId,
          color: _color,
          title: _title,
          isCompleted: _isCompleted,
          isImportant: _isImportant,
          description: _description,
          location: _location,
          subtasks: _subtasks,
          targetType: _targetType,
          unit: _unit,
          targetAtLeast: _targetAtLeast,
          targetAtMost: _targetAtMost,
          howMuchHasBeenDone: _howMuchHasBeenDone,
          startDate: _startDate,
          endDate: _endDate,
          startTime: _startTime,
          endTime: _endTime,
          isStartDateUndefined: _isStartDateUndefined,
          isEndDateUndefined: _isEndDateUndefined,
          isStartTimeUndefined: _isStartTimeUndefined,
          isEndTimeUndefined: _isEndTimeUndefined,
          reminderMinutesBefore: _reminderMinutes,
        );
        if ((timeInterval.startTimestamp != null &&
                timeInterval.endTimestamp != null &&
                timeInterval.startTimestamp! > timeInterval.endTimestamp!) ||
            (timeInterval.startDate != null &&
                timeInterval.endDate != null &&
                timeInterval.startDate!.isAfter(timeInterval.endDate!)) ||
            (timeInterval.startDate != null &&
                timeInterval.endDate != null &&
                timeInterval.startDate!
                    .isAtSameMomentAs(timeInterval.endDate!) &&
                timeInterval.startTime != null &&
                timeInterval.endTime != null &&
                (timeInterval.startTime!.hour * 60 +
                        timeInterval.startTime!.minute) >
                    (timeInterval.endTime!.hour * 60 +
                        timeInterval.endTime!.minute))) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Lỗi'),
                content: Text(
                    'Thời gian bắt đầu không được phép xảy ra sau thời gian kết thúc.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Đóng'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          //DataControllerProvider.of(context).controller.add(timeInterval);
          // Sinh (và lưu) các time interval theo quy tắc lặp. Nếu không lặp
          // hoặc không có ngày bắt đầu, chỉ lưu đúng một interval.
          // Ước lượng tổng số interval sẽ tạo (để quyết định hiển thị progress).
          final plannedCount =
              (_repeatRule.isRepeating && timeInterval.startDate != null)
                  ? _repeatRule.generateStartDates(timeInterval.startDate!).length
                  : 1;

          // Với nhiều interval: hiện hộp thoại tiến trình trong lúc lưu.
          final progress = ValueNotifier<int>(0);
          final showProgress = plannedCount > 1;
          if (showProgress) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => _SaveProgressDialog(
                total: plannedCount,
                progress: progress,
              ),
            );
          }

          final createdCount = await _saveWithRepeat(
            timeInterval,
            _repeatRule,
            onProgress: (done, _) => progress.value = done,
          );

          // Việc lưu là bất đồng bộ; widget có thể đã bị unmount trong lúc chờ.
          if (!mounted) {
            progress.dispose();
            return;
          }

          // Đóng hộp thoại tiến trình (nếu có).
          if (showProgress) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          progress.dispose();

          setState(() {
            _startDateController.clear();
            _startTimeController.clear();
            _endDateController.clear();
            _endTimeController.clear();
            _isStartDateUndefined = false;
            _isEndDateUndefined = false;
            _isStartTimeUndefined = false;
            _isEndTimeUndefined = false;
          });

          // Thông báo thành công rõ ràng.
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 40),
              title: const Text('Đã lưu'),
              content: Text(createdCount > 1
                  ? 'Đã lên lịch thành công $createdCount khoảng thời gian lặp lại.'
                  : 'Đã lên lịch thành công khoảng thời gian.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  /// Lưu [base] cùng tất cả các bản lặp theo [rule]. Trả về số interval đã tạo.
  ///
  /// Mỗi occurrence là một TimeInterval độc lập (id riêng), chỉ khác ở ngày:
  /// startDate được dịch tới ngày lặp, còn endDate giữ nguyên khoảng cách so với
  /// startDate gốc (để độ dài mỗi lần lặp không đổi). Giờ (startTime/endTime)
  /// được giữ nguyên.
  /// [onProgress] được gọi sau mỗi lần lưu với (số đã lưu, tổng số) để cập nhật
  /// thanh tiến trình.
  Future<int> _saveWithRepeat(
    TimeInterval base,
    RepeatRule rule, {
    void Function(int done, int total)? onProgress,
  }) async {
    // Không lặp, hoặc không có ngày bắt đầu để làm mốc -> lưu đúng 1 interval.
    if (!rule.isRepeating || base.startDate == null) {
      await _databaseManager.insertTimeInterval(base);
      onProgress?.call(1, 1);
      return 1;
    }

    final startDates = rule.generateStartDates(base.startDate!);
    final total = startDates.length;

    // Khoảng cách ngày giữa endDate và startDate gốc (giữ nguyên cho mỗi bản).
    Duration? endOffset;
    if (base.endDate != null) {
      final s = DateTime(base.startDate!.year, base.startDate!.month,
          base.startDate!.day);
      final e =
          DateTime(base.endDate!.year, base.endDate!.month, base.endDate!.day);
      endOffset = e.difference(s);
    }

    var count = 0;
    for (final date in startDates) {
      // Ghép ngày lặp với giờ bắt đầu gốc.
      final newStart = DateTime(
        date.year,
        date.month,
        date.day,
        base.startTime?.hour ?? 0,
        base.startTime?.minute ?? 0,
      );
      final newEnd = endOffset != null
          ? DateTime(date.year, date.month, date.day).add(endOffset)
          : base.endDate;

      final occurrence = base.copyWith(
        startDate: DateTime(newStart.year, newStart.month, newStart.day),
        endDate: newEnd,
      );
      // Cấp id mới cho mỗi bản để không ghi đè lẫn nhau (id là field non-final).
      occurrence.id = const Uuid().v4();

      await _databaseManager.insertTimeInterval(occurrence);
      count++;
      onProgress?.call(count, total);
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    String languageCode = Localizations.localeOf(context).languageCode;
    // Ngày/giờ bắt đầu: ưu tiên giá trị điền sẵn (khi mở từ ô trống trên lịch),
    // nếu không thì mặc định là thời điểm hiện tại.
    final start = widget.initialStart ?? DateTime.now();
    // Ngày/giờ kết thúc: ưu tiên initialEnd, nếu không thì lấy +1 giờ so với start.
    final end = widget.initialEnd ??
        DateTime(start.year, start.month, start.day, start.hour + 1,
            start.minute);
    _startDateController = TextEditingController(
      text: DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(start),
    );
    _endDateController = TextEditingController(
      text: DateFormat(
              'EEE, dd MMM, yyyy', Localizations.localeOf(context).languageCode)
          .format(end),
    );
    _startTimeController = TextEditingController(
      text: TimeOfDay.fromDateTime(start).format(context),
    );
    _endTimeController = TextEditingController(
      text: TimeOfDay.fromDateTime(end).format(context),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SetTimeIntervalBlockListTile(
                startDateController: _startDateController,
                isStartDateUndefined: _isStartDateUndefined,
                endDateController: _endDateController,
                isEndDateUndefined: _isEndDateUndefined,
                startTimeController: _startTimeController,
                endTimeController: _endTimeController,
                isStartTimeUndefined: _isStartTimeUndefined,
                isEndTimeUndefined: _isEndTimeUndefined,
                languageCode: languageCode,
                formKey: _formKey),
            RepeatListTile(
              onChanged: (rule) => _repeatRule = rule,
            ),
            AlarmListTile(
              initial: _reminderMinutes,
              onChanged: (minutes) => _reminderMinutes = minutes,
            ),
            TimezoneListTile(),
          ],
        ),
      ),
    );
  }
}

class TimeIntervalOfTaskOrEventPage extends StatefulWidget {
  const TimeIntervalOfTaskOrEventPage(
      {super.key,
      this.taskId,
      this.subtaskId,
      required this.selectedTimeIntervals});

  final String? taskId;
  final String? subtaskId;
  final String selectedTimeIntervals;

  @override
  _TimeIntervalOfTaskOrEventPageState createState() =>
      _TimeIntervalOfTaskOrEventPageState();
}

class _TimeIntervalOfTaskOrEventPageState
    extends State<TimeIntervalOfTaskOrEventPage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];
  List<TimeInterval> _timeIntervalsGone = [];
  List<TimeInterval> _timeIntervalsToday = [];
  List<TimeInterval> _timeIntervalsThisWeek = [];
  List<TimeInterval> _timeIntervalsThisMonth = [];
  List<TimeInterval> _timeIntervalsNextMonth = [];
  List<TimeInterval> _timeIntervalsAll = [];
  Task? _task;
  Subtask? _subtask;
  //bool _isExpanded = false;
  final Map<String, bool> _isExpanded = {};

  String _formattedStartDate = '--/--/----';
  String _formattedStartTime = '--:--';
  String _formattedEndDate = '--/--/----';
  String _formattedEndTime = '--:--';
  String _selectedTimeIntervals = 'today';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if the data has changed.
    for (var timeInterval in _timeIntervals) {
      if (_task == null) continue;
      // Mô tả/vị trí luôn lấy từ task cha.
      if (timeInterval.description != _task!.description) {
        timeInterval.isDescriptionChanged = true;
      }
      if (timeInterval.location != _task!.location) {
        timeInterval.isLocationChanged = true;
      }
      if (_subtask != null) {
        // So sánh mục tiêu với subtask.
        if ((timeInterval.targetType != _subtask!.targetType) ||
            (timeInterval.targetAtLeast != _subtask!.targetAtLeast) ||
            (timeInterval.targetAtMost != _subtask!.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
      } else {
        // So sánh mục tiêu với task.
        if ((timeInterval.targetType != _task!.targetType) ||
            (timeInterval.targetAtLeast != _task!.targetAtLeast) ||
            (timeInterval.targetAtMost != _task!.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
        // So sánh danh sách công việc con.
        List<String> timeIntervalSubtasksTitles =
            timeInterval.subtasks.map((subtask) => subtask.title).toList();
        timeIntervalSubtasksTitles.sort();

        List<String> taskSubtasksTitles =
            _task!.subtasks.map((subtask) => subtask.title).toList();
        taskSubtasksTitles.sort();

        if (!listEquals(timeIntervalSubtasksTitles, taskSubtasksTitles)) {
          timeInterval.isSubtasksChanged = true;
        }
      }
    }
  }

  Future<void> _init() async {
    if (widget.taskId == null) return;
    final task = await _databaseManager.task(widget.taskId!);
    _task = task;

    // Nếu là subtask, tìm subtask trong task cha để so sánh mục tiêu.
    Subtask? subtask;
    if (widget.subtaskId != null) {
      for (final s in task.subtasks) {
        if (s.id == widget.subtaskId) {
          subtask = s;
          break;
        }
      }
      _subtask = subtask;
    }

    final timeIntervals = widget.subtaskId != null
        ? await _databaseManager.timeIntervalsOfSubtask(widget.subtaskId!)
        : await _databaseManager.timeIntervalsOfTask(widget.taskId!);

    for (var timeInterval in timeIntervals) {
      // Mô tả/vị trí luôn lấy từ task cha.
      if (timeInterval.description != task.description) {
        timeInterval.isDescriptionChanged = true;
      }
      if (timeInterval.location != task.location) {
        timeInterval.isLocationChanged = true;
      }
      if (subtask != null) {
        if ((timeInterval.targetType != subtask.targetType) ||
            (timeInterval.targetAtLeast != subtask.targetAtLeast) ||
            (timeInterval.targetAtMost != subtask.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
      } else {
        if ((timeInterval.targetType != task.targetType) ||
            (timeInterval.targetAtLeast != task.targetAtLeast) ||
            (timeInterval.targetAtMost != task.targetAtMost)) {
          timeInterval.isTargetChanged = true;
        }
        List<String> timeIntervalSubtasksTitles =
            timeInterval.subtasks.map((s) => s.title).toList();
        timeIntervalSubtasksTitles.sort();

        List<String> taskSubtasksTitles =
            task.subtasks.map((s) => s.title).toList();
        taskSubtasksTitles.sort();

        if (!listEquals(timeIntervalSubtasksTitles, taskSubtasksTitles)) {
          timeInterval.isSubtasksChanged = true;
        }
      }
    }

    for (var timeInterval in timeIntervals) {
      _isExpanded[timeInterval.id] = false;
    }

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
    setState(() {
      _timeIntervalsAll = timeIntervals;
      _timeIntervalsToday = timeIntervals
          .where((timeInterval) => timeInterval.isToday ?? false)
          .toList();
      _timeIntervalsGone = timeIntervals
          .where((timeInterval) => timeInterval.isGone ?? false)
          .toList();
      _timeIntervalsThisWeek = timeIntervals
          .where((timeInterval) => timeInterval.isThisWeek ?? false)
          .toList();
      _timeIntervalsThisMonth = timeIntervals
          .where((timeInterval) => timeInterval.isThisMonth ?? false)
          .toList();
      _timeIntervalsNextMonth = timeIntervals
          .where((timeInterval) => timeInterval.isNextMonth ?? false)
          .toList();
    });
  }

  Future<void> _onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval =
        timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    final index =
        _timeIntervals.indexWhere((item) => item.id == _timeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = _timeInterval;
      });
    }
    await _databaseManager.updateTimeInterval(_timeInterval);
  }

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    setState(() => _timeIntervals.remove(timeInterval));
    await _databaseManager.deleteTimeInterval(timeInterval.id);
  }

  Future<void> _onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(
      subtasks: timeInterval.subtasks,
    );
    final index =
        _timeIntervals.indexWhere((item) => item.id == _timeInterval.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = _timeInterval;
      });
    }
    await _databaseManager.updateTimeInterval(_timeInterval);
  }

  Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: timeInterval.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Has been done:'),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              TimeInterval _timeInterval = timeInterval.copyWith(
                  howMuchHasBeenDone:
                      double.parse(_hasBeenDoneController.text));
              final index = _timeIntervals
                  .indexWhere((item) => item.id == _timeInterval.id);
              if (index != -1) {
                setState(() {
                  _timeIntervals[index] = _timeInterval;
                });
              }
              await _databaseManager.updateTimeInterval(_timeInterval);
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _selectedTimeIntervals = widget.selectedTimeIntervals;
    if (_selectedTimeIntervals == 'all') {
      _timeIntervals = _timeIntervalsAll;
    } else if (_selectedTimeIntervals == 'today') {
      _timeIntervals = _timeIntervalsToday;
    } else if (_selectedTimeIntervals == 'gone') {
      _timeIntervals = _timeIntervalsGone;
    } else if (_selectedTimeIntervals == 'this week') {
      _timeIntervals = _timeIntervalsThisWeek;
    } else if (_selectedTimeIntervals == 'this month') {
      _timeIntervals = _timeIntervalsThisMonth;
    } else if (_selectedTimeIntervals == 'next month') {
      _timeIntervals = _timeIntervalsNextMonth;
    }

    return _timeIntervals.isEmpty
        ? _selectedTimeIntervals == 'all'
            ? const Text('This task has not been scheduled yet')
            : _selectedTimeIntervals == 'today'
                ? const Text('This task has not been scheduled today')
                : _selectedTimeIntervals == 'this week'
                    ? const Text('This task has not been scheduled this week')
                    : _selectedTimeIntervals == 'this month'
                        ? const Text(
                            'This task has not been scheduled this month')
                        : _selectedTimeIntervals == 'next month'
                            ? const Text(
                                'This task has not been scheduled next month')
                            : _selectedTimeIntervals == 'gone'
                                ? const Text(
                                    'This task has not been scheduled in the past')
                                : Container()
        : SingleChildScrollView(
            child: Column(children: [
            Card(
              child: TableCalendar<TimeInterval>(
                firstDay: kFirstDay,
                lastDay: kLastDay,
                focusedDay: DateTime.now(),
                // headerVisible: false,
                // selectedDayPredicate: (day) => _selectedDays.contains(day),
                // rangeStartDay: _rangeStart,
                // rangeEndDay: _rangeEnd,
                // calendarFormat: _calendarFormat,
                // rangeSelectionMode: _rangeSelectionMode,
                // eventLoader: _getTimeIntervalsForDay,
                // daysOfWeekVisible: true,
                // startingDayOfWeek: StartingDayOfWeek.monday,
                // onDaySelected: _onDaySelected,
                // onRangeSelected: _onRangeSelected,
                // onCalendarCreated: (controller) => _pageController = controller,
                // //onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
                // onPageChanged: (focusedDay) => _focusedDayNew = focusedDay,
                // onFormatChanged: (format) {
                //   if (_calendarFormat != format) {
                //     setState(() => _calendarFormat = format);
                //   }
                // },
                // calendarBuilders: calendarBuilders,

                // headerVisible: false,
                // selectedDayPredicate: widget.selectedDayPredicate,
                // rangeStartDay: widget.rangeStart,
                // rangeEndDay: widget.rangeEnd,
                // calendarFormat: widget.calendarFormat,
                // rangeSelectionMode: widget.rangeSelectionMode,
                // eventLoader: widget.getTimeIntervalsForDay,
                // daysOfWeekVisible: true,
                // startingDayOfWeek: StartingDayOfWeek.monday,
                // onDaySelected: widget.onDaySelected,
                // onRangeSelected: widget.onRangeSelected,
                // onCalendarCreated: widget.onCalendarCreated,
                // onPageChanged: widget.onPageChanged,
                // onFormatChanged: widget.onFormatChanged,
                //calendarBuilders: widget.calendarBuilders,
              ),
            ),
            ListView.builder(
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

                return Column(
                  children: [
                    ListTile(
                      //contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8.0, // khoảng cách giữa các Chip
                            children: <Widget>[
                              // if (timeInterval.isGone == true)
                              //   Container(
                              //     decoration: BoxDecoration(
                              //       color: Colors.red,
                              //       borderRadius: BorderRadius.circular(
                              //           5), // bo tròn viền tại đây
                              //     ),
                              //     child: const Text(
                              //       'gone',
                              //       style: TextStyle(
                              //           color: Colors.white, fontSize: 10),
                              //     ),
                              //   ),
                              if (timeInterval.isInProgress == true)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(
                                        5), // bo tròn viền tại đây
                                  ),
                                  child: const Text(
                                    'in progress',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              // if (timeInterval.isToday == true)
                              //   Container(
                              //     decoration: BoxDecoration(
                              //       color: Colors.red,
                              //       borderRadius: BorderRadius.circular(
                              //           5), // bo tròn viền tại đây
                              //     ),
                              //     child: const Text(
                              //       'today',
                              //       style: TextStyle(
                              //           color: Colors.white, fontSize: 10),
                              //     ),
                              //   ),
                            ],
                          ),
                          RichText(
                            text: TextSpan(
                              style: timeInterval.isCompleted
                                  ? textTheme.titleSmall!.copyWith(
                                      decoration: TextDecoration.lineThrough)
                                  : textTheme.titleSmall,
                              text: _formattedStartDate == _formattedEndDate
                                  ? 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndTime'
                                  : 'From $_formattedStartDate: $_formattedStartTime to $_formattedEndDate: $_formattedEndTime',
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                        ),
                        onSelected: (String result) {
                          if (result == 'mark_completed') {
                            _onTimeIntervalToggleCompleted(timeInterval);
                          } else if (result == 'sync_details') {
                          } else if (result == 'edit') {
                            Future<void> editTimeInterval() async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddOrEditTimeIntervalPage(
                                    timeInterval: timeInterval,
                                  ),
                                  fullscreenDialog: false,
                                ),
                              );
                              final updatedTimeInterval = await _databaseManager
                                  .timeInterval(timeInterval.id);
                              final index = _timeIntervals.indexWhere(
                                  (item) => item.id == updatedTimeInterval.id);
                              if (index != -1) {
                                setState(() {
                                  _timeIntervals[index] = updatedTimeInterval;
                                });
                              }
                            }

                            // Call the async function
                            editTimeInterval();
                          } else if (result == 'delete') {
                            _deleteTimeInterval(timeInterval);
                          } else if (result == 'expand') {
                            setState(() {
                              _isExpanded[timeInterval.id] =
                                  !_isExpanded[timeInterval.id]!;
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'expand',
                            child: Row(
                              children: [
                                Icon(_isExpanded[timeInterval.id]!
                                    ? Icons.chevron_right
                                    : Icons.expand_more),
                                const SizedBox(width: 8),
                                _isExpanded[timeInterval.id]!
                                    ? const Text('Hide details')
                                    : const Text('Show details'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                              value: 'mark_completed',
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
                            value: 'sync_details',
                            child: Row(
                              children: [
                                Icon(Icons.copy_outlined),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Sync details from task to this time interval'),
                                )
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Edit details in this time interval'),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
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
                    ),
                    if (_isExpanded[timeInterval.id]! &&
                        timeInterval.description.isNotEmpty)
                      ListTile(
                          dense: true,
                          leading: Icon(Icons.description_outlined),
                          title: Text(timeInterval.description)),
                    if (_isExpanded[timeInterval.id]! &&
                        timeInterval.location.isNotEmpty)
                      ListTile(
                          dense: true,
                          leading: Icon(Icons.location_on_outlined),
                          title: Text(timeInterval.location)),
                    if (timeInterval.unit.isNotEmpty &&
                        _isExpanded[timeInterval.id]!)
                      ListTile(
                        dense: true,
                        title: Column(
                          children: [
                            if (timeInterval.targetType == TargetType.about)
                              Text(
                                'Target: about ${timeInterval.targetAtLeast} to ${timeInterval.targetAtMost} ${timeInterval.unit}',
                                //style: TextStyle(color: labelColor),
                              ),
                            if (timeInterval.targetType == TargetType.atLeast)
                              Text(
                                'Target: at least ${timeInterval.targetAtLeast} ${timeInterval.unit}',
                                //style: TextStyle(color: labelColor),
                              ),
                            if (timeInterval.targetType == TargetType.atMost)
                              Text(
                                'Target: at most ${timeInterval.targetAtMost} ${timeInterval.unit}',
                                //style: TextStyle(color: labelColor),
                              ),
                          ],
                        ),
                      ),
                    if (timeInterval.unit.isNotEmpty &&
                        _isExpanded[timeInterval.id]!)
                      ListTile(
                        dense: true,
                        title: ActionChip(
                            label: Text(
                              'Has been done: ${timeInterval.howMuchHasBeenDone} ${timeInterval.unit}',
                            ),
                            onPressed: () =>
                                _onHasBeenDoneUpdate(timeInterval)),
                      ),
                    if (timeInterval.subtasks.isNotEmpty &&
                            _isExpanded[timeInterval.id]!
                        //timeInterval.isSubtasksChanged
                        )
                      ...timeInterval.subtasks.reversed.map(
                        (subtask) => CheckboxListTile(
                          //contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                          dense: true,
                          side: BorderSide(
                              //color: labelColor,
                              ),
                          //activeColor: labelColor,
                          activeColor: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.black
                              : Colors.white, // Màu nền khi Checkbox được chọn
                          checkColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: subtask.isCompleted,
                          onChanged: (value) {
                            subtask.isCompleted = value ?? false;
                            _onSubtasksChanged(timeInterval);
                          },
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              //color: labelColor,
                            ),
                          ),
                          secondary: IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              //color: labelColor,
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
                                timeInterval.subtasks.remove(subtask);
                                _onSubtasksChanged(timeInterval);
                              }
                            },
                          ),
                        ),
                      ),
                    const Divider(
                      height: 4,
                    ),
                  ],
                );
              },
            )
          ]));
  }
}


/// Hộp thoại hiển thị tiến trình khi lưu nhiều time interval lặp lại cùng lúc.
///
/// Lắng nghe [progress] (số interval đã lưu) và cập nhật thanh tiến trình cùng
/// nhãn "X/total". Không cho đóng bằng cách chạm ra ngoài (barrierDismissible
/// được đặt false ở nơi gọi).
class _SaveProgressDialog extends StatelessWidget {
  const _SaveProgressDialog({
    required this.total,
    required this.progress,
  });

  final int total;
  final ValueListenable<int> progress;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đang lưu...'),
      content: ValueListenableBuilder<int>(
        valueListenable: progress,
        builder: (context, done, _) {
          final fraction = total == 0 ? 0.0 : done / total;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Đang lưu $done/$total khoảng thời gian'),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
