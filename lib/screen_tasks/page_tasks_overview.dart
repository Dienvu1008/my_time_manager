import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_calendar_event.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_calendar_event.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_list.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_task.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/app_localizations.dart';
import '../domain/models/models.dart';
import '../data/repositories/sqlite_task_list_repository.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/repositories/task_list_repository.dart';
import '../domain/repositories/calendar_repository.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/services/task_completion_service.dart';
import '../home/component_widgets/app_drawer.dart';
import '../home/component_widgets/button_brightness.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';
import '../home/component_widgets/button_material3.dart';
import '../home/component_widgets/button_select_calendar_mode.dart';
import '../home/component_widgets/button_show_timeline_calendar.dart';
import '../home/component_widgets/button_use_bottom_bar.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

/// Vị trí FAB giống [FloatingActionButtonLocation.endFloat] nhưng được nâng
/// thêm [bottomOffset] pixel để không bị thanh điều hướng dưới che mất.
class _EndFloatRaised extends FloatingActionButtonLocation {
  const _EndFloatRaised({this.bottomOffset = 0});
  final double bottomOffset;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base = FloatingActionButtonLocation.endFloat
        .getOffset(scaffoldGeometry);
    return Offset(base.dx, base.dy - bottomOffset);
  }
}

class TasksOverviewPage extends StatefulWidget {
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

  final bool isProVersion;

  const TasksOverviewPage({super.key,
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
    required this.isProVersion});

  @override
  _TasksOverviewPageState createState() => _TasksOverviewPageState();
}

class _TasksOverviewPageState extends State<TasksOverviewPage> {
  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  late final TaskListRepository _taskListRepository =
      context.read<TaskListRepository>();
  late final CalendarRepository _calendarRepository =
      context.read<CalendarRepository>();
  late final TaskCompletionService _completionService =
      context.read<TaskCompletionService>();
  late SharedPreferences _prefs;
  List<TaskList>? _taskLists;

  /// Các item "tự do" (task/calendar event không thuộc danh sách nào) hiển thị
  /// ở cấp cao nhất của màn Overview, ngang hàng với các card danh sách.
  List<dynamic> _looseItems = [];

  /// True khi speed-dial FAB đang mở.
  bool _fabOpen = false;

  /// Bộ đếm "epoch" để buộc các [TaskListCard] con dựng lại (mỗi card tự cache
  /// danh sách item con trong state của nó và chỉ nạp một lần ở initState).
  /// Khi kéo-thả một item sang danh sách khác, ta tăng token này và ghép vào
  /// key của từng card -> Flutter tạo lại state -> card nạp lại item từ DB, nên
  /// card nguồn bỏ item vừa chuyển đi và card đích hiện item mới ngay lập tức.
  int _reloadToken = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final taskLists = await _taskListRepository.getTaskLists();
    final order = _prefs.getStringList('taskListOrder');
    if (order != null) {
      taskLists
          .sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }
    final looseTasks = await _taskRepository.getTasksWithoutTaskList();
    final looseEvents =
        await _calendarRepository.getCalendarEventsWithoutTaskList();
    //if(mounted)
    setState(() {
      _taskLists = taskLists;
      _looseItems = [...looseTasks, ...looseEvents];
    });
    //_taskLists = taskLists;
  }

  /// Di chuyển một item (Task hoặc CalendarEvent) sang danh sách [newListId]
  /// (null = đưa ra cấp cao nhất). Dùng cho kéo-thả.
  Future<void> _moveItemToList(dynamic item, String? newListId) async {
    if (item is Task) {
      if (item.taskListId == newListId) return;
      await _taskRepository.moveTask(item.id, newListId);
    } else if (item is CalendarEvent) {
      if (item.taskListId == newListId) return;
      await _calendarRepository.moveCalendarEvent(item.id, newListId);
    } else {
      return;
    }
    // Buộc các card danh sách con nạp lại (xem [_reloadToken]) để card nguồn bỏ
    // item vừa chuyển và card đích hiện nó ngay, không cần rời màn rồi quay lại.
    _reloadToken++;
    await _init();
    if (mounted) {
      final where = newListId == null
          ? 'ra ngoài danh sách'
          : 'vào danh sách';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Đã chuyển $where.')));
    }
  }

  void _reorderTaskLists(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final taskList = _taskLists!.removeAt(oldIndex);
      _taskLists!.insert(newIndex, taskList);
      final order = _taskLists!.map((b) => b.id.toString()).toList();
      _prefs.setStringList('taskListOrder', order);
    });
  }

  Future<void> _onTaskListDelete(TaskList taskList) async {
    // Soft-delete: Ä‘Æ°a danh sÃ¡ch (vÃ  task con) vÃ o thÃ¹ng rÃ¡c.
    await _taskListRepository.softDeleteTaskList(taskList.id);
    // Bỏ đúng danh sách khỏi state (so khớp theo id) và rebuild ngay. Trước đây
    // gọi remove(taskList.id) — xóa một String khỏi List<TaskList> nên không
    // bao giờ khớp, khiến card vẫn hiển thị cho tới khi rời màn rồi quay lại.
    if (mounted) {
      setState(() => _taskLists?.removeWhere((l) => l.id == taskList.id));
    } else {
      _taskLists?.removeWhere((l) => l.id == taskList.id);
    }
    await _saveOrder();
  }

  /// Lưu trữ cả một danh sách (và các task con của nó): ẩn khỏi màn chính nhưng
  /// không xóa. Có thể bỏ lưu trữ lại từ màn Lưu trữ.
  Future<void> _onTaskListArchive(TaskList taskList) async {
    await _taskListRepository.archiveTaskList(taskList.id);
    // Bỏ đúng danh sách khỏi state (so khớp theo id) và rebuild ngay — xem ghi
    // chú ở _onTaskListDelete về lỗi remove(taskList.id) cũ.
    if (mounted) {
      setState(() => _taskLists?.removeWhere((l) => l.id == taskList.id));
    } else {
      _taskLists?.removeWhere((l) => l.id == taskList.id);
    }
    await _saveOrder();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('Đã lưu trữ "${taskList.title}".')));
    }
  }

  Future<void> _addTaskList(TaskList taskList) async {
    setState(() => _taskLists!.insert(0, taskList));
    await _saveOrder();
  }

  // --- Các luồng tạo từ speed-dial FAB ---

  Future<void> _createTaskList() async {
    final taskList = await showDialog<TaskList>(
      context: context,
      builder: (context) => AddOrEditTaskListPage(),
    );
    if (taskList != null) await _addTaskList(taskList);
  }

  /// Tạo task mới. taskList = null nên trang tạo hiện ô chọn danh sách (hoặc
  /// "Không thuộc danh sách nào"). Sau khi tạo, nạp lại để hiện đúng vị trí.
  Future<void> _createTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (context) => const AddOrEditTaskPage(),
    );
    if (task != null) await _init();
  }

  Future<void> _createCalendarEvent() async {
    final event = await Navigator.of(context).push<CalendarEvent>(
      MaterialPageRoute(
        builder: (_) => const AddOrEditCalendarEventPage(),
      ),
    );
    if (event != null) await _init();
  }

  Future<void> _saveOrder() async {
    final order = _taskLists!.map((taskList) => taskList.id).toList();
    await _prefs.setStringList('taskListOrder', order);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    //_init();
    if (_taskLists == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Expanded(
      child: Column(
        children: [
          AppBar(title: Text(localizations!.overview, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              actions: [
                MenuAnchor(
                  builder: (context, controller, child) {
                    return IconButton(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
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
                      handleMaterialVersionChange:
                      widget.handleMaterialVersionChange,
                    ),

                    UsingBottomBarMenuItemButton(
                        handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
                        useBottomBar: widget.useBottomBar),
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
              ]),
          Expanded(
            child: Scaffold(
              // Nâng FAB lên khỏi thanh điều hướng dưới để không che tab
              // "Timeline" và bảo đảm luôn nhấn được nút thêm danh sách.
              floatingActionButtonLocation:
                  const _EndFloatRaised(bottomOffset: 72),
              body: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  // Danh sách các list-card (có thể sắp xếp thứ tự). Mỗi card
                  // đồng thời là DragTarget nhận task/event thả vào.
                  TaskListsHolder(
                    onReorder: _reorderTaskLists,
                    taskLists: _taskLists ?? [],
                    reloadToken: _reloadToken,
                    onItemMovedToList: _moveItemToList,
                    onTaskListDelete: (value) async {
                      _onTaskListDelete(value);
                    },
                    onTaskListArchive: (value) async {
                      _onTaskListArchive(value);
                    },
                    onTaskListEdit: (TaskList taskList) async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AddOrEditTaskListPage(taskList: taskList),
                          fullscreenDialog: false,
                        ),
                      );
                      final updatedTaskLists =
                          await _taskListRepository.getTaskLists();
                      final order = _prefs.getStringList('taskListOrder');
                      if (order != null) {
                        updatedTaskLists.sort((a, b) =>
                            order.indexOf(a.id).compareTo(order.indexOf(b.id)));
                      }
                      setState(() => _taskLists = updatedTaskLists);
                    },
                    isProVersion: widget.isProVersion,
                  ),
                  // Khu vực item "tự do" (không thuộc list nào) — cũng là nơi
                  // thả để gỡ item khỏi list.
                  _buildLooseItemsSection(),
                ],
              ),
              floatingActionButton: _buildSpeedDial(),
            ),
          )
        ],
      ),
    );
  }

  /// Khu vực hiển thị các item không thuộc danh sách nào. Là một DragTarget: thả
  /// một task/event vào đây sẽ gỡ nó khỏi danh sách hiện tại.
  Widget _buildLooseItemsSection() {
    return DragTarget<_ItemDragData>(
      onWillAcceptWithDetails: (details) => details.data.item != null,
      onAcceptWithDetails: (details) =>
          _moveItemToList(details.data.item, null),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: highlight
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: highlight ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: highlight
                ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.06)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 18, color: Theme.of(context).hintColor),
                    const SizedBox(width: 8),
                    Text(
                      'Không thuộc danh sách',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              if (_looseItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    highlight
                        ? 'Thả vào đây để gỡ khỏi danh sách'
                        : 'Chưa có mục nào. Kéo một task/sự kiện ra đây để tách khỏi danh sách.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                )
              else
                ..._looseItems.map(_buildLooseItemCard),
            ],
          ),
        );
      },
    );
  }

  /// Một item tự do, bọc trong LongPressDraggable để kéo vào danh sách.
  Widget _buildLooseItemCard(dynamic item) {
    final Widget card;
    if (item is Task) {
      card = TaskCard(
        key: ValueKey(item),
        task: item,
        onTaskEdit: (t) async {
          final tl = t.taskListId == null
              ? null
              : await _taskListRepository.getTaskList(t.taskListId!);
          if (!mounted) return;
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddOrEditTaskPage(task: t, taskList: tl),
          ));
          await _init();
        },
        onTaskDelete: (t) async {
          await _taskRepository.softDeleteTask(t.id);
          await _init();
        },
        onTaskArchive: (t) async {
          await _taskRepository.archiveTask(t.id);
          await _init();
        },
        onTaskToggleComplete: (t) async {
          await _completionService.toggleCompleted(t);
          await _init();
        },
        isProVersion: widget.isProVersion,
      );
    } else if (item is CalendarEvent) {
      card = CalendarEventCard(
        key: ValueKey(item),
        event: item,
        onEdit: (e) async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddOrEditCalendarEventPage(event: e),
          ));
          await _init();
        },
        onDelete: (e) async {
          await _calendarRepository.softDeleteCalendarEvent(e.id);
          await _init();
        },
        onArchive: (e) async {
          await _calendarRepository.archiveCalendarEvent(e.id);
          await _init();
        },
      );
    } else {
      return const SizedBox.shrink();
    }

    return LongPressDraggable<_ItemDragData>(
      data: _ItemDragData(item),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 48,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  /// Speed-dial FAB: nút chính bật/tắt 3 nút tạo (danh sách / task / sự kiện).
  Widget _buildSpeedDial() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_fabOpen) ...[
          _MiniFab(
            heroTag: 'fab_list',
            icon: Icons.playlist_add_outlined,
            label: 'Danh sách',
            onTap: () async {
              setState(() => _fabOpen = false);
              await _createTaskList();
            },
          ),
          const SizedBox(height: 10),
          _MiniFab(
            heroTag: 'fab_task',
            icon: Icons.check_circle_outline,
            label: 'Công việc',
            onTap: () async {
              setState(() => _fabOpen = false);
              await _createTask();
            },
          ),
          const SizedBox(height: 10),
          _MiniFab(
            heroTag: 'fab_event',
            icon: Icons.event_outlined,
            label: 'Sự kiện',
            onTap: () async {
              setState(() => _fabOpen = false);
              await _createCalendarEvent();
            },
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Dữ liệu kéo-thả cho một item (task/calendar event) ở màn Overview.
class _ItemDragData {
  const _ItemDragData(this.item);
  final dynamic item;
}

/// Nút nhỏ kèm nhãn dùng trong speed-dial FAB.
class _MiniFab extends StatelessWidget {
  const _MiniFab({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String heroTag;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: heroTag,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class TaskListsHolder extends StatefulWidget {
  const TaskListsHolder({
    Key? key,
    required this.onTaskListDelete,
    this.onTaskListArchive,
    required this.onTaskListEdit,
    required this.onReorder,
    required this.taskLists,
    required this.isProVersion,
    this.reloadToken = 0,
    this.onItemMovedToList,
  }) : super(key: key);

  final Function(TaskList) onTaskListDelete;
  final Function(TaskList)? onTaskListArchive;
  final Function(TaskList) onTaskListEdit;
  final Function(int, int) onReorder;
  final List<TaskList> taskLists;
  final bool isProVersion;

  /// Tăng mỗi khi cần buộc các card danh sách con nạp lại item (xem
  /// [_TasksOverviewPageState._reloadToken]). Ghép vào key của từng card.
  final int reloadToken;

  /// Được gọi khi kéo-thả một item (Task/CalendarEvent) vào một danh sách.
  final Future<void> Function(dynamic item, String? newListId)?
      onItemMovedToList;

  @override
  _TaskListsHolderState createState() => _TaskListsHolderState();
}

class _TaskListsHolderState extends State<TaskListsHolder> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: widget.onReorder,
      children: List.generate(widget.taskLists.length, (index) {
        final taskList = widget.taskLists[index];
        return TaskListCard(
          // Ghép reloadToken vào key: khi có kéo-thả item giữa các danh sách,
          // token đổi -> key đổi -> Flutter dựng lại state của card -> card nạp
          // lại item con từ DB (card nguồn bỏ item, card đích thêm item).
          key: ValueKey('${taskList.id}_${widget.reloadToken}'),
          taskList: taskList,
          onItemMovedToList: widget.onItemMovedToList,
          onTaskListDelete: (TaskList taskList) async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete this list'),
                content: Text(
                    'Are you sure you want to delete this list and all its tasks and events?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              ),
            );

            if (shouldDelete ?? false) {
              widget.onTaskListDelete(taskList);
              setState(() => widget.taskLists.remove(taskList));
            }
          },
          onTaskListEdit: widget.onTaskListEdit,
          onTaskListArchive: widget.onTaskListArchive == null
              ? null
              : (TaskList taskList) async {
                  widget.onTaskListArchive!(taskList);
                  setState(() => widget.taskLists.remove(taskList));
                },
          isProVersion: widget.isProVersion,
        );
      }),
    );
  }
}

class TaskListCard extends StatefulWidget {
  const TaskListCard({
    Key? key,
    required this.taskList,
    required this.onTaskListEdit,
    required this.onTaskListDelete,
    this.onTaskListArchive,
    required this.isProVersion,
    this.onItemMovedToList,
  }) : super(key: key);

  final TaskList taskList;
  final Function(TaskList) onTaskListEdit;
  final Function(TaskList) onTaskListDelete;
  final Function(TaskList)? onTaskListArchive;
  final bool isProVersion;

  /// Kéo-thả một item vào danh sách này.
  final Future<void> Function(dynamic item, String? newListId)?
      onItemMovedToList;

  @override
  _TaskListCardState createState() => _TaskListCardState();
}

class _TaskListCardState extends State<TaskListCard> {
  late final TaskRepository _taskRepository = context.read<TaskRepository>();
  late final CalendarRepository _calendarRepository =
      context.read<CalendarRepository>();
  late final EventRepository _eventRepository = context.read<EventRepository>();
  late final TaskCompletionService _completionService =
      context.read<TaskCompletionService>();
  late SharedPreferences _prefs;
  bool _isExpanded = false;
  // Khá»Ÿi táº¡o rá»—ng Ä‘á»ƒ build Ä‘áº§u tiÃªn (trÆ°á»›c khi _init náº¡p xong báº¥t Ä‘á»“ng bá»™)
  // khÃ´ng gáº·p LateInitializationError. Danh sÃ¡ch tháº­t Ä‘Æ°á»£c gÃ¡n trong _init().
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final tasks = await _taskRepository.getTasksOfTaskList(widget.taskList.id);
    final events = await _eventRepository.getEventsOfTaskList(widget.taskList.id);
    final calendarEvents =
        await _calendarRepository.getCalendarEventsOfTaskList(widget.taskList.id);
    final List<dynamic> items = [
      ...tasks,
      ...events,
      ...calendarEvents,
    ];

    final order = _prefs.getStringList('itemsOrder');
    if (order != null) {
      items.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    }

    if (mounted) {
      setState(() => {
            _items = items,
            _isExpanded =
                _prefs.getBool('${widget.taskList.id}_isExpanded') ?? false,
          });
    }
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      final order = _items.map((b) => b.id.toString()).toList();
      _prefs.setStringList('itemsOrder', order);
    });
  }

  Future<void> _onTaskToggleCompleted(Task task) async {
    final Task _task = task.copyWith(
      isCompleted: !task.isCompleted,
    );
    final index = _items.indexWhere((item) => item.id == _task.id);
    if (index != -1) {
      setState(() {
        _items[index] = _task;
      });
    }

    // Business rule (toggle completion + persist) lives in the domain service.
    await _completionService.toggleCompleted(task);
  }

  Future<void> _onHasBeenDoneUpdate(Task task) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: task.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.hasBeenDone),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              final double amount = double.parse(_hasBeenDoneController.text);
              final Task _task =
                  task.copyWith(howMuchHasBeenDone: amount);
              final index =
                  _items.indexWhere((item) => item.id == _task.id);
              if (index != -1) {
                setState(() {
                  _items[index] = _task;
                });
              }
              // Business rule (measurable progress + persist) in domain service.
              await _completionService.updateMeasurableProgress(task, amount);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubtasksChanged(Task task) async {
    final index = _items.indexWhere((item) => item.id == task.id);
    if (index != -1) {
      setState(() {
        _items[index] = task;
      });
    }

    await _taskRepository.updateTask(task);
  }

  Future<void> _onTaskDelete(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final localizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(localizations!.deleteTask),
          content: Text(localizations.areYouSureYouWantToDeleteThisTask),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations.delete),
            ),
          ],
        );
      },
    );
    if (result == true) {
      setState(() {
        _items.remove(task);
      });
      await _saveOrder();
      // Soft-delete: Ä‘Æ°a vÃ o thÃ¹ng rÃ¡c thay vÃ¬ xÃ³a vÄ©nh viá»…n.
      await _taskRepository.softDeleteTask(task.id);
    }
  }

  /// Lưu trữ một task: ẩn khỏi màn chính (không xóa). Người dùng có thể bỏ lưu
  /// trữ lại từ màn Lưu trữ.
  Future<void> _onTaskArchive(Task task) async {
    setState(() {
      _items.remove(task);
    });
    await _saveOrder();
    await _taskRepository.archiveTask(task.id);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Đã lưu trữ "${task.title}".')));
    }
  }

  // --- Handlers cho CalendarEvent ---

  Future<void> _onCalendarEventEdit(CalendarEvent event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddOrEditCalendarEventPage(
          event: event,
          taskList: widget.taskList,
        ),
      ),
    );
    final updated = await _calendarRepository.getCalendarEvent(event.id);
    final index = _items.indexWhere((item) => item.id == event.id);
    if (index != -1 && updated != null && mounted) {
      setState(() => _items[index] = updated);
    }
  }

  Future<void> _onCalendarEventDelete(CalendarEvent event) async {
    // Soft-delete: đưa vào thùng rác thay vì xóa vĩnh viễn.
    await _calendarRepository.softDeleteCalendarEvent(event.id);
    await _saveOrder();
  }

  Future<void> _onCalendarEventArchive(CalendarEvent event) async {
    await _calendarRepository.archiveCalendarEvent(event.id);
    await _saveOrder();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text('Đã lưu trữ "${event.title}".')));
    }
  }

  Future<void> _addCalendarEvent(CalendarEvent event) async {
    setState(() => _items.insert(0, event));
    await _saveOrder();
    _init();
  }

  Future<void> _addTask(Task task) async {
    setState(() => _items.insert(0, task));
    await _saveOrder();
    _init();
  }

  Future<void> _saveOrder() async {
    final order = _items.map((item) => item.id as String).toList();
    await _prefs.setStringList('itemsOrder', order);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context)
        .textTheme
        .apply(displayColor: Theme.of(context).colorScheme.onSurface);
    // Bọc card trong DragTarget để có thể thả task/event vào danh sách này.
    return DragTarget<_ItemDragData>(
      onWillAcceptWithDetails: (details) =>
          widget.onItemMovedToList != null && details.data.item != null,
      onAcceptWithDetails: (details) =>
          widget.onItemMovedToList?.call(details.data.item, widget.taskList.id),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Card(
          shape: highlight
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(children: [
              Row(
            children: [
              IconButton(
                icon:
                    Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right),
                onPressed: () => setState(() {
                  _isExpanded = !_isExpanded;
                  _prefs.setBool(
                      '${widget.taskList.id}_isExpanded', _isExpanded);
                }),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTaskListEdit(widget.taskList),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.taskList.title, style: textTheme.titleMedium),
                      const SizedBox(height: 4.0),
                      if (_isExpanded && widget.taskList.description.isNotEmpty)
                        Text(widget.taskList.description),
                    ],
                  ),
                ),
              ),
              TaskListCardOptions(
                taskList: widget.taskList,
                onTaskListDelete: () =>
                    widget.onTaskListDelete(widget.taskList),
                onTaskListArchive: widget.onTaskListArchive == null
                    ? null
                    : () => widget.onTaskListArchive!(widget.taskList),
                onTaskListEdit: () => widget.onTaskListEdit(widget.taskList),
                addTask: (value) => _addTask(value),
                addCalendarEvent: (value) => _addCalendarEvent(value),
              ),
            ],
          ),

    //     ListTile(
    //       contentPadding: const EdgeInsets.only(right:0, left: 0),
    //     leading: IconButton(
    //     icon: Icon(_isExpanded ? Icons.expand_more : Icons.chevron_right),
    //     onPressed: () => setState(() {
    //       _isExpanded = !_isExpanded;
    //       _prefs.setBool('${widget.taskList.id}_isExpanded', _isExpanded);
    //     }),
    //   ),
    //   title: GestureDetector(
    //     onTap: () => widget.onTaskListEdit(widget.taskList),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Text(widget.taskList.title, style: textTheme.titleMedium),
    //         const SizedBox(height: 4.0),
    //         if (_isExpanded && widget.taskList.description.isNotEmpty)
    //           Text(widget.taskList.description),
    //       ],
    //     ),
    //   ),
    //   trailing: TaskListCardOptions(
    //     taskList: widget.taskList,
    //     onTaskListDelete: () => widget.onTaskListDelete(widget.taskList),
    //     onTaskListEdit: () => widget.onTaskListEdit(widget.taskList),
    //     addTask: (value) => _addTask(value),
    //     addMeasurableTask: (value) => _addMeasurableTask(value),
    //     addTaskWithSubtasks: (value) => _addTaskWithSubtasks(value),
    //   ),
    // ),

    if (_isExpanded)
            ItemsHolder(
              onReorder: _reorderItems,
              items: _items,
              onTaskEdit: (Task task) async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddOrEditTaskPage(
                      task: task,
                      taskList: widget.taskList,
                    ),
                    fullscreenDialog: false,
                  ),
                );
                final updatedTask = await _taskRepository.getTask(task.id);
                final index =
                    _items.indexWhere((item) => item.id == updatedTask.id);
                if (index != -1) {
                  setState(() {
                    _items[index] = updatedTask;
                  });
                }
              },
              onTaskToggleComplete: _onTaskToggleCompleted,
              onTaskDelete: _onTaskDelete,
              onTaskArchive: _onTaskArchive,
              onHasBeenDoneUpdate: _onHasBeenDoneUpdate,
              onSubtasksChanged: _onSubtasksChanged,
              onCalendarEventEdit: _onCalendarEventEdit,
              onCalendarEventDelete: _onCalendarEventDelete,
              onCalendarEventArchive: _onCalendarEventArchive,
              isProVersion: widget.isProVersion,
            ),
            ]),
          ),
        );
      },
    );
  }
}

class TaskListCardOptions extends StatelessWidget {
  const TaskListCardOptions(
      {super.key,
      required this.onTaskListEdit,
      required this.onTaskListDelete,
      this.onTaskListArchive,
      required this.taskList,
      required this.addTask,
      this.addCalendarEvent});

  final Function() onTaskListEdit;
  final Function() onTaskListDelete;
  final Function()? onTaskListArchive;
  final Function(Task) addTask;
  final Function(CalendarEvent)? addCalendarEvent;
  final TaskList taskList;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert_outlined),
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: () async {
                final task = await showDialog<Task>(
                  context: context,
                  builder: (context) => AddOrEditTaskPage(
                    taskList: taskList,
                  ),
                );
                if (task != null) {
                  await addTask(task);
                }
              },
              child: Text(localizations!.addANewTask),
            ),
            MenuItemButton(
              onPressed: () async {
                final event = await Navigator.of(context).push<CalendarEvent>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddOrEditCalendarEventPage(taskList: taskList),
                  ),
                );
                if (event != null) {
                  addCalendarEvent?.call(event);
                }
              },
              child: Text(localizations.addANewEvent),
            ),
          ],
          child: Row(
            children: [
              const Icon(Icons.add_outlined),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.addToThisList)
            ],
          ),
        ),
        MenuItemButton(
          onPressed: onTaskListEdit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.editThisList)
            ],
          ),
        ),
        if (onTaskListArchive != null)
          MenuItemButton(
            onPressed: onTaskListArchive,
            child: Row(
              children: [
                const Icon(Icons.archive_outlined),
                const SizedBox(
                  width: 5,
                ),
                Text(localizations.archive)
              ],
            ),
          ),
        MenuItemButton(
          onPressed: onTaskListDelete,
          child: Row(
            children: [
              const Icon(Icons.delete_outline),
              const SizedBox(
                width: 5,
              ),
              Text(localizations.deleteThisList)
            ],
          ),
        ),
      ],
    );
  }
}

class ItemsHolder extends StatefulWidget {
  const ItemsHolder({
    Key? key,
    required this.items,
    required this.onReorder,
    required this.onTaskEdit,
    required this.onTaskDelete,
    required this.onTaskArchive,
    required this.onTaskToggleComplete,
    required this.onHasBeenDoneUpdate,
    required this.onSubtasksChanged,
    required this.onCalendarEventEdit,
    required this.onCalendarEventDelete,
    required this.onCalendarEventArchive,
    required this.isProVersion,
  }) : super(key: key);

  final Function(Task) onTaskEdit;
  final Function(Task) onTaskDelete;
  final Function(Task) onTaskArchive;
  final Function(Task) onTaskToggleComplete;
  final Function(Task) onHasBeenDoneUpdate;
  final Function(Task) onSubtasksChanged;
  final Function(CalendarEvent) onCalendarEventEdit;
  final Function(CalendarEvent) onCalendarEventDelete;
  final Function(CalendarEvent) onCalendarEventArchive;
  final List<dynamic> items;
  final Function(int, int) onReorder;
  final bool isProVersion;

  @override
  _ItemsHolderState createState() => _ItemsHolderState();
}

class _ItemsHolderState extends State<ItemsHolder> {
  /// Bọc một card item trong LongPressDraggable để kéo sang danh sách khác.
  Widget _draggable(dynamic item, Widget card) {
    return LongPressDraggable<_ItemDragData>(
      key: ValueKey(item),
      data: _ItemDragData(item),
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 64,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Column các card (mỗi card là nguồn kéo). Bỏ ReorderableListView vì xung
    // đột cử chỉ long-press với kéo-thả giữa các danh sách; thứ tự trong list
    // không còn tự sắp (kéo-thả liên-list là tính năng ưu tiên).
    return Column(
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        if (item is Task) {
          final card = TaskCard(
            task: item,
            onTaskDelete: (Task task) async {
              widget.onTaskDelete(task);
              widget.items.remove(task);
            },
            onTaskArchive: (Task task) async {
              widget.onTaskArchive(task);
              widget.items.remove(task);
            },
            onTaskEdit: (Task task) async {
              widget.onTaskEdit(task);
            },
            onTaskToggleComplete: (Task task) async {
              widget.onTaskToggleComplete(task);
            },
            onHasBeenDoneUpdate: widget.onHasBeenDoneUpdate,
            onSubtasksChanged: widget.onSubtasksChanged,
            isProVersion: widget.isProVersion,
          );
          return _draggable(item, card);
        } else if (item is CalendarEvent) {
          final card = CalendarEventCard(
            event: item,
            onEdit: (CalendarEvent e) async {
              widget.onCalendarEventEdit(e);
            },
            onDelete: (CalendarEvent e) async {
              widget.onCalendarEventDelete(e);
              widget.items.remove(e);
            },
            onArchive: (CalendarEvent e) async {
              widget.onCalendarEventArchive(e);
              widget.items.remove(e);
            },
          );
          return _draggable(item, card);
        } else {
          return SizedBox(key: ValueKey(item));
        }
      }),
    );
  }
}

class BlocTasksOverviewPage extends StatelessWidget {
  const BlocTasksOverviewPage({Key? key, required this.isProVersion}) : super(key: key);
  final bool isProVersion;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListsHolderBloc(
        taskListRepository: context.read<TaskListRepository>(),
      ),
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
                  context.read<TaskListsHolderBloc>().add(ReorderTaskListsEvent(
                      oldIndex: oldIndex, newIndex: newIndex));
                },
                taskLists: state.taskLists,
                // onTaskListDelete: (value) async {
                //   context
                //       .read<TaskListsHolderBloc>()
                //       .add(DeleteTaskListEvent(id: value.id));
                // },
                onTaskListDelete: (value) async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete this list'),
                      content: Text(
                          'Are you sure you want to delete this list and all its tasks and events?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete ?? false) {
                    context
                        .read<TaskListsHolderBloc>()
                        .add(DeleteTaskListEvent(id: value.id));
                  } else {}
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
                isProVersion: isProVersion,
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
                      context
                          .read<TaskListsHolderBloc>()
                          .add(AddTaskListEvent(taskList: taskList));
                      context
                          .read<TaskListsHolderBloc>()
                          .add(LoadTaskListsEvent());
                    }
                  },
                  heroTag: 'addTaskList',
                  child: const Icon(Icons.add),
                ),
                // const SizedBox(
                //   width: 10.0,
                //   height: 20.0,
                // ),
                // FloatingActionButton(
                //   onPressed: () async {
                //     await DatabaseManager().deleteDatabase();
                //     context.read<TaskListsHolderBloc>().add(LoadTaskListsEvent());
                //   },
                //   child: const Icon(Icons.delete),
                // ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderBloc
class TaskListsHolderBloc
    extends Bloc<TaskListsHolderEvent, TaskListsHolderState> {
  // Depends on the domain repository, not DatabaseManager. Injected so the app
  // provides the shared instance and tests can provide a fake.
  final TaskListRepository _taskListRepository;
  late SharedPreferences _prefs;

  TaskListsHolderBloc({TaskListRepository? taskListRepository})
      : _taskListRepository =
            taskListRepository ?? SqliteTaskListRepository(),
        super(TaskListsHolderState(taskLists: [], isLoading: true)) {
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
    final taskLists = await _taskListRepository.getTaskLists();
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
    // Soft-delete: Ä‘Æ°a danh sÃ¡ch (vÃ  task con) vÃ o thÃ¹ng rÃ¡c.
    await _taskListRepository.softDeleteTaskList(event.id);
    final taskLists = state.taskLists..removeWhere((b) => b.id == event.id);
    await _saveOrder(taskLists);
    emit(state.copyWith(taskLists: taskLists));
  }

//   Future<void> _onDeleteTaskListEvent(
//   DeleteTaskListEvent event,
//   Emitter<TaskListsHolderState> emit,
//   Future<bool> Function() confirmDelete,
// ) async {
//   final shouldDelete = await confirmDelete();
//   if (shouldDelete) {
//     await _databaseManager.deleteTaskList(event.id);
//     final taskLists = state.taskLists..removeWhere((b) => b.id == event.id);
//     await _saveOrder(taskLists);
//     emit(state.copyWith(taskLists: taskLists));
//   }
// }

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

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderEvent
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

///////////////////////////////////////////////////////////////////////////////////////////////
/// TaskListsHolderState
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
