import 'package:flutter/material.dart';

/// Danh sách listtile chọn các mốc nhắc (số phút TRƯỚC thời điểm bắt đầu).
///
/// Đẩy giá trị ra ngoài qua [onChanged] (danh sách số phút, ví dụ [15, 1440]).
/// Có thể nhận [initial] để hiển thị lại khi sửa.
class AlarmListTile extends StatefulWidget {
  const AlarmListTile({super.key, this.initial, this.onChanged});

  final List<int>? initial;
  final ValueChanged<List<int>>? onChanged;

  @override
  State<AlarmListTile> createState() => _AlarmListTileState();
}

class _AlarmListTileState extends State<AlarmListTile> {
  late List<int> _minutes;

  /// Các mốc nhắc dựng sẵn: nhãn -> số phút trước.
  static const Map<String, int> _presets = {
    'Đúng giờ': 0,
    '5 phút trước': 5,
    '10 phút trước': 10,
    '15 phút trước': 15,
    '30 phút trước': 30,
    '1 giờ trước': 60,
    '2 giờ trước': 120,
    '1 ngày trước': 1440,
    '2 ngày trước': 2880,
    '1 tuần trước': 10080,
  };

  @override
  void initState() {
    super.initState();
    _minutes = List<int>.from(widget.initial ?? const <int>[]);
  }

  String _labelFor(int minutes) {
    for (final entry in _presets.entries) {
      if (entry.value == minutes) return entry.key;
    }
    if (minutes % 1440 == 0) return '${minutes ~/ 1440} ngày trước';
    if (minutes % 60 == 0) return '${minutes ~/ 60} giờ trước';
    return '$minutes phút trước';
  }

  void _notify() => widget.onChanged?.call(List<int>.from(_minutes));

  Future<void> _addReminder() async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chọn thời điểm nhắc',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final entry in _presets.entries)
              ListTile(
                title: Text(entry.key),
                enabled: !_minutes.contains(entry.value),
                onTap: () => Navigator.pop(ctx, entry.value),
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Tùy chỉnh (phút trước)...'),
              onTap: () => Navigator.pop(ctx, -1),
            ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    if (chosen == -1) {
      await _addCustom();
      return;
    }
    if (!_minutes.contains(chosen)) {
      setState(() => _minutes.add(chosen));
      _notify();
    }
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Số phút trước'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Ví dụ: 45'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (n != null && n >= 0) ? n : null);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    if (value != null && !_minutes.contains(value)) {
      setState(() => _minutes.add(value));
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<int>.from(_minutes)..sort();
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Nhắc'),
          subtitle: sorted.isEmpty
              ? const Text('Chưa đặt nhắc')
              : Text(sorted.map(_labelFor).join(', ')),
          trailing: const Icon(Icons.add),
          onTap: _addReminder,
        ),
        for (final minutes in sorted)
          ListTile(
            dense: true,
            title: Text(_labelFor(minutes)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
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
