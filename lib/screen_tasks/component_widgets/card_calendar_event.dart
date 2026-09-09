import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/utils/constants.dart';
import 'package:my_time_manager/utils/utils.dart';

/// Thẻ hiển thị MỘT [CalendarEvent] trong danh sách ở màn Overview (tương tự
/// [TaskCard]). Tôn trọng cài đặt kiểu thẻ (filled / dải màu bên trái) giống
/// task để giao diện đồng nhất.
class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
    this.onArchive,
  });

  final CalendarEvent event;
  final Function(CalendarEvent) onEdit;
  final Function(CalendarEvent) onDelete;
  final Function(CalendarEvent)? onArchive;

  String _timeLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (event.isAllDay) {
      final d = DateFormat.yMMMd(locale).format(event.start.effective);
      return 'Cả ngày · $d';
    }
    final start = event.start.effective;
    final end = event.end.effective;
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final dateFmt = DateFormat.yMMMd(locale);
    final timeFmt = DateFormat.Hm(locale);
    if (sameDay) {
      return '${dateFmt.format(start)} · ${timeFmt.format(start)}–${timeFmt.format(end)}';
    }
    return '${dateFmt.format(start)} ${timeFmt.format(start)} → '
        '${dateFmt.format(end)} ${timeFmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final eventColor = event.color;

    final cardStyle = context.watch<AppBloc>().state.taskCardStyle;
    final bool leadingBar = cardStyle == TaskCardStyle.leadingColorBar;

    final Color backgroundColor;
    final Color labelColor;
    if (leadingBar) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      labelColor = theme.colorScheme.onSurface;
    } else {
      final scheme = theme.brightness == Brightness.dark
          ? ColorScheme.dark(primary: eventColor)
          : ColorScheme.light(primary: eventColor);
      backgroundColor = scheme.primaryContainer;
      labelColor = contrastColor(backgroundColor);
    }

    final content = ListTile(
      leading: Icon(Icons.event_outlined, color: labelColor),
      title: Text(
        event.title.isEmpty ? '(Không tiêu đề)' : event.title,
        style: textTheme.labelLarge!.copyWith(color: labelColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _timeLabel(context),
            style: textTheme.labelMedium!.copyWith(color: labelColor),
          ),
          if (event.location.isNotEmpty)
            Text(
              event.location,
              style: textTheme.labelMedium!.copyWith(color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            children: [
              if (event.isRecurring)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 2),
                  child: Icon(Icons.repeat, size: 14, color: labelColor),
                ),
              if (event.syncStatus != EventSyncStatus.synced &&
                  event.syncStatus != EventSyncStatus.localOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.sync_outlined, size: 14, color: labelColor),
                ),
            ],
          ),
        ],
      ),
      onTap: () => onEdit(event),
      trailing: _buildMenu(context, labelColor),
    );

    if (!leadingBar) {
      return Card(color: backgroundColor, child: content);
    }
    return Card(
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: eventColor),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, Color labelColor) {
    final localizations = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: labelColor),
      onSelected: (result) {
        switch (result) {
          case 'edit':
            onEdit(event);
            break;
          case 'archive':
            onArchive?.call(event);
            break;
          case 'delete':
            onDelete(event);
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Expanded(child: Text('Sửa sự kiện')),
            ],
          ),
        ),
        if (onArchive != null)
          PopupMenuItem<String>(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(localizations.archive)),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outlined),
              SizedBox(width: 8),
              Expanded(child: Text('Xóa sự kiện')),
            ],
          ),
        ),
      ],
    );
  }
}
