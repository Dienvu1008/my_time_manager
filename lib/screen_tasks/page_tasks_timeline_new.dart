import 'dart:collection';

import 'package:calendar_widgets/src_sticky_header/widgets/sliver_sticky_header.dart';
import 'package:calendar_widgets/src_table_calendar/customization/calendar_builders.dart';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/data/models/model_task.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/domain/services/time_interval_progress_service.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';

import '../home/component_widgets/button_brightness.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';
import '../home/component_widgets/button_material3.dart';
import '../home/component_widgets/button_use_bottom_bar.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

/// Màn Timeline theo phong cách "Schedule view" của Google Calendar:
///   - AppBar hiển thị tháng/năm + mũi tên để mở/thu gọn lịch lưới tháng.
///   - Danh sách agenda cuộn liên tục: TẤT CẢ sự kiện (quá khứ + tương lai)
///     nhóm theo ngày (chỉ ngày có sự kiện), mỗi ngày một header dính, mỗi sự
///     kiện là một dòng gọn (giờ | thanh màu | tiêu đề + địa điểm).
///   - Tự cuộn tới hôm nay khi mở; bấm một ngày trên lịch sẽ cuộn agenda tới
///     ngày đó.
class TableComplexExample extends StatefulWidget {
  final List<TimeInterval> timeIntervals;

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

  const TableComplexExample({
    super.key,
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
    required this.timeIntervals,
  });

  @override
  State<TableComplexExample> createState() => _TableComplexExampleState();
}

class _TableComplexExampleState extends State<TableComplexExample> {
  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  late final TaskListRepository _taskListRepository =
      context.read<TaskListRepository>();
  late final TimeIntervalRepository _timeIntervalRepository =
      context.read<TimeIntervalRepository>();
  late final TimeIntervalProgressService _progressService =
      context.read<TimeIntervalProgressService>();
  final ScrollController _scrollController = ScrollController();

  /// Tất cả interval, giữ trong state để cập nhật cục bộ khi sửa/xóa.
  late List<TimeInterval> _timeIntervals;

  /// Bản đồ ngày -> danh sách interval (đã sắp theo giờ). Chỉ chứa ngày có sự kiện.
  late LinkedHashMap<DateTime, List<TimeInterval>> _byDay;

  /// Danh sách ngày (có sự kiện) đã sắp tăng dần — thứ tự dựng agenda.
  late List<DateTime> _days;

  /// Key của header từng ngày — dùng để cuộn tới ngày đó.
  final Map<DateTime, GlobalKey> _dayKeys = {};

  /// Key đánh dấu sliver "center" (giữ ổn định để không nhảy khi rebuild).
  final Map<DateTime, Key> _dayCenterKeys = {};

  /// Ngày "trung tâm" mà agenda mở sẵn (ngày có sự kiện đầu tiên >= hôm nay).
  /// Tính MỘT LẦN lúc khởi tạo để tránh nhảy vị trí khi sửa/xóa sự kiện.
  DateTime? _centerDay;

  /// Tháng đang hiển thị trên AppBar (theo ngày người dùng focus / cuộn tới).
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());

  /// Có đang mở lịch lưới tháng hay không (mặc định thu gọn — giống Google).
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _timeIntervals = List<TimeInterval>.from(widget.timeIntervals);
    _rebuildIndex();
    _computeCenterDay();
  }

  /// Xác định ngày trung tâm (mở sẵn) MỘT LẦN: ngày có sự kiện đầu tiên >= hôm
  /// nay, hoặc ngày cuối cùng nếu tất cả đều ở quá khứ.
  void _computeCenterDay() {
    if (_days.isEmpty) {
      _centerDay = null;
      return;
    }
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    _centerDay = _days.firstWhere(
      (d) => !d.isBefore(todayKey),
      orElse: () => _days.last,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusedDay.dispose();
    super.dispose();
  }

  /// Chuẩn hoá về đầu ngày (bỏ giờ) để gom nhóm/tra cứu.
  DateTime _dayOf(TimeInterval ti) {
    final d = ti.startDate ?? ti.endDate ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// Dựng lại chỉ mục ngày -> sự kiện và danh sách ngày đã sắp xếp.
  void _rebuildIndex() {
    final map = <DateTime, List<TimeInterval>>{};
    for (final ti in _timeIntervals) {
      final day = _dayOf(ti);
      map.putIfAbsent(day, () => []).add(ti);
    }
    // Sắp mỗi ngày theo giờ bắt đầu (không có giờ -> lên trước).
    for (final list in map.values) {
      list.sort((a, b) {
        final am = a.startTime == null
            ? -1
            : a.startTime!.hour * 60 + a.startTime!.minute;
        final bm = b.startTime == null
            ? -1
            : b.startTime!.hour * 60 + b.startTime!.minute;
        return am.compareTo(bm);
      });
    }
    final sortedDays = map.keys.toList()..sort((a, b) => a.compareTo(b));
    _days = sortedDays;
    _byDay = LinkedHashMap<DateTime, List<TimeInterval>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll({for (final d in sortedDays) d: map[d]!});

    // Đảm bảo mỗi ngày có một key ổn định để cuộn tới.
    for (final d in sortedDays) {
      _dayKeys.putIfAbsent(d, () => GlobalKey());
    }
  }

  List<TimeInterval> _eventsForDay(DateTime day) => _byDay[day] ?? const [];

  /// Cuộn agenda tới [day] (ngày có sự kiện gần nhất >= day nếu day không có).
  void _scrollToDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    // Tìm ngày có sự kiện trùng, hoặc ngày kế tiếp gần nhất.
    DateTime? match;
    for (final d in _days) {
      if (!d.isBefore(target)) {
        match = d;
        break;
      }
    }
    match ??= _days.isNotEmpty ? _days.last : null;
    if (match == null) return;
    final key = _dayKeys[match];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
    _focusedDay.value = match;
  }

  void _scrollToToday() {
    if (!mounted || !_scrollController.hasClients) return;
    // Với CustomScrollView dùng center + anchor 0.0, offset 0 chính là đầu của
    // sliver "trung tâm" (hôm nay). Cuộn về 0 là quay lại hôm nay.
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    if (_centerDay != null) _focusedDay.value = _centerDay!;
  }

  // ------------------------------------------------------------------
  // CRUD cục bộ (cập nhật state + DB)
  // ------------------------------------------------------------------

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    await _timeIntervalRepository.deleteTimeInterval(timeInterval.id);
    setState(() {
      _timeIntervals.removeWhere((e) => e.id == timeInterval.id);
      _rebuildIndex();
    });
  }

  Future<void> _onToggleCompleted(TimeInterval timeInterval) async {
    await _progressService.toggleCompleted(timeInterval);
    _replaceLocal(
        await _timeIntervalRepository.getTimeInterval(timeInterval.id));
  }

  Future<void> _editTimeInterval(TimeInterval timeInterval) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddOrEditTimeIntervalPage(timeInterval: timeInterval),
        fullscreenDialog: false,
      ),
    );
    if (!mounted) return;
    _replaceLocal(
        await _timeIntervalRepository.getTimeInterval(timeInterval.id));
  }

  /// Mở task gốc của time interval (nếu có) để xem/sửa. Sau khi quay lại, đồng
  /// bộ lại time interval trong danh sách vì task có thể đã đổi tiêu đề/màu.
  Future<void> _goToMainTask(TimeInterval timeInterval) async {
    final taskId = timeInterval.taskId;
    if (taskId == null) return;
    final Task task = await _taskRepository.getTask(taskId);
    final TaskList? taskList = task.taskListId == null
        ? null
        : await _taskListRepository.getTaskList(task.taskListId!);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddOrEditTaskPage(taskList: taskList, task: task),
      ),
    );
    if (!mounted) return;
    _replaceLocal(
        await _timeIntervalRepository.getTimeInterval(timeInterval.id));
  }

  void _replaceLocal(TimeInterval updated) {
    final index = _timeIntervals.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      setState(() {
        _timeIntervals[index] = updated;
        _rebuildIndex();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _buildAppBar(context),
          if (_showCalendar) _buildCalendar(context),
          Expanded(child: _buildAgenda(context)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // AppBar: tháng/năm + mũi tên mở lịch + menu tuỳ chọn
  // ------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: ValueListenableBuilder<DateTime>(
        valueListenable: _focusedDay,
        builder: (context, day, _) {
          final headerText =
              DateFormat.yMMMM(Localizations.localeOf(context).languageCode)
                  .format(day);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      headerText,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_showCalendar
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Hôm nay',
          icon: const Icon(Icons.today_outlined),
          onPressed: () {
            _focusedDay.value = DateTime.now();
            _scrollToToday();
          },
        ),
        MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
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
                handleMaterialVersionChange: widget.handleMaterialVersionChange,
              ),
            UsingBottomBarMenuItemButton(
              handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
              useBottomBar: widget.useBottomBar,
            ),
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
      ],
    );
  }

  // ------------------------------------------------------------------
  // Lịch lưới tháng (mở khi nhấn mũi tên) — bấm ngày để cuộn agenda tới đó
  // ------------------------------------------------------------------

  Widget _buildCalendar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TableCalendar<TimeInterval>(
        firstDay: kFirstDay,
        lastDay: kLastDay,
        focusedDay: _focusedDay.value,
        headerVisible: true,
        daysOfWeekVisible: true,
        startingDayOfWeek: StartingDayOfWeek.monday,
        eventLoader: _eventsForDay,
        selectedDayPredicate: (day) => isSameDay(day, _focusedDay.value),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay.value = selectedDay);
          _scrollToDay(selectedDay);
        },
        onPageChanged: (focusedDay) => _focusedDay.value = focusedDay,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final e in events.take(4))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.color,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Agenda: danh sách cuộn liên tục, nhóm theo ngày, header dính
  // ------------------------------------------------------------------

  Widget _buildAgenda(BuildContext context) {
    if (_days.isEmpty) {
      return const _EmptyAgenda();
    }

    // Ngày "trung tâm" (đã tính một lần ở initState). Nếu ngày đó không còn
    // (bị xóa hết sự kiện), lấy ngày có sự kiện đầu tiên >= nó, hoặc ngày đầu.
    DateTime centerDay = _centerDay ?? _days.first;
    int centerIndex = _days.indexWhere((d) => !d.isBefore(centerDay));
    if (centerIndex == -1) centerIndex = 0;
    centerDay = _days[centerIndex];

    final before = <Widget>[]; // các ngày trước centerDay (dựng đảo ngược)
    final after = <Widget>[]; // centerDay trở đi
    for (var i = 0; i < _days.length; i++) {
      final sliver = _daySliver(_days[i]);
      if (i < centerIndex) {
        before.add(sliver);
      } else {
        after.add(sliver);
      }
    }
    // Slivers phía trước center phải được liệt kê theo thứ tự NGƯỢC lại.
    final beforeReversed = before.reversed.toList();

    final centerKey = _dayCenterKeys.putIfAbsent(centerDay, () => UniqueKey());

    return CustomScrollView(
      controller: _scrollController,
      center: centerKey,
      anchor: 0.0,
      slivers: [
        ...beforeReversed,
        // Sliver mốc center (rỗng, chỉ để đánh dấu vị trí bắt đầu).
        SliverToBoxAdapter(key: centerKey, child: const SizedBox.shrink()),
        ...after,
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Dựng một sliver (header dính + danh sách sự kiện) cho [day].
  Widget _daySliver(DateTime day) {
    return SliverStickyHeader(
      header: _DayHeader(key: _dayKeys[day], date: day),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final ti = _eventsForDay(day)[i];
            return _AgendaEventRow(
              timeInterval: ti,
              onTap: () => _editTimeInterval(ti),
              onToggleComplete: () => _onToggleCompleted(ti),
              onDelete: () => _deleteTimeInterval(ti),
              onGoToMainTask: () => _goToMainTask(ti),
            );
          },
          childCount: _eventsForDay(day).length,
        ),
      ),
    );
  }
}

/// Header dính cho một ngày trong agenda: số ngày to + thứ + tháng.
/// Hôm nay được tô màu nổi bật.
class _DayHeader extends StatelessWidget {
  const _DayHeader({Key? key, required this.date}) : super(key: key);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final accent = theme.colorScheme.primary;

    final weekday = DateFormat.EEEE(locale).format(date); // Thứ Hai...
    final monthYear = DateFormat.yMMMM(locale).format(date);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Số ngày (vòng tròn nếu là hôm nay).
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? accent : Colors.transparent,
            ),
            child: Text(
              '${date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday ? theme.colorScheme.onPrimary : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday ? accent : null,
                  ),
                ),
                Text(
                  monthYear,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng sự kiện gọn kiểu Google Calendar: giờ | thanh màu | tiêu đề + nơi.
class _AgendaEventRow extends StatelessWidget {
  const _AgendaEventRow({
    required this.timeInterval,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onGoToMainTask,
  });

  final TimeInterval timeInterval;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onGoToMainTask;

  String _timeLabel(BuildContext context) {
    final ti = timeInterval;
    final start = ti.startTime;
    final end = ti.endTime;
    if (start == null && end == null) {
      return 'Cả ngày';
    }
    String fmt(TimeOfDay? t) => t == null ? '--:--' : t.format(context);
    if (start != null && end != null) {
      return '${fmt(start)}\n${fmt(end)}';
    }
    return fmt(start ?? end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = timeInterval.isCompleted;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? theme.disabledColor : null,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cột giờ (căn bằng chiều rộng với số ngày ở header).
            SizedBox(
              width: 52,
              child: Text(
                _timeLabel(context),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: done ? theme.disabledColor : theme.hintColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Thanh màu của sự kiện.
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: done
                    ? theme.disabledColor
                    : timeInterval.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Tiêu đề + địa điểm.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (timeInterval.isImportant && !done)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.star,
                              size: 14, color: theme.colorScheme.error),
                        ),
                      Expanded(
                        child: Text(
                          timeInterval.title.isEmpty
                              ? '(Không tiêu đề)'
                              : timeInterval.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
                  if (timeInterval.location.isNotEmpty)
                    Text(
                      timeInterval.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                ],
              ),
            ),
            // Menu tùy chọn (khôi phục lại menu options đầy đủ thay cho nút
            // đánh dấu hoàn thành nhanh trước đây).
            _buildOptionsMenu(context),
          ],
        ),
      ),
    );
  }

  /// Menu ba chấm với đầy đủ tùy chọn cho một time interval, tương tự thẻ time
  /// interval ở màn Overview: đánh dấu hoàn thành, đến task gốc, sửa, xóa.
  Widget _buildOptionsMenu(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final done = timeInterval.isCompleted;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_outlined,
          size: 20, color: Theme.of(context).hintColor),
      onSelected: (String result) {
        switch (result) {
          case 'toggle_complete':
            onToggleComplete();
            break;
          case 'go_to_main_task':
            onGoToMainTask();
            break;
          case 'edit':
            onTap();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'toggle_complete',
          child: Row(
            children: [
              Icon(done ? Icons.check_box : Icons.check_box_outline_blank),
              const SizedBox(width: 8),
              Expanded(
                child: Text(done
                    ? localizations.markAsIncompletedInThisTimeInterval
                    : localizations.markAsCompletedInThisTimeInterval),
              ),
            ],
          ),
        ),
        if (timeInterval.taskId != null)
          PopupMenuItem<String>(
            value: 'go_to_main_task',
            child: Row(
              children: [
                const Icon(Icons.read_more_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(localizations.goToMainTask)),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.editThisTimeInterval)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(localizations.deleteThisTimeInterval)),
            ],
          ),
        ),
      ],
    );
  }

  void _showActions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final done = timeInterval.isCompleted;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(done ? Icons.check_box : Icons.check_box_outline_blank),
              title: Text(done
                  ? localizations.markAsIncompletedInThisTimeInterval
                  : localizations.markAsCompletedInThisTimeInterval),
              onTap: () {
                Navigator.pop(ctx);
                onToggleComplete();
              },
            ),
            if (timeInterval.taskId != null)
              ListTile(
                leading: const Icon(Icons.read_more_outlined),
                title: Text(localizations.goToMainTask),
                onTap: () {
                  Navigator.pop(ctx);
                  onGoToMainTask();
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(localizations.editThisTimeInterval),
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(localizations.deleteThisTimeInterval),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined,
              size: 64, color: theme.disabledColor),
          const SizedBox(height: 12),
          const Text('Chưa có sự kiện nào được lên lịch'),
        ],
      ),
    );
  }
}
