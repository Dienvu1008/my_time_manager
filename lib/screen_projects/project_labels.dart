import '../app/app_localizations.dart';
import '../domain/models/model_project.dart';

/// Nhãn đã dịch của trạng thái dự án (Core Track C6). Đặt ở đây để
/// `app_localizations.dart` không phụ thuộc vào domain model.
String projectStatusLabel(AppLocalizations l, ProjectStatus s) {
  switch (s) {
    case ProjectStatus.active:
      return l.projectStatusActive;
    case ProjectStatus.onHold:
      return l.projectStatusOnHold;
    case ProjectStatus.completed:
      return l.projectStatusCompleted;
    case ProjectStatus.cancelled:
      return l.projectStatusCancelled;
  }
}

/// Định dạng ngày đơn giản dd/MM/yyyy (giống ArchiveScreen).
String formatProjectDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
