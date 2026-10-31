import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app.dart' show AppBloc, AppState;
import '../app/app_localizations.dart';
import '../application/reminders/notification_scheduler.dart';
import '../application/reminders/reminder_coordinator.dart';
import '../domain/models/model_reminder_rule.dart';
import 'reminder_labels.dart';

/// Màn "Nhắc sắp tới" (Phase R, plan item 7): danh sách mốc nhắc mà
/// [ReminderCoordinator] sẽ đặt (kể cả mốc bị hoãn do giới hạn nền tảng).
/// Hiện banner không chặn khi quyền thông báo bị từ chối hoặc chưa được đặt
/// báo thức chính xác. Khi nhắc bị tắt / đang ở chế độ legacy (theo [AppBloc]
/// nếu có), hiện thông báo thay cho danh sách.
class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() =>
      _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  late final ReminderCoordinator _coordinator =
      context.read<ReminderCoordinator>();
  late Future<List<UpcomingReminder>> _future;

  @override
  void initState() {
    super.initState();
    _future = _coordinator.upcoming();
    _coordinator.refreshPermission();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _coordinator.upcoming();
    });
    await _future;
  }

  Future<void> _allow() async {
    await _coordinator.requestPermission();
    await _coordinator.refreshPermission();
    if (mounted) await _refresh();
  }

  /// Thông báo thay cho danh sách khi engine không đặt các mốc này: nhắc bị
  /// tắt, hoặc đang ở chế độ legacy. null = coordinator đang hoạt động.
  String? _inactiveNotice(AppLocalizations l, AppState state) {
    if (!state.remindersEnabled) return l.remindersOffInfo;
    if (!state.reminderCoordinatorEnabled) return l.reminderLegacyModeInfo;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final appBloc = context.read<AppBloc?>();
    return Scaffold(
      appBar: AppBar(title: Text(l.upcomingReminders)),
      body: appBloc == null
          ? _buildActive(l)
          : BlocBuilder<AppBloc, AppState>(
              bloc: appBloc,
              buildWhen: (a, b) =>
                  a.remindersEnabled != b.remindersEnabled ||
                  a.reminderCoordinatorEnabled != b.reminderCoordinatorEnabled,
              builder: (context, state) {
                final notice = _inactiveNotice(l, state);
                return notice == null
                    ? _buildActive(l)
                    : _InactiveNotice(message: notice);
              },
            ),
    );
  }

  Widget _buildActive(AppLocalizations l) {
    return Column(
      children: [
        ValueListenableBuilder<ReminderHealth>(
          valueListenable: _coordinator.health,
          builder: (context, health, _) {
            final String message;
            if (health.permission == ReminderPermission.denied) {
              message = l.notificationsDenied;
            } else if (!health.exactAlarmsAllowed) {
              message = l.exactAlarmsDenied;
            } else {
              return const SizedBox.shrink();
            }
            return MaterialBanner(
              leading: const ExcludeSemantics(
                  child: Icon(Icons.notifications_off_outlined)),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: _allow,
                  child: Text(l.allowNotifications),
                ),
              ],
            );
          },
        ),
        Expanded(
          child: FutureBuilder<List<UpcomingReminder>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? const <UpcomingReminder>[];
              return RefreshIndicator(
                onRefresh: _refresh,
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_EmptyState(l: l)],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _UpcomingTile(item: items[index], l: l),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InactiveNotice extends StatelessWidget {
  const _InactiveNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
                child: Icon(Icons.notifications_paused_outlined, size: 48)),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item, required this.l});

  final UpcomingReminder item;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final p = item.planned;
    final when = formatReminderWhen(context, item.fireAtLocal);
    final detail = p.offsetMinutes == null
        ? l.reminderAbsoluteAt.replaceAll('{time}', when)
        : '$when · ${reminderOffsetLabel(l, p.offsetMinutes!)}';
    final chips = <Widget>[
      if (!item.scheduled)
        Chip(
          label: Text(l.reminderDeferred),
          visualDensity: VisualDensity.compact,
        ),
      if (p.shiftedByQuietHours)
        Chip(
          label: Text(l.reminderShiftedQuietHours),
          visualDensity: VisualDensity.compact,
        ),
    ];
    return ListTile(
      leading: p.priority == ReminderPriority.high
          ? Icon(Icons.priority_high, semanticLabel: l.reminderHighPriority)
          : const ExcludeSemantics(child: Icon(Icons.alarm_outlined)),
      title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(spacing: 8, runSpacing: 4, children: chips),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
              child: Icon(Icons.alarm_off_outlined, size: 48)),
          const SizedBox(height: 16),
          Text(l.noUpcomingReminders,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noUpcomingRemindersHint,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
