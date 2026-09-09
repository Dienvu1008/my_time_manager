import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/data/auth_repository.dart';
import '../data/sync/calendar_sync_manager.dart';

/// Thẻ cài đặt Đồng bộ lịch (Google Calendar) đặt trong màn Cài đặt.
///
/// Cho phép: bật/tắt đồng bộ, nhập/chọn calendarId (mặc định 'primary'), và
/// bấm "Đồng bộ ngay". Trạng thái lưu qua [CalendarSyncManager]
/// (SharedPreferences). Cần [AuthRepository] trong cây widget (chỉ có khi
/// Firebase/đăng nhập đã cấu hình); nếu không, thẻ hiển thị thông báo không khả
/// dụng.
class CalendarSyncSettingsCard extends StatefulWidget {
  const CalendarSyncSettingsCard({super.key});

  @override
  State<CalendarSyncSettingsCard> createState() =>
      _CalendarSyncSettingsCardState();
}

class _CalendarSyncSettingsCardState extends State<CalendarSyncSettingsCard> {
  CalendarSyncManager? _manager;
  bool _available = false;
  bool _loading = true;
  bool _enabled = false;
  bool _syncing = false;
  late final TextEditingController _calendarIdController;

  @override
  void initState() {
    super.initState();
    _calendarIdController = TextEditingController();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // AuthRepository chỉ tồn tại khi nhánh có auth được dựng. Đọc an toàn.
    AuthRepository? auth;
    try {
      auth = context.read<AuthRepository>();
    } catch (_) {
      auth = null;
    }

    if (auth == null) {
      setState(() {
        _available = false;
        _loading = false;
      });
      return;
    }

    final manager = CalendarSyncManager(authRepository: auth);
    final enabled = await manager.isEnabled();
    final calId = await manager.calendarId();
    if (!mounted) return;
    setState(() {
      _manager = manager;
      _available = true;
      _loading = false;
      _enabled = enabled;
      _calendarIdController.text = calId;
    });
  }

  @override
  void dispose() {
    _calendarIdController.dispose();
    _manager?.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _syncNow() async {
    final manager = _manager;
    if (manager == null || _syncing) return;
    setState(() => _syncing = true);
    // Lưu calendarId người dùng nhập trước khi đồng bộ.
    final id = _calendarIdController.text.trim();
    await manager.setCalendarId(id.isEmpty ? 'primary' : id);
    final outcome = await manager.syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    if (outcome.success) {
      _snack('Đồng bộ xong: +${outcome.upserted}, xóa ${outcome.deleted}.');
    } else {
      _snack('Đồng bộ thất bại: ${outcome.error ?? 'lỗi không rõ'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Đồng bộ Google Calendar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (!_available)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cần đăng nhập Google (và cấu hình xác thực) để đồng bộ lịch.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            SwitchListTile(
              secondary: const Icon(Icons.sync_outlined),
              title: const Text('Bật đồng bộ lịch'),
              subtitle: const Text(
                  'Đẩy sự kiện cục bộ lên và kéo sự kiện từ Google Calendar về.'),
              value: _enabled,
              onChanged: (v) async {
                await _manager!.setEnabled(v);
                setState(() => _enabled = v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Calendar ID'),
              subtitle: TextField(
                controller: _calendarIdController,
                enabled: _enabled,
                decoration: const InputDecoration(
                  hintText: 'primary (lịch chính) hoặc email lịch chia sẻ',
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: (_enabled && !_syncing) ? _syncNow : null,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(_syncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
