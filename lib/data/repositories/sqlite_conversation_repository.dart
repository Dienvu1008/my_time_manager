import '../../domain/repositories/conversation_repository.dart';
import '../database/database_manager.dart';
import '../database/daos/conversation_dao.dart';
import '../../domain/models/model_conversation.dart';

class SqliteConversationRepository implements ConversationRepository {
  SqliteConversationRepository({DatabaseManager? databaseManager})
      : _dao = ConversationDao(() => (databaseManager ?? DatabaseManager()).database);

  final ConversationDao _dao;

  @override
  Future<List<Conversation>> getConversations() => _dao.getAll();

  @override
  Future<Conversation?> getConversation(String id) => _dao.getById(id);

  @override
  Future<void> createConversation(Conversation conversation) => _dao.insert(conversation);

  @override
  Future<void> updateConversation(Conversation conversation) => _dao.update(conversation);

  @override
  Future<void> deleteConversation(String id) => _dao.delete(id);

  @override
  Future<int> deleteConversationsUpdatedBefore(DateTime cutoff) =>
      _dao.deleteUpdatedBefore(cutoff);

  @override
  Future<List<ChatMessageRecord>> getMessages(String conversationId) =>
      _dao.getMessages(conversationId);

  @override
  Future<void> appendMessage(ChatMessageRecord message) => _dao.insertMessage(message);
}
