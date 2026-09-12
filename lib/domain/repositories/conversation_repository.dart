import '../../data/models/model_conversation.dart';

/// Ranh giới domain cho **lịch sử chat AI**: các cuộc trò chuyện và tin nhắn
/// của chúng. Tầng UI (và tương lai là các công cụ AI) phụ thuộc vào interface
/// này, không chạm trực tiếp [DatabaseManager]/SQLite.
abstract class ConversationRepository {
  /// Tất cả cuộc trò chuyện, mới cập nhật lên đầu.
  Future<List<Conversation>> getConversations();

  /// Một cuộc trò chuyện theo id, hoặc null nếu không tồn tại.
  Future<Conversation?> getConversation(String id);

  /// Tạo cuộc trò chuyện mới.
  Future<void> createConversation(Conversation conversation);

  /// Cập nhật cuộc trò chuyện (đổi tiêu đề, cập nhật updatedAt).
  Future<void> updateConversation(Conversation conversation);

  /// Xóa hẳn một cuộc trò chuyện (kèm mọi tin nhắn của nó).
  Future<void> deleteConversation(String id);

  /// Xóa các cuộc trò chuyện có lần cập nhật cuối cũ hơn [cutoff]. Trả về số
  /// cuộc đã xóa. Dùng cho tính năng tự xóa lịch sử sau N ngày.
  Future<int> deleteConversationsUpdatedBefore(DateTime cutoff);

  /// Các tin nhắn của một cuộc trò chuyện, thứ tự cũ -> mới.
  Future<List<ChatMessageRecord>> getMessages(String conversationId);

  /// Thêm một tin nhắn vào cuộc trò chuyện.
  Future<void> appendMessage(ChatMessageRecord message);
}
