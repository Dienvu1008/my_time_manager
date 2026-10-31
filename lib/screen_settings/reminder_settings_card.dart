import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app.dart';
import '../app/app_localizations.dart';
import '../screen_reminders/upcoming_reminders_screen.dart';

/// Thẻ cài đặt nhắc trong trang Cài đặt (Phase R, D14b): nối [AppBloc] với
/// [ReminderSettingsPanel].
class ReminderSettingsCard extends StatelessWidget {
  const ReminderSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (prev, curr) =>
          prev.remindersEnabled != curr.remindersEnabled ||
          prev.reminderCoordinatorEnabled != curr.reminderCoordinatorEnabled ||
          prev.quietHoursEnabled != curr.quietHoursEnabled ||
          prev.quietHoursStartMinutes != curr.quietHoursStartMinutes ||
          prev.quietHoursEndMinutes != curr.quietHoursEndMinutes,
      builder: (context, state) {
        final bloc = context.read<AppBloc>();
        return ReminderSettingsPanel(
          remindersEnabled: state.remindersEnabled,
          coordinatorEnabled: state.reminderCoordinatorEnabled,
          quietEnabled: state.quietHoursEnabled,
          quietStartMinutes: state.quietHoursStartMinutes,
          quietEndMinutes: state.quietHoursEndMinutes,
          onRemindersChanged: (v) => bloc.add(ToggleRemindersEnabled(v)),
          onCoordinatorChanged: (v) => bloc.add(ToggleReminderCoordinator(v)),
          onQuietHoursChanged: (enabled, start, end) => bloc.add(
              ChangeQuietHours(
                  enabled: enabled, startMinutes: start, endMinutes: end)),
          onOpenUpcoming: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const UpcomingRemindersScreen(),
            ),
          ),
        );
      },
    );
  }
}

/// Phần hiển thị (không trạng thái) của thẻ cài đặt nhắc: bật/tắt nhắc, giờ
/// yên lặng, cờ "lên lịch nhắc thông minh" và liên kết tới "Nhắc sắp tới".
class ReminderSettingsPanel extends StatelessWidget {
  const ReminderSettingsPanel({
    super.key,
    required this.remindersEnabled,
    required this.coordinatorEnabled,
    required this.quietEnabled,
    required this.quietStartMinutes,
    required this.quietEndMinutes,
    required this.onRemindersChanged,
    required this.onCoordinatorChanged,
    required this.onQuietHoursChanged,
    required this.onOpenUpcoming,
  });

  final bool remindersEnabled;
  final bool coordinatorEnabled;
  final bool quietEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;
  final ValueChanged<bool> onRemindersChanged;
  final ValueChanged<bool> onCoordinatorChanged;
  final void Function(bool enabled, int startMinutes, int endMinutes)
      onQuietHoursChanged;
  final VoidCallback onOpenUpcoming;

  static TimeOfDay _toTime(int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final current = isStart ? quietStartMinutes : quietEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: _toTime(current),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    onQuietHoursChanged(
      quietEnabled,
      isStart ? minutes : quietStartMinutes,
      isStart ? quietEndMinutes : minutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              'Nhắc',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Bật nhắc bằng thông báo'),
            subtitle: const Text(
                'Gửi thông báo trước khi công việc bắt đầu theo '
                'các mốc bạn đặt. Tắt để hủy toàn bộ nhắc.'),
            value: remindersEnabled,
            onChanged: onRemindersChanged,
          ),
          SwitchListTile(
            secondary:
                const ExcludeSemantics(child: Icon(Icons.bedtime_outlined)),
            title: Text(l.quietHours),
            subtitle: Text(l.quietHoursSubtitle),
            value: quietEnabled,
            onChanged: (v) =>
                onQuietHoursChanged(v, quietStartMinutes, quietEndMinutes),
          ),
          ListTile(
            enabled: quietEnabled,
            leading: const SizedBox(width: 24),
            title: Text(l.quietHoursStart),
            trailing: Text(_toTime(quietStartMinutes).format(context)),
            onTap: () => _pickTime(context, isStart: true),
          ),
          ListTile(
            enabled: quietEnabled,
            leading: const SizedBox(width: 24),
            title: Text(l.quietHoursEnd),
            trailing: Text(_toTime(quietEndMinutes).format(context)),
            onTap: () => _pickTime(context, isStart: false),
          ),
          SwitchListTile(
            secondary:
                const ExcludeSemantics(child: Icon(Icons.auto_mode_outlined)),
            title: Text(l.reminderEngine),
            subtitle: Text(coordinatorEnabled
                ? l.reminderEngineSubtitle
                : l.reminderLegacyModeInfo),
            value: coordinatorEnabled,
            onChanged: onCoordinatorChanged,
          ),
          ListTile(
            leading:
                const ExcludeSemantics(child: Icon(Icons.alarm_outlined)),
            title: Text(l.upcomingReminders),
            trailing: const ExcludeSemantics(child: Icon(Icons.chevron_right)),
            onTap: onOpenUpcoming,
          ),
        ],
      ),
    );
  }
}
