import '../models/model_ai_action_log.dart';

/// Lưu trữ nhật ký hành động AI (Phase C8b, bảng `ai_action_log`).
///
/// Dữ liệu kiểm toán cục bộ của thiết bị: KHÔNG nằm trong sao lưu / nhập.
abstract class AiActionLogRepository {
  /// Ghi một dòng nhật ký.
  Future<void> record(AiActionLogEntry entry);

  /// Các dòng mới nhất trước, lọc theo [outcome] nếu có, tối đa [limit].
  Future<List<AiActionLogEntry>> getEntries({
    AiActionOutcome? outcome,
    int limit = 500,
  });

  /// Một dòng theo id, hoặc null.
  Future<AiActionLogEntry?> getEntry(String id);

  /// Xóa toàn bộ nhật ký; trả về số dòng đã xóa.
  Future<int> clear();

  /// Dọn theo retention: xóa dòng cũ hơn [maxAge] (tính từ [now]) rồi chỉ
  /// giữ [maxEntries] dòng mới nhất. Trả về tổng số dòng đã xóa.
  Future<int> purge({
    required DateTime now,
    int maxEntries = AiActionLogRetention.maxEntries,
    Duration maxAge = AiActionLogRetention.maxAge,
  });
}
