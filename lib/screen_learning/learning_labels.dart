import '../app/app_localizations.dart';
import '../domain/models/model_course.dart';
import '../domain/models/model_lesson_progress.dart';

/// Nhãn đã dịch của trạng thái khóa học (Core Track C7). Đặt ở đây để
/// `app_localizations.dart` không phụ thuộc vào domain model.
String courseStatusLabel(AppLocalizations l, CourseStatus s) {
  switch (s) {
    case CourseStatus.active:
      return l.courseStatusActive;
    case CourseStatus.paused:
      return l.courseStatusPaused;
  }
}

/// Nhãn đã dịch của trạng thái bài học.
String lessonStatusLabel(AppLocalizations l, LessonStatus s) {
  switch (s) {
    case LessonStatus.notStarted:
      return l.lessonStatusNotStarted;
    case LessonStatus.inProgress:
      return l.lessonStatusInProgress;
    case LessonStatus.completed:
      return l.lessonStatusCompleted;
  }
}

/// Phần trăm làm tròn, vd. 0.5 → '50%'.
String formatPercent(double ratio) => '${(ratio * 100).round()}%';
