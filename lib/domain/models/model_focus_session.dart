import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Loại task mà một phiên focus gắn vào.
///
/// Sau khi hợp nhất 3 loại task thành một model [Task] duy nhất, enum này chỉ
/// còn [none] (không gắn task) và [task] (gắn với một task). Giá trị được lưu
/// theo index; xem [FocusTaskType.fromIndex] để đọc an toàn dữ liệu cũ.
enum FocusTaskType {
  none,
  task;

  /// Đọc an toàn từ index đã lưu. Dữ liệu cũ có thể chứa index 2 (measurableTask)
  /// hoặc 3 (taskWithSubtasks) — nay đều quy về [task].
  static FocusTaskType fromIndex(int? index) {
    if (index == null || index == 0) return FocusTaskType.none;
    return FocusTaskType.task;
  }

  /// Nhãn hiển thị tiếng Việt.
  String get label {
    switch (this) {
      case FocusTaskType.none:
        return 'Không gắn task';
      case FocusTaskType.task:
        return 'Công việc';
    }
  }
}

/// Một phiên focus (một lần chạy hết một khoảng "focus" của Pomodoro).
///
/// Đây là đơn vị dữ liệu để thống kê. Ta cố tình lưu kèm [taskTitle] (denormalize)
/// để màn hình thống kê hiển thị được tên task mà không phải join sang bảng task
/// — và vẫn đúng kể cả sau này task gốc bị đổi tên hoặc xóa.
class FocusSession extends Equatable {
  FocusSession({
    String? id,
    this.taskType = FocusTaskType.none,
    this.taskId,
    this.taskTitle = '',
    required this.startTime,
    required this.endTime,
    required this.focusDurationSeconds,
    this.completed = true,
    this.synced = false,
  }) : id = id ?? const Uuid().v4();

  /// Khóa chính (UUID).
  final String id;

  /// Loại task gắn với phiên.
  final FocusTaskType taskType;

  /// ID của task gắn với phiên (null nếu [taskType] == none).
  final String? taskId;

  /// Tên task tại thời điểm focus (denormalize để thống kê ổn định).
  final String taskTitle;

  /// Thời điểm bắt đầu và kết thúc phiên focus.
  final DateTime startTime;
  final DateTime endTime;

  /// Số giây thực sự đã focus (đã trừ thời gian pause nếu có).
  final int focusDurationSeconds;

  /// True nếu phiên chạy hết giờ (không bị reset/hủy giữa chừng).
  final bool completed;

  /// True nếu đã đồng bộ lên Firestore. Dùng cho cơ chế sync sau này.
  final bool synced;

  /// Số phút focus (làm tròn) — tiện cho hiển thị/thống kê.
  int get focusMinutes => (focusDurationSeconds / 60).round();

  // ----------------- SQLite -----------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskType': taskType.index,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'focusDurationSeconds': focusDurationSeconds,
      'completed': completed ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      taskType: FocusTaskType.fromIndex(map['taskType'] as int?),
      taskId: map['taskId'] as String?,
      taskTitle: (map['taskTitle'] as String?) ?? '',
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      focusDurationSeconds: map['focusDurationSeconds'] as int,
      completed: (map['completed'] as int) == 1,
      synced: (map['synced'] as int) == 1,
    );
  }

  // ----------------- Firestore -----------------

  /// Chuyển sang map để ghi lên Firestore. Dùng ISO string cho thời gian để
  /// nhất quán với SQLite và tránh phụ thuộc kiểu Timestamp của Firestore ở
  /// tầng model (giữ model độc lập với plugin).
  Map<String, dynamic> toFirestore() {
    return {
      'taskType': taskType.index,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'focusDurationSeconds': focusDurationSeconds,
      'completed': completed,
    };
  }

  factory FocusSession.fromFirestore(String id, Map<String, dynamic> data) {
    return FocusSession(
      id: id,
      taskType: FocusTaskType.fromIndex(data['taskType'] as int?),
      taskId: data['taskId'] as String?,
      taskTitle: (data['taskTitle'] as String?) ?? '',
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: DateTime.parse(data['endTime'] as String),
      focusDurationSeconds: (data['focusDurationSeconds'] as num).toInt(),
      completed: (data['completed'] as bool?) ?? true,
      synced: true,
    );
  }

  FocusSession copyWith({
    String? id,
    FocusTaskType? taskType,
    String? taskId,
    String? taskTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? focusDurationSeconds,
    bool? completed,
    bool? synced,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskType: taskType ?? this.taskType,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      focusDurationSeconds: focusDurationSeconds ?? this.focusDurationSeconds,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
    );
  }

  String toJson() => json.encode(toMap());
  factory FocusSession.fromJson(String source) =>
      FocusSession.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        id,
        taskType,
        taskId,
        taskTitle,
        startTime,
        endTime,
        focusDurationSeconds,
        completed,
        synced,
      ];
}
