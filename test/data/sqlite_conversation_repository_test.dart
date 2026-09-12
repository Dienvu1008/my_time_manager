@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_conversation.dart';
import 'package:my_time_manager/data/repositories/sqlite_conversation_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for the SQLite-backed ConversationRepository (chat history).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('create + getConversation round-trips', () async {
    final repo = SqliteConversationRepository();
    final c = Conversation(title: 'Planning');
    await repo.createConversation(c);

    final fetched = await repo.getConversation(c.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, c.id);
    expect(fetched.title, 'Planning');
  });

  test('getConversations sorts most-recently-updated first', () async {
    final repo = SqliteConversationRepository();
    final older = Conversation(
      title: 'Older',
      updatedAt: DateTime(2026, 1, 1),
    );
    final newer = Conversation(
      title: 'Newer',
      updatedAt: DateTime(2026, 6, 1),
    );
    await repo.createConversation(older);
    await repo.createConversation(newer);

    final all = await repo.getConversations();
    expect(all.first.id, newer.id);
    expect(all.last.id, older.id);
  });

  test('appendMessage + getMessages keep order and round-trip fields', () async {
    final repo = SqliteConversationRepository();
    final c = Conversation(title: 'Chat');
    await repo.createConversation(c);

    await repo.appendMessage(ChatMessageRecord.fromAiMessage(
      c.id,
      const AiMessage.user('hello'),
      createdAt: DateTime(2026, 1, 1, 10, 0),
    ));
    await repo.appendMessage(ChatMessageRecord.fromAiMessage(
      c.id,
      const AiMessage.assistant('hi there'),
      createdAt: DateTime(2026, 1, 1, 10, 1),
    ));

    final msgs = await repo.getMessages(c.id);
    expect(msgs.map((m) => m.content), ['hello', 'hi there']);
    expect(msgs.first.role, AiRole.user);
    expect(msgs.last.role, AiRole.assistant);
  });

  test('tool calls and error flag survive a round-trip', () async {
    final repo = SqliteConversationRepository();
    final c = Conversation(title: 'Tools');
    await repo.createConversation(c);

    final toolCall = AiMessage.assistantToolCalls(const [
      AiToolCall(id: 'call_1', name: 'create_task', rawArguments: '{"title":"x"}'),
    ]);
    await repo.appendMessage(ChatMessageRecord.fromAiMessage(c.id, toolCall));
    await repo.appendMessage(ChatMessageRecord.fromAiMessage(
      c.id,
      const AiMessage.assistant('Something went wrong'),
      isError: true,
    ));

    final msgs = await repo.getMessages(c.id);
    expect(msgs.first.toolCalls, hasLength(1));
    expect(msgs.first.toolCalls.first.name, 'create_task');
    expect(msgs.last.isError, isTrue);
  });

  test('deleteConversation removes its messages (cascade)', () async {
    final repo = SqliteConversationRepository();
    final c = Conversation(title: 'Doomed');
    await repo.createConversation(c);
    await repo.appendMessage(
        ChatMessageRecord.fromAiMessage(c.id, const AiMessage.user('bye')));

    await repo.deleteConversation(c.id);

    expect(await repo.getConversation(c.id), isNull);
    expect(await repo.getMessages(c.id), isEmpty);
  });

  test('updateConversation renames', () async {
    final repo = SqliteConversationRepository();
    final c = Conversation(title: 'Before');
    await repo.createConversation(c);

    await repo.updateConversation(c.copyWith(title: 'After'));

    expect((await repo.getConversation(c.id))!.title, 'After');
  });

  test('deleteConversationsUpdatedBefore removes only the stale ones', () async {
    final repo = SqliteConversationRepository();
    final stale = Conversation(
      title: 'Stale',
      updatedAt: DateTime(2026, 1, 1),
    );
    final fresh = Conversation(
      title: 'Fresh',
      updatedAt: DateTime(2026, 6, 1),
    );
    await repo.createConversation(stale);
    await repo.createConversation(fresh);

    final removed =
        await repo.deleteConversationsUpdatedBefore(DateTime(2026, 3, 1));

    expect(removed, 1);
    final remaining = await repo.getConversations();
    expect(remaining.map((c) => c.id), [fresh.id]);
  });
}
