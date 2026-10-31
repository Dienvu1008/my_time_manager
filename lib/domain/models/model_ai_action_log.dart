import 'package:uuid/uuid.dart';

/// Kết quả của một lần trợ lý AI cố gắng chạy công cụ GHI / XÓA (Phase C8b).
enum AiActionOutcome {
  /// Công cụ đã chạy và trả về thành công.
  executed,

  /// Người dùng từ chối ở hộp thoại xác nhận.
  declined,

  /// Công cụ trả lỗi, ném ngoại lệ, hoặc tham số JSON hỏng.
  failed,

  /// Bị chặn bởi chính sách (vd. chế độ chỉ đọc) trước khi hỏi người dùng.
  deniedByPolicy;

  static AiActionOutcome fromName(String? name) => AiActionOutcome.values
      .firstWhere((o) => o.name == name, orElse: () => AiActionOutcome.failed);
}

/// Giới hạn lưu giữ nhật ký hành động AI: tối đa [maxEntries] bản ghi mới nhất
/// VÀ không cũ hơn [maxAge]. Dọn khi app khởi động.
class AiActionLogRetention {
  const AiActionLogRetention._();
  static const int maxEntries = 1000;
  static const Duration maxAge = Duration(days: 90);
}

/// Một dòng nhật ký hành động AI (bảng `ai_action_log`, schema v17).
///
/// Chỉ chứa bản TÓM TẮT đã che bớt của tham số / kết quả (không lưu toàn văn
/// nội dung người dùng). [createdAt] được lưu dạng UTC ISO-8601 để sắp xếp
/// theo chuỗi luôn đúng.
class AiActionLogEntry {
  AiActionLogEntry({
    String? id,
    DateTime? createdAt,
    required this.toolName,
    required this.policyLevel,
    this.policyMode,
    this.argsSummary = '',
    required this.outcome,
    this.resultSummary,
    this.errorMessage,
    this.conversationId,
    this.deviceId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final DateTime createdAt;
  final String toolName;

  /// Mức rủi ro của công cụ (`write` | `destructive`).
  final String policyLevel;

  /// Tên chế độ ActionPolicy lúc gọi (vd. `confirmWrites`), null nếu không có.
  final String? policyMode;
  final String argsSummary;
  final AiActionOutcome outcome;
  final String? resultSummary;
  final String? errorMessage;
  final String? conversationId;
  final String? deviceId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'toolName': toolName,
        'policyLevel': policyLevel,
        'policyMode': policyMode,
        'argsSummary': argsSummary,
        'outcome': outcome.name,
        'resultSummary': resultSummary,
        'errorMessage': errorMessage,
        'conversationId': conversationId,
        if (deviceId != null) 'deviceId': deviceId,
      };

  factory AiActionLogEntry.fromMap(Map<String, dynamic> map) {
    return AiActionLogEntry(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
      toolName: map['toolName'] as String,
      policyLevel: map['policyLevel'] as String,
      policyMode: map['policyMode'] as String?,
      argsSummary: (map['argsSummary'] as String?) ?? '',
      outcome: AiActionOutcome.fromName(map['outcome'] as String?),
      resultSummary: map['resultSummary'] as String?,
      errorMessage: map['errorMessage'] as String?,
      conversationId: map['conversationId'] as String?,
      deviceId: map['deviceId'] as String?,
    );
  }
}
