import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';

import '../data/database/database_manager.dart';
import '../data/device_calendar/device_calendar_service.dart';
import '../data/models/model_task.dart';
import '../data/models/model_time_interval.dart';
import '../screen_focus_timer/data/model_focus_session.dart';
import '../screen_focus_timer/view/task_picker_sheet.dart';
import '../screen_tasks/component_widgets/bottomsheet_show_or_set_time_intervals.dart';
import '../utils/constants.dart';
import 'page_edit_device_event.dart';

/// Tải tất cả time interval, làm giàu (gán màu + tiêu đề lấy từ task liên kết)
/// rồi nạp vào [controller].
///
/// Hiệu năng: thay vì gọi 1 truy vấn DB cho MỖI interval (N+1 query — với hàng
/// trăm/nghìn interval sẽ treo màn hình), ta tải toàn bộ task một lần vào map
/// tra cứu trong RAM. Cũng KHÔNG ghi ngược DB (updateTimeInterval): việc hiển
/// thị chỉ cần gán màu/tiêu đề vào object trong bộ nhớ.
Future<void> enrichTimeIntervals(
  DatabaseManager databaseManager,
  TimeIntervalController controller,
) async {
  final timeIntervals = await databaseManager.timeIntervals();

  // Tải toàn bộ task một lần rồi dựng map id -> Task.
  final tasks = await databaseManager.tasks();
  final Map<String, Task> taskById = {for (final t in tasks) t.id: t};

  for (final ti in timeIntervals) {
    if (ti.taskId == null) continue;
    final t = taskById[ti.taskId];
    if (t == null) continue;
    // Màu luôn theo task cha. Tiêu đề: interval của công việc con giữ tiêu đề
    // riêng (của subtask); interval của chính task lấy tiêu đề task cha.
    ti.color = t.color;
    if (ti.subtaskId == null) {
      ti.title = t.title;
    }
  }

  controller.addAll(timeIntervals.toCalendarData());

  // Nạp thêm event từ lịch thiết bị (Android/iOS). Trên desktop trả rỗng.
  await loadDeviceEventsInto(controller);
}

/// Đọc event từ lịch thiết bị trong một cửa sổ rộng quanh hiện tại (±1 năm) và
/// nạp vào [controller]. An toàn: nếu không có quyền hoặc nền tảng không hỗ trợ
/// thì không làm gì. Chỉ nạp khi ĐÃ có quyền (không tự bật hộp thoại xin quyền
/// ở đây — việc xin quyền do UI chủ động gọi để tránh làm phiền lúc mở lịch).
Future<void> loadDeviceEventsInto(TimeIntervalController controller) async {
  final service = DeviceCalendarService.instance;
  if (!service.isSupported) return;
  if (!await service.hasPermissions()) return;

  final now = DateTime.now();
  final start = DateTime(now.year - 1, now.month, now.day);
  final end = DateTime(now.year + 1, now.month, now.day);
  final events = await service.retrieveEvents(start, end);
  if (events.isEmpty) return;
  controller.addAll(events.toCalendarData());
}

/// Nạp lại toàn bộ time interval: xóa hết dữ liệu cũ trong [controller] rồi
/// enrich lại từ DB. Dùng sau khi thêm/sửa interval để lịch cập nhật mà không
/// bị nhân đôi (vì [enrichTimeIntervals] chỉ addAll chứ không xóa trước).
Future<void> reloadTimeIntervals(
  DatabaseManager databaseManager,
  TimeIntervalController controller,
) async {
  controller.removeAll(controller.allEvents.toList());
  await enrichTimeIntervals(databaseManager, controller);
}

/// Luồng tạo time interval mới khi người dùng nhấn vào ô giờ trống trên lịch.
///
/// Trước tiên mở [TaskPickerSheet] (giống focus timer) để người dùng chọn công
/// việc muốn gắn — hoặc chọn "không gắn" để tạo interval độc lập. Sau đó mở
/// [ShowOrSetTimeIntervalsBottomSheet] ở chế độ tạo mới với ngày/giờ điền sẵn
/// theo [start] và task đã chọn (nếu có). Cuối cùng nạp lại lịch.
/// Luồng khi nhấn ô trống: nếu thiết bị hỗ trợ lịch (Android/iOS), hỏi người
/// dùng muốn tạo "Công việc" hay "Sự kiện lịch". Với Sự kiện -> mở trang tạo
/// event thiết bị; với Công việc (hoặc desktop) -> luồng tạo time interval.
Future<void> openCreateOnEmptySlot({
  required BuildContext context,
  required DatabaseManager databaseManager,
  required TimeIntervalController controller,
  required DateTime start,
}) async {
  final service = DeviceCalendarService.instance;
  final canUseDeviceCalendar = service.isSupported;

  if (canUseDeviceCalendar) {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Công việc'),
              subtitle: const Text('Lên lịch một khoảng thời gian cho công việc'),
              onTap: () => Navigator.pop(ctx, 'task'),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Sự kiện lịch'),
              subtitle: const Text('Tạo sự kiện trên lịch thiết bị'),
              onTap: () => Navigator.pop(ctx, 'event'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'event') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EditDeviceEventPage(
            initialStart: start,
            initialEnd: start.add(const Duration(hours: 1)),
          ),
        ),
      );
      if (changed == true && context.mounted) {
        await reloadTimeIntervals(databaseManager, controller);
      }
      return;
    }
    // choice == 'task' -> tiếp tục luồng tạo time interval bên dưới.
  }

  await openCreateTimeIntervalFlow(
    context: context,
    databaseManager: databaseManager,
    controller: controller,
    start: start,
  );
}

Future<void> openCreateTimeIntervalFlow({
  required BuildContext context,
  required DatabaseManager databaseManager,
  required TimeIntervalController controller,
  required DateTime start,
}) async {
  // Bước 1: chọn task (null = không gắn task hoặc người dùng đóng picker).
  final selected = await TaskPickerSheet.show(context);
  if (!context.mounted) return;

  // Bước 2: từ task đã chọn, lấy màu/tiêu đề/mục tiêu cho header.
  String? taskId;
  String title = '';
  Color color = ColorSeed.baseColor.color;
  String description = '';
  String location = '';
  TargetType targetType = TargetType.about;
  double targetAtLeast = double.negativeInfinity;
  double targetAtMost = double.infinity;
  String unit = '';
  List<Subtask> subtasks = const [];

  if (selected != null && selected.type == FocusTaskType.task) {
    taskId = selected.id;
    final t = await databaseManager.task(selected.id);
    title = t.title;
    color = t.color;
    description = t.description;
    location = t.location;
    subtasks = t.subtasks;
    if (t.isMeasurable) {
      targetType = t.targetType;
      targetAtLeast = t.targetAtLeast;
      targetAtMost = t.targetAtMost;
      unit = t.unit;
    }
  }
  if (!context.mounted) return;

  // Bước 3: mở bottomsheet tạo interval với prefill.
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ShowOrSetTimeIntervalsBottomSheet(
      isSetTimeIntervalPage: true,
      title: title,
      color: color,
      description: description,
      location: location,
      targetType: targetType,
      targetAtLeast: targetAtLeast,
      targetAtMost: targetAtMost,
      unit: unit,
      subtasks: subtasks,
      taskId: taskId,
      initialStart: start,
    ),
  );
  if (!context.mounted) return;

  // Bước 4: nạp lại lịch để hiển thị interval vừa tạo.
  await reloadTimeIntervals(databaseManager, controller);
}

extension ListTimeIntervalCalendarData on List<TimeInterval> {
  List<CalendarTimeIntervalData> toCalendarData() {
    return map((timeInterval) => CalendarTimeIntervalData(
          date:
              timeInterval.startDate ?? timeInterval.endDate ?? DateTime.now(),
          startTime: timeInterval.calendarStartDateTime,
          endTime: timeInterval.calendarEndDateTime,
          title: timeInterval.title,
          description: timeInterval.description,
          color: timeInterval.color,
          event: timeInterval,
        )).toList();
  }
}

extension ListDeviceEventCalendarData on List<DeviceEvent> {
  List<CalendarTimeIntervalData> toCalendarData() {
    return map((e) {
      // event trong cùng một ngày -> dùng startTime/endTime (giờ). event kéo
      // dài nhiều ngày hoặc all-day -> để full-day (startTime/endTime null) và
      // dùng endDate, vì CalendarTimeIntervalData không cho startTime span quá
      // một ngày.
      final sameDay = !e.allDay &&
          e.start.year == e.end.year &&
          e.start.month == e.end.month &&
          e.start.day == e.end.day;
      return CalendarTimeIntervalData(
        date: e.start,
        endDate: sameDay ? null : e.end,
        startTime: sameDay ? e.start : null,
        endTime: sameDay ? e.end : null,
        title: e.title,
        description: e.description,
        // Màu lịch thiết bị (nếu có) hoặc màu mặc định để phân biệt với task.
        color: e.calendarColor != null
            ? Color(e.calendarColor!)
            : const Color(0xFF3F51B5),
        event: e,
      );
    }).toList();
  }
}

