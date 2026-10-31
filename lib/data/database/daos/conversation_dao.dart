import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_conversation.dart';

/// DAO cho bảng `conversations` + `chat_messages` (Core Track C4).
class ConversationDao {
  ConversationDao(this._getDatabase);
  final Future<Database> Function() _getDatabase;

  static Future<void> createConversationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  static Future<void> createChatMessagesTable(Database db) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT,
        toolCalls TEXT,
        toolCallId TEXT,
        name TEXT,
        isError INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT,
        FOREIGN KEY (conversationId) REFERENCES conversations (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_chat_messages_conversation ON chat_messages (conversationId, createdAt)',
    );
  }

  Future<List<Conversation>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('conversations', orderBy: 'updatedAt DESC');
    return maps.map((m) => Conversation.fromMap(m)).toList();
  }

  Future<Conversation?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('conversations', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Conversation.fromMap(maps.first);
  }

  Future<void> insert(Conversation c) async {
    final db = await _getDatabase();
    await db.insert('conversations', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Conversation c) async {
    final db = await _getDatabase();
    await db.update('conversations', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUpdatedBefore(DateTime cutoff) async {
    final db = await _getDatabase();
    return db.delete('conversations', where: 'updatedAt < ?', whereArgs: [cutoff.toIso8601String()]);
  }

  Future<List<ChatMessageRecord>> getMessages(String conversationId) async {
    final db = await _getDatabase();
    final maps = await db.query('chat_messages',
        where: 'conversationId = ?', whereArgs: [conversationId], orderBy: 'createdAt ASC');
    return maps.map((m) => ChatMessageRecord.fromMap(m)).toList();
  }

  Future<void> insertMessage(ChatMessageRecord message) async {
    final db = await _getDatabase();
    await db.insert('chat_messages', message.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
