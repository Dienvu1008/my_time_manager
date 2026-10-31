// Nhãn hiển thị cho mốc nhắc (Phase R, plan item 6).
import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

/// Nhãn của một mốc nhắc [minutes] phút trước mốc bắt đầu.
///
/// 0 → "đúng giờ"; bội của 1 tuần → tuần; của 1 ngày → ngày; của 1 giờ → giờ;
/// còn lại → phút. Tiếng Việt trùng với nhãn cũ của AlarmListTile.
String reminderOffsetLabel(AppLocalizations l, int minutes) {
  String fill(String template, int n) => template.replaceAll('{n}', '$n');
  if (minutes == 0) return l.reminderAtStart;
  if (minutes % 10080 == 0) {
    final n = minutes ~/ 10080;
    return n == 1 ? l.reminderOneWeekBefore : fill(l.reminderWeeksBefore, n);
  }
  if (minutes % 1440 == 0) {
    final n = minutes ~/ 1440;
    return n == 1 ? l.reminderOneDayBefore : fill(l.reminderDaysBefore, n);
  }
  if (minutes % 60 == 0) {
    final n = minutes ~/ 60;
    return n == 1 ? l.reminderOneHourBefore : fill(l.reminderHoursBefore, n);
  }
  return minutes == 1
      ? l.reminderOneMinuteBefore
      : fill(l.reminderMinutesBefore, minutes);
}

/// Ngày (định dạng trung bình theo locale) + giờ của [local].
String formatReminderWhen(BuildContext context, DateTime local) {
  final material = MaterialLocalizations.of(context);
  return '${material.formatMediumDate(local)} '
      '${TimeOfDay.fromDateTime(local).format(context)}';
}
