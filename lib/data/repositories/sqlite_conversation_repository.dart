import '../../domain/repositories/conversation_repository.dart';
import '../database/database_manager.dart';
import '../../domain/models/model_conversation.dart';

/// [ConversationRepository] chạy trên SQLite. Adapter mỏng qua [DatabaseManager].
class SqliteConversationRepository implements ConversationRepository {
  SqliteConversationRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<Conversation>> getConversations() => _db.conversations();

  @override
  Future<Conversation?> getConversation(String id) => _db.conversation(id);

  @override
  Future<void> createConversation(Conversation conversation) =>
      _db.insertConversation(conversation);

  @override
  Future<void> updateConversation(Conversation conversation) =>
      _db.updateConversation(conversation);

  @override
  Future<void> deleteConversation(String id) => _db.deleteConversation(id);

  @override
  Future<int> deleteConversationsUpdatedBefore(DateTime cutoff) =>
      _db.deleteConversationsUpdatedBefore(cutoff);

  @override
  Future<List<ChatMessageRecord>> getMessages(String conversationId) =>
      _db.chatMessages(conversationId);

  @override
  Future<void> appendMessage(ChatMessageRecord message) =>
      _db.insertChatMessage(message);
}
