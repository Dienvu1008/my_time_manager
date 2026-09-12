import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/data/models/model_list.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_location.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_title.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:uuid/uuid.dart';

/// Trang thêm/sửa một [CalendarEvent] trong một danh sách (giống trang thêm/sửa
/// task). Hỗ trợ các trường phổ biến của Google Calendar để có thể đồng bộ:
/// tiêu đề, thời gian bắt đầu/kết thúc, cả ngày, địa điểm, mô tả, màu, lặp lại
/// cơ bản, và một mốc nhắc.
///
/// Sự kiện mới có [EventSyncStatus.localOnly]; khi sửa một sự kiện đã đồng bộ,
/// trạng thái chuyển sang [EventSyncStatus.pendingUpdate] để lần đồng bộ sau
/// đẩy thay đổi lên máy chủ.
class AddOrEditCalendarEventPage extends StatefulWidget {
  const AddOrEditCalendarEventPage({
    super.key,
    this.event,
    this.taskList,
    this.initialStart,
    this.initialEnd,
  });

  /// Danh sách chứa sự kiện. Null = sự kiện "tự do" (không thuộc danh sách nào).
  final TaskList? taskList;
  final CalendarEvent? event;

  /// Giờ bắt đầu điền sẵn khi TẠO MỚI (ví dụ khi nhấn vào ô giờ trống trên
  /// lịch). Bỏ qua khi đang sửa một sự kiện có sẵn.
  final DateTime? initialStart;

  /// Giờ kết thúc điền sẵn khi tạo mới. Nếu null mà có [initialStart] thì mặc
  /// định là [initialStart] + 1 giờ.
  final DateTime? initialEnd;

  @override
  State<AddOrEditCalendarEventPage> createState() =>
      _AddOrEditCalendarEventPageState();
}

/// Các mẫu lặp lại đơn giản, ánh xạ sang RRULE (RFC 5545).
enum _RecurrencePreset {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case _RecurrencePreset.none:
        return 'Không lặp';
      case _RecurrencePreset.daily:
        return 'Hằng ngày';
      case _RecurrencePreset.weekly:
        return 'Hằng tuần';
      case _RecurrencePreset.monthly:
        return 'Hằng tháng';
      case _RecurrencePreset.yearly:
        return 'Hằng năm';
    }
  }

  /// Chuỗi RRULE tương ứng (rỗng nếu không lặp).
  List<String> get rrule {
    switch (this) {
      case _RecurrencePreset.none:
        return const [];
      case _RecurrencePreset.daily:
        return const ['RRULE:FREQ=DAILY'];
      case _RecurrencePreset.weekly:
        return const ['RRULE:FREQ=WEEKLY'];
      case _RecurrencePreset.monthly:
        return const ['RRULE:FREQ=MONTHLY'];
      case _RecurrencePreset.yearly:
        return const ['RRULE:FREQ=YEARLY'];
    }
  }

  /// Suy ra preset từ danh sách recurrence hiện có (chỉ nhận dạng mẫu đơn giản).
  static _RecurrencePreset fromRecurrence(List<String> recurrence) {
    final rrule =
        recurrence.firstWhere((r) => r.startsWith('RRULE:'), orElse: () => '');
    if (rrule.contains('FREQ=DAILY')) return _RecurrencePreset.daily;
    if (rrule.contains('FREQ=WEEKLY')) return _RecurrencePreset.weekly;
    if (rrule.contains('FREQ=MONTHLY')) return _RecurrencePreset.monthly;
    if (rrule.contains('FREQ=YEARLY')) return _RecurrencePreset.yearly;
    return _RecurrencePreset.none;
  }
}

class _AddOrEditCalendarEventPageState
    extends State<AddOrEditCalendarEventPage> {
  late final CalendarRepository _calendarRepository =
      context.read<CalendarRepository>();
  late final TaskListRepository _taskListRepository =
      context.read<TaskListRepository>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _id = '';
  Color _color = ColorSeed.baseColor.color;
  bool _isAllDay = false;
  late DateTime _start;
  late DateTime _end;
  _RecurrencePreset _recurrence = _RecurrencePreset.none;

  /// Số phút nhắc trước; null = dùng mặc định của lịch.
  int? _reminderMinutes = 10;

  /// Danh sách được chọn (null = không thuộc danh sách nào).
  String? _selectedTaskListId;
  List<TaskList> _availableLists = [];

  bool get _isEditing => widget.event != null;

  Future<void> _loadLists() async {
    final lists = await _taskListRepository.getTaskLists();
    if (mounted) setState(() => _availableLists = lists);
  }

  static const List<int> _reminderOptions = [0, 5, 10, 15, 30, 60, 120, 1440];

  @override
  void initState() {
    super.initState();
    _selectedTaskListId = widget.event?.taskListId ?? widget.taskList?.id;
    _loadLists();
    final e = widget.event;
    if (e != null) {
      _id = e.id;
      _titleController.text = e.title;
      _locationController.text = e.location;
      _descriptionController.text = e.description;
      _color = e.color;
      _isAllDay = e.isAllDay;
      _start = e.start.effective;
      _end = e.end.effective;
      _recurrence = _RecurrencePreset.fromRecurrence(e.recurrence);
      if (e.reminders.useDefault) {
        _reminderMinutes = null;
      } else if (e.reminders.overrides.isNotEmpty) {
        _reminderMinutes = e.reminders.overrides.first.minutes;
      } else {
        _reminderMinutes = null;
      }
    } else {
      _id = const Uuid().v4();
      final initialStart = widget.initialStart;
      if (initialStart != null) {
        // Tạo từ ô giờ trống trên lịch -> dùng giờ đã nhấn.
        _start = initialStart;
        _end = widget.initialEnd ?? initialStart.add(const Duration(hours: 1));
      } else {
        final now = DateTime.now();
        // Làm tròn tới giờ kế tiếp cho gọn.
        _start = DateTime(now.year, now.month, now.day, now.hour + 1);
        _end = _start.add(const Duration(hours: 1));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.notification),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final newDt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        base.hour,
        base.minute,
      );
      if (isStart) {
        _shiftStart(newDt);
      } else {
        _end = newDt;
        _ensureOrder();
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      final newDt = DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _shiftStart(newDt);
      } else {
        _end = newDt;
        _ensureOrder();
      }
    });
  }

  /// Dời start; giữ nguyên khoảng cách start→end nếu end đang sau start.
  void _shiftStart(DateTime newStart) {
    final duration = _end.difference(_start);
    _start = newStart;
    if (duration > Duration.zero) {
      _end = _start.add(duration);
    } else {
      _ensureOrder();
    }
  }

  void _ensureOrder() {
    if (_end.isBefore(_start)) {
      _end = _start.add(const Duration(hours: 1));
    }
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Vui lòng nhập tiêu đề sự kiện');
      return;
    }
    if (_end.isBefore(_start)) {
      _showError('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }

    final EventDateTime start;
    final EventDateTime end;
    if (_isAllDay) {
      start = EventDateTime(date: DateTime(_start.year, _start.month, _start.day));
      // Theo iCal, end cả ngày là exclusive (ngày sau ngày cuối).
      final endDay = DateTime(_end.year, _end.month, _end.day)
          .add(const Duration(days: 1));
      end = EventDateTime(date: endDay);
    } else {
      start = EventDateTime(dateTime: _start);
      end = EventDateTime(dateTime: _end);
    }

    final reminders = _reminderMinutes == null
        ? const EventReminders(useDefault: true)
        : EventReminders(
            useDefault: false,
            overrides: [
              EventReminderOverride(
                method: ReminderMethod.popup,
                minutes: _reminderMinutes!,
              ),
            ],
          );

    final existing = widget.event;
    // Sự kiện mới -> localOnly. Sửa sự kiện đã đồng bộ -> pendingUpdate để lần
    // sync sau đẩy lên; nếu vốn localOnly thì giữ localOnly.
    final EventSyncStatus syncStatus;
    if (existing == null) {
      syncStatus = EventSyncStatus.localOnly;
    } else if (existing.syncStatus == EventSyncStatus.localOnly) {
      syncStatus = EventSyncStatus.localOnly;
    } else {
      syncStatus = EventSyncStatus.pendingUpdate;
    }

    final event = CalendarEvent(
      id: _id,
      taskListId: _selectedTaskListId,
      title: title,
      description: _descriptionController.text,
      location: _locationController.text,
      color: _color,
      start: start,
      end: end,
      recurrence: _recurrence.rrule,
      reminders: reminders,
      // Giữ lại các trường đồng bộ khi sửa.
      googleEventId: existing?.googleEventId,
      calendarId: existing?.calendarId,
      iCalUID: existing?.iCalUID,
      etag: existing?.etag,
      sequence: existing?.sequence ?? 0,
      created: existing?.created,
      syncStatus: syncStatus,
    );

    _isEditing
        ? await _calendarRepository.updateCalendarEvent(event)
        : await _calendarRepository.createCalendarEvent(event);

    if (!mounted) return;
    Navigator.pop(context, event);
  }

  /// Xóa (mềm) sự kiện đang sửa: đưa vào Thùng rác (khôi phục được), giống cơ
  /// chế xóa của task/time interval. Hỏi xác nhận trước.
  Future<void> _onDelete() async {
    final existing = widget.event;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sự kiện'),
        content: const Text('Chuyển sự kiện này vào Thùng rác?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _calendarRepository.softDeleteCalendarEvent(existing.id);
    if (!mounted) return;
    Navigator.pop(context, existing);
  }

  String _dateLabel(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa sự kiện' : 'Thêm sự kiện'),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa',
              onPressed: _onDelete,
            ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _onSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Chọn danh sách chứa sự kiện (hoặc "Không thuộc danh sách nào").
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Danh sách'),
                trailing: DropdownButton<String?>(
                  value: _availableLists.any((l) => l.id == _selectedTaskListId)
                      ? _selectedTaskListId
                      : null,
                  hint: const Text('Không thuộc danh sách nào'),
                  onChanged: (value) =>
                      setState(() => _selectedTaskListId = value),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Không thuộc danh sách nào'),
                    ),
                    ..._availableLists.map(
                      (l) => DropdownMenuItem<String?>(
                        value: l.id,
                        child:
                            Text(l.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
              TitleListTile(
                itemColor: _color,
                titleController: _titleController,
                isCompleted: false,
                handleColorSelect: (index) {
                  setState(() => _color = ColorSeed.values[index].color);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.calendar_today_outlined),
                title: const Text('Cả ngày'),
                value: _isAllDay,
                onChanged: (v) => setState(() => _isAllDay = v),
              ),
              _dateTimeTile(isStart: true),
              _dateTimeTile(isStart: false),
              ListTile(
                leading: const Icon(Icons.repeat_outlined),
                title: const Text('Lặp lại'),
                trailing: DropdownButton<_RecurrencePreset>(
                  value: _recurrence,
                  onChanged: (v) =>
                      setState(() => _recurrence = v ?? _RecurrencePreset.none),
                  items: _RecurrencePreset.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Nhắc trước'),
                trailing: DropdownButton<int?>(
                  value: _reminderMinutes,
                  onChanged: (v) => setState(() => _reminderMinutes = v),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Mặc định'),
                    ),
                    ..._reminderOptions.map(
                      (m) => DropdownMenuItem<int?>(
                        value: m,
                        child: Text(_reminderLabel(m)),
                      ),
                    ),
                  ],
                ),
              ),
              LocationListTile(locationController: _locationController),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.notes_outlined),
                    labelText: localizations?.description ?? 'Mô tả',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reminderLabel(int minutes) {
    if (minutes == 0) return 'Lúc bắt đầu';
    if (minutes < 60) return '$minutes phút trước';
    if (minutes == 60) return '1 giờ trước';
    if (minutes < 1440) return '${minutes ~/ 60} giờ trước';
    return '${minutes ~/ 1440} ngày trước';
  }

  Widget _dateTimeTile({required bool isStart}) {
    final dt = isStart ? _start : _end;
    return ListTile(
      leading: Icon(isStart ? Icons.play_arrow_outlined : Icons.stop_outlined),
      title: Text(isStart ? 'Bắt đầu' : 'Kết thúc'),
      subtitle: Row(
        children: [
          TextButton(
            onPressed: () => _pickDate(isStart: isStart),
            child: Text(_dateLabel(dt)),
          ),
          if (!_isAllDay)
            TextButton(
              onPressed: () => _pickTime(isStart: isStart),
              child: Text(TimeOfDay.fromDateTime(dt).format(context)),
            ),
        ],
      ),
    );
  }
}
