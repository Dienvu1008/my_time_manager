// Model LessonProgress (Core Track C7 — Learning system)
import 'package:equatable/equatable.dart';

/// Trạng thái học của một bài. Lưu xuống DB dưới dạng `.name`.
enum LessonStatus {
  notStarted,
  inProgress,
  completed;

  /// Đọc từ chuỗi đã lưu; giá trị null/không xác định → [LessonStatus.notStarted].
  static LessonStatus parse(Object? raw) {
    for (final s in LessonStatus.values) {
      if (s.name == raw) return s;
    }
    return LessonStatus.notStarted;
  }
}

/// Tiến độ của MỘT bài học (bảng `lesson_progress`, tối đa một hàng / bài).
///
/// Danh tính: `id == lessonId` theo cấu trúc ([toMap] ghi `'id': lessonId`) để
/// hai thiết bị không bao giờ sinh hai hàng tiến độ cho cùng một bài → import
/// gộp sạch. Tiến độ chương/khóa học được TÍNH (LearningProgressService),
/// không lưu. `deviceId` do DAO gắn khi insert.
class LessonProgress extends Equatable {
  final String lessonId;
  final LessonStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? lastOpenedAt;
  final DateTime updateTimeStamp;

  LessonProgress({
    required this.lessonId,
    this.status = LessonStatus.notStarted,
    this.startedAt,
    this.completedAt,
    this.lastOpenedAt,
    DateTime? updateTimeStamp,
  }) : updateTimeStamp = updateTimeStamp ?? DateTime.now();

  /// Giá trị "chưa bắt đầu" cho bài chưa có hàng tiến độ (không ghi DB).
  factory LessonProgress.notStarted(String lessonId) =>
      LessonProgress(lessonId: lessonId);

  Map<String, dynamic> toMap() {
    return {
      'id': lessonId,
      'lessonId': lessonId,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'updateTimeStamp': updateTimeStamp.toIso8601String(),
    };
  }

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      lessonId: map['lessonId'] as String,
      status: LessonStatus.parse(map['status']),
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
      lastOpenedAt: _parseDate(map['lastOpenedAt']),
      updateTimeStamp: _parseDate(map['updateTimeStamp']) ?? DateTime.now(),
    );
  }

  LessonProgress copyWith({
    LessonStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? lastOpenedAt,
    DateTime? updateTimeStamp,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      updateTimeStamp: updateTimeStamp ?? this.updateTimeStamp,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  @override
  String toString() =>
      'LessonProgress(lessonId: $lessonId, status: ${status.name})';

  @override
  List<Object?> get props => [
        lessonId,
        status,
        startedAt,
        completedAt,
        lastOpenedAt,
        updateTimeStamp,
      ];
}
