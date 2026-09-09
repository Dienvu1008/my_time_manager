import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/device_calendar/device_calendar_service.dart';

/// Trang tạo/sửa/xóa một event trên lịch thiết bị.
///
/// - [existing] != null: chế độ sửa (điền sẵn, cho phép xóa).
/// - [existing] == null: chế độ tạo mới; dùng [initialStart]/[initialEnd] để
///   điền sẵn thời gian (ví dụ khi mở từ việc nhấn ô trống trên lịch).
///
/// Trả về (qua Navigator.pop) `true` nếu có thay đổi (đã lưu/xóa) để màn gọi
/// biết mà nạp lại lịch; null/false nếu không đổi gì.
class EditDeviceEventPage extends StatefulWidget {
  const EditDeviceEventPage({
    super.key,
    this.existing,
    this.initialStart,
    this.initialEnd,
  });

  final DeviceEvent? existing;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  State<EditDeviceEventPage> createState() => _EditDeviceEventPageState();
}

class _EditDeviceEventPageState extends State<EditDeviceEventPage> {
  final _service = DeviceCalendarService.instance;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  List<DeviceCalendarInfo> _calendars = [];
  String? _selectedCalendarId;
  late DateTime _start;
  late DateTime _end;
  bool _loading = true;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _descriptionController.text = e.description ?? '';
      _locationController.text = e.location ?? '';
      _start = e.start;
      _end = e.end;
      _selectedCalendarId = e.calendarId;
    } else {
      final now = DateTime.now();
      _start = widget.initialStart ??
          DateTime(now.year, now.month, now.day, now.hour + 1);
      _end = widget.initialEnd ??
          _start.add(const Duration(hours: 1));
    }
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    // Cần quyền để đọc danh sách lịch (và để ghi).
    final granted = await _service.ensurePermissions();
    if (!granted) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final cals = await _service.retrieveCalendars();
    // Chỉ cho chọn lịch ghi được (không read-only) để tạo/sửa.
    final writable = cals.where((c) => !c.isReadOnly).toList();
    if (!mounted) return;
    setState(() {
      _calendars = writable;
      _selectedCalendarId ??=
          writable.isNotEmpty ? writable.first.id : null;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa sự kiện' : 'Sự kiện mới'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa',
              onPressed: _saving ? null : _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_service.isSupported
              ? const _CenterMessage(
                  'Lịch thiết bị chỉ hỗ trợ trên Android/iOS.')
              : _calendars.isEmpty
                  ? const _CenterMessage(
                      'Chưa cấp quyền lịch hoặc không có lịch ghi được trên '
                      'thiết bị.')
                  : _form(),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedCalendarId,
          decoration: const InputDecoration(
            labelText: 'Lịch',
            border: OutlineInputBorder(),
          ),
          items: _calendars
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.accountName != null
                        ? '${c.name} (${c.accountName})'
                        : c.name),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCalendarId = v),
        ),
        const SizedBox(height: 16),
        _dateTimeTile(
          label: 'Bắt đầu',
          value: _start,
          onChanged: (dt) => setState(() {
            _start = dt;
            if (_end.isBefore(_start)) {
              _end = _start.add(const Duration(hours: 1));
            }
          }),
        ),
        _dateTimeTile(
          label: 'Kết thúc',
          value: _end,
          onChanged: (dt) => setState(() => _end = dt),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Địa điểm',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _dateTimeTile({
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    final fmt = DateFormat('EEE, dd MMM yyyy - HH:mm');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(fmt.format(value)),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(DateTime(
            date.year, date.month, date.day, time.hour, time.minute));
      },
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _snack('Vui lòng nhập tiêu đề.');
      return;
    }
    if (_selectedCalendarId == null) {
      _snack('Vui lòng chọn lịch.');
      return;
    }
    if (_end.isBefore(_start)) {
      _snack('Thời gian kết thúc phải sau thời gian bắt đầu.');
      return;
    }
    setState(() => _saving = true);
    final id = await _service.createOrUpdateEvent(
      calendarId: _selectedCalendarId!,
      eventId: widget.existing?.eventId,
      title: _titleController.text.trim(),
      start: _start,
      end: _end,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (id != null) {
      Navigator.pop(context, true);
    } else {
      _snack('Lưu sự kiện thất bại.');
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null || e.calendarId == null || e.eventId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sự kiện?'),
        content: Text('Xóa "${e.title}" khỏi lịch thiết bị?'),
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
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    final ok = await _service.deleteEvent(e.calendarId!, e.eventId!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _snack('Xóa sự kiện thất bại.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
