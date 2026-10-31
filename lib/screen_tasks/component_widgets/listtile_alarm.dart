import 'package:flutter/material.dart';

import '../../app/app_localizations.dart';
import '../../application/reminders/reminder_ids.dart';
import '../../screen_reminders/reminder_labels.dart';

/// Danh sách listtile chọn các mốc nhắc (số phút TRƯỚC thời điểm bắt đầu).
///
/// Đẩy giá trị ra ngoài qua [onChanged] (danh sách số phút, ví dụ [15, 1440]).
/// Có thể nhận [initial] để hiển thị lại khi sửa. Nhấn vào một mốc để thay
/// bằng mốc khác. [maxCount] (nếu có) giới hạn số mốc: đạt giới hạn thì không
/// thêm được nữa.
class AlarmListTile extends StatefulWidget {
  const AlarmListTile({super.key, this.initial, this.onChanged, this.maxCount});

  final List<int>? initial;
  final ValueChanged<List<int>>? onChanged;
  final int? maxCount;

  @override
  State<AlarmListTile> createState() => _AlarmListTileState();
}

class _AlarmListTileState extends State<AlarmListTile> {
  late List<int> _minutes;

  /// Giá trị trả về từ bảng chọn khi người dùng chọn "Tùy chỉnh".
  static const int _custom = -1;

  @override
  void initState() {
    super.initState();
    _minutes = List<int>.from(widget.initial ?? const <int>[]);
  }

  bool get _canAdd =>
      widget.maxCount == null || _minutes.length < widget.maxCount!;

  void _notify() => widget.onChanged?.call(List<int>.from(_minutes));

  /// Mở bảng chọn mốc. [replacing] = mốc đang sửa (null = thêm mới). Trả về
  /// số phút được chọn (đã qua hộp thoại tùy chỉnh nếu cần), hoặc null.
  Future<int?> _pick({int? replacing}) async {
    final l = AppLocalizations.of(context)!;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  replacing == null ? l.reminderPickTitle : l.reminderEdit,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final m in kCommonReminderMinutes)
              ListTile(
                title: Text(reminderOffsetLabel(l, m)),
                enabled: m == replacing || !_minutes.contains(m),
                selected: m == replacing,
                onTap: () => Navigator.pop(ctx, m),
              ),
            ListTile(
              leading: const ExcludeSemantics(child: Icon(Icons.edit_outlined)),
              title: Text(l.reminderCustomMinutes),
              onTap: () => Navigator.pop(ctx, _custom),
            ),
          ],
        ),
      ),
    );
    if (chosen == _custom) return _askCustom();
    return chosen;
  }

  Future<int?> _askCustom() async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.reminderCustomMinutesTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l.reminderCustomMinutesHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.reminderCancel),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (n != null && n >= 0) ? n : null);
            },
            child: Text(l.reminderConfirmAdd),
          ),
        ],
      ),
    );
    return value;
  }

  Future<void> _addReminder() async {
    if (!_canAdd) return;
    final value = await _pick();
    if (value != null && !_minutes.contains(value) && _canAdd) {
      setState(() => _minutes.add(value));
      _notify();
    }
  }

  Future<void> _editReminder(int current) async {
    final value = await _pick(replacing: current);
    // Bỏ qua nếu không chọn, không đổi, hoặc trùng mốc khác.
    if (value == null || value == current || _minutes.contains(value)) return;
    final index = _minutes.indexOf(current);
    if (index < 0) return;
    setState(() => _minutes[index] = value);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sorted = List<int>.from(_minutes)..sort();
    final canAdd = _canAdd;
    return Column(
      children: [
        ListTile(
          leading: const ExcludeSemantics(
              child: Icon(Icons.notifications_active_outlined)),
          title: Text(l.reminders),
          subtitle: sorted.isEmpty
              ? Text(l.reminderNone)
              : Text(sorted.map((m) => reminderOffsetLabel(l, m)).join(', ')),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.reminderAdd,
            onPressed: canAdd ? _addReminder : null,
          ),
          onTap: canAdd ? _addReminder : null,
        ),
        for (final minutes in sorted)
          ListTile(
            dense: true,
            title: Text(reminderOffsetLabel(l, minutes)),
            onTap: () => _editReminder(minutes),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.reminderDelete,
              onPressed: () {
                setState(() => _minutes.remove(minutes));
                _notify();
              },
            ),
          ),
        const Divider(height: 4),
      ],
    );
  }
}
