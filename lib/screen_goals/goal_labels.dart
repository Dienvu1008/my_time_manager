import '../app/app_localizations.dart';
import '../domain/models/model_goal.dart';

/// Nhãn đã dịch của trạng thái mục tiêu. Đặt ở đây để
/// `app_localizations.dart` không phụ thuộc vào domain model.
String goalStatusLabel(AppLocalizations l, GoalStatus s) {
  switch (s) {
    case GoalStatus.active:
      return l.goalStatusActive;
    case GoalStatus.paused:
      return l.goalStatusPaused;
    case GoalStatus.completed:
      return l.goalStatusCompleted;
    case GoalStatus.abandoned:
      return l.goalStatusAbandoned;
  }
}
