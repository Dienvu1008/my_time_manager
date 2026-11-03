import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../app/app.dart';
import '../app/app_localizations.dart';

/// Immutable snapshot of the Daily Review settings (Phase DR2).
class DailyReviewSettingsValue {
  const DailyReviewSettingsValue({
    required this.enabled,
    required this.reviewTimeMinutes,
    required this.workStartMinutes,
    required this.workEndMinutes,
    required this.workDayBits,
    required this.bufferMinutes,
  });

  factory DailyReviewSettingsValue.of(AppState s) => DailyReviewSettingsValue(
        enabled: s.dailyReviewEnabled,
        reviewTimeMinutes: s.dailyReviewTimeMinutes,
        workStartMinutes: s.dailyReviewWorkStartMinutes,
        workEndMinutes: s.dailyReviewWorkEndMinutes,
        workDayBits: s.dailyReviewWorkDayBits,
        bufferMinutes: s.dailyReviewBufferMinutes,
      );

  final bool enabled;
  final int reviewTimeMinutes;
  final int workStartMinutes;
  final int workEndMinutes;

  /// Bit 0 = Monday … bit 6 = Sunday.
  final int workDayBits;
  final int bufferMinutes;

  DailyReviewSettingsValue copyWith({
    bool? enabled,
    int? reviewTimeMinutes,
    int? workStartMinutes,
    int? workEndMinutes,
    int? workDayBits,
    int? bufferMinutes,
  }) =>
      DailyReviewSettingsValue(
        enabled: enabled ?? this.enabled,
        reviewTimeMinutes: reviewTimeMinutes ?? this.reviewTimeMinutes,
        workStartMinutes: workStartMinutes ?? this.workStartMinutes,
        workEndMinutes: workEndMinutes ?? this.workEndMinutes,
        workDayBits: workDayBits ?? this.workDayBits,
        bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      );

  ChangeDailyReviewSettings toEvent() => ChangeDailyReviewSettings(
        enabled: enabled,
        reviewTimeMinutes: reviewTimeMinutes,
        workStartMinutes: workStartMinutes,
        workEndMinutes: workEndMinutes,
        workDayBits: workDayBits,
        bufferMinutes: bufferMinutes,
      );
}

/// Settings card for the Daily Review (Phase DR2): wires [AppBloc] to
/// [DailyReviewSettingsPanel]. Changes are persisted by AppBloc; the daily
/// notification is rescheduled by the reminder engine.
class DailyReviewSettingsCard extends StatelessWidget {
  const DailyReviewSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (a, b) =>
          a.dailyReviewEnabled != b.dailyReviewEnabled ||
          a.dailyReviewTimeMinutes != b.dailyReviewTimeMinutes ||
          a.dailyReviewWorkStartMinutes != b.dailyReviewWorkStartMinutes ||
          a.dailyReviewWorkEndMinutes != b.dailyReviewWorkEndMinutes ||
          a.dailyReviewWorkDayBits != b.dailyReviewWorkDayBits ||
          a.dailyReviewBufferMinutes != b.dailyReviewBufferMinutes,
      builder: (context, state) => DailyReviewSettingsPanel(
        value: DailyReviewSettingsValue.of(state),
        onChanged: (v) => context.read<AppBloc>().add(v.toEvent()),
      ),
    );
  }
}

/// Stateless view of the Daily Review settings.
class DailyReviewSettingsPanel extends StatelessWidget {
  const DailyReviewSettingsPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DailyReviewSettingsValue value;
  final ValueChanged<DailyReviewSettingsValue> onChanged;

  static const bufferChoices = [0, 5, 10, 15];

  static TimeOfDay _toTime(int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);

  Future<int?> _pick(BuildContext context, int current) async {
    final picked =
        await showTimePicker(context: context, initialTime: _toTime(current));
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final enabled = value.enabled;
    // MaterialLocalizations.narrowWeekdays starts on Sunday.
    String dayLabel(int isoDay) => ml.narrowWeekdays[isoDay % 7];
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              l.dailyReviewSettings,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            key: const ValueKey('dr-settings-enabled'),
            secondary:
                const ExcludeSemantics(child: Icon(Icons.fact_check_outlined)),
            title: Text(l.dailyReviewEnable),
            value: enabled,
            onChanged: (v) => onChanged(value.copyWith(enabled: v)),
          ),
          ListTile(
            key: const ValueKey('dr-settings-time'),
            enabled: enabled,
            leading: const ExcludeSemantics(child: Icon(Icons.schedule)),
            title: Text(l.dailyReviewTime),
            trailing: Text(_toTime(value.reviewTimeMinutes).format(context)),
            onTap: () async {
              final m = await _pick(context, value.reviewTimeMinutes);
              if (m != null) onChanged(value.copyWith(reviewTimeMinutes: m));
            },
          ),
          ListTile(
            enabled: enabled,
            leading: const SizedBox(width: 24),
            title: Text(l.dailyReviewWorkingHoursStart),
            trailing: Text(_toTime(value.workStartMinutes).format(context)),
            onTap: () async {
              final m = await _pick(context, value.workStartMinutes);
              if (m != null) onChanged(value.copyWith(workStartMinutes: m));
            },
          ),
          ListTile(
            enabled: enabled,
            leading: const SizedBox(width: 24),
            title: Text(l.dailyReviewWorkingHoursEnd),
            trailing: Text(_toTime(value.workEndMinutes).format(context)),
            onTap: () async {
              final m = await _pick(context, value.workEndMinutes);
              if (m != null) onChanged(value.copyWith(workEndMinutes: m));
            },
          ),
          ListTile(
            enabled: enabled,
            title: Text(l.dailyReviewWorkingDays),
            subtitle: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  FilterChip(
                    key: ValueKey('dr-settings-day-$d'),
                    label: Text(dayLabel(d)),
                    // Full weekday name for screen readers (2024-01-01 is a
                    // Monday, so day d of that week has ISO weekday d).
                    tooltip: DateFormat.EEEE(
                            Localizations.localeOf(context).toLanguageTag())
                        .format(DateTime(2024, 1, d)),
                    selected: value.workDayBits & (1 << (d - 1)) != 0,
                    onSelected: !enabled
                        ? null
                        : (sel) => onChanged(value.copyWith(
                            workDayBits: sel
                                ? value.workDayBits | (1 << (d - 1))
                                : value.workDayBits & ~(1 << (d - 1)))),
                  ),
              ],
            ),
          ),
          ListTile(
            enabled: enabled,
            title: Text(l.dailyReviewBufferMinutes),
            trailing: DropdownButton<int>(
              key: const ValueKey('dr-settings-buffer'),
              value: bufferChoices.contains(value.bufferMinutes)
                  ? value.bufferMinutes
                  : 0,
              items: [
                for (final b in bufferChoices)
                  DropdownMenuItem(value: b, child: Text('$b')),
              ],
              onChanged: !enabled
                  ? null
                  : (b) => onChanged(value.copyWith(bufferMinutes: b ?? 0)),
            ),
          ),
        ],
      ),
    );
  }
}
