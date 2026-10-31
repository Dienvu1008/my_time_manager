import '../models/model_reminder_rule.dart';

/// Lưu trữ các rule nhắc tường minh (Phase R, bảng `reminder_rules`).
///
/// Các phương thức ghi ném [ArgumentError] khi `entityType` / `entityId` rỗng
/// hoặc rule không khớp kiểu: offset cần `offsetMinutes >= 0`, absolute cần
/// `absoluteAt`.
abstract class ReminderRuleRepository {
  /// Mọi rule (mọi thực thể).
  Future<List<ReminderRule>> getAllRules();

  /// Các rule của một thực thể.
  Future<List<ReminderRule>> getRulesFor(String entityType, String entityId);

  /// Một rule theo id, hoặc null nếu không có.
  Future<ReminderRule?> getRule(String id);

  /// Upsert theo id (update trước, không có thì insert).
  Future<void> saveRule(ReminderRule rule);

  /// Xóa một rule theo id.
  Future<void> deleteRule(String id);

  /// Trong MỘT transaction: xóa các rule hiện có của thực thể có cùng [kind],
  /// rồi insert [rules] (mỗi rule phải thuộc đúng thực thể và [kind]). Rule
  /// kiểu khác của thực thể giữ nguyên.
  Future<void> replaceRulesFor(
    String entityType,
    String entityId,
    List<ReminderRule> rules, {
    required ReminderRuleKind kind,
  });
}
