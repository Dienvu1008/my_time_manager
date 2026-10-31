import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_reminder_rule.dart';
import '../screen_reminders/reminder_labels.dart';

/// Danh sách mốc nhắc theo thời điểm cụ thể (wall-clock cục bộ) — Phase R.
///
/// Thêm qua bộ chọn ngày rồi giờ; nhấn một dòng để sửa; nút xóa có tooltip.
/// Đẩy danh sách (đã sắp xếp) ra ngoài qua [onChanged].
class AbsoluteRemindersTile extends StatefulWidget {
  const AbsoluteRemindersTile({
    super.key,
    this.initial = const [],
    this.onChanged,
  });

  final List<WallClock> initial;
  final ValueChanged<List<WallClock>>? onChanged;

  @override
  State<AbsoluteRemindersTile> createState() => _AbsoluteRemindersTileState();
}

class _AbsoluteRemindersTileState extends State<AbsoluteRemindersTile> {
  late List<WallClock> _times;

  @override
  void initState() {
    super.initState();
    _times = List<WallClock>.from(widget.initial);
    _sort();
  }

  void _sort() => _times.sort(
      (a, b) => a.toLocalDateTime().compareTo(b.toLocalDateTime()));

  void _notify() => widget.onChanged?.call(List<WallClock>.from(_times));

  Future<WallClock?> _pick(WallClock? current) async {
    final base = current?.toLocalDateTime() ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return null;
    return WallClock(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _add() async {
    final value = await _pick(null);
    if (value == null || _times.contains(value)) return;
    setState(() {
      _times.add(value);
      _sort();
    });
    _notify();
  }

  Future<void> _edit(WallClock current) async {
    final value = await _pick(current);
    if (value == null || value == current || _times.contains(value)) return;
    setState(() {
      _times[_times.indexOf(current)] = value;
      _sort();
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          leading: const ExcludeSemantics(child: Icon(Icons.event_outlined)),
          title: Text(l.reminderAtSpecificTime),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.reminderAdd,
            onPressed: _add,
          ),
          onTap: _add,
        ),
        for (final t in _times)
          ListTile(
            dense: true,
            title: Text(formatReminderWhen(context, t.toLocalDateTime())),
            onTap: () => _edit(t),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.reminderDelete,
              onPressed: () {
                setState(() => _times.remove(t));
                _notify();
              },
            ),
          ),
      ],
    );
  }
}
