@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_ai_action_log_repository.dart';
import 'package:my_time_manager/domain/models/model_ai_action_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for [SqliteAiActionLogRepository] (Phase C8b, schema v17)
/// against an in-memory sqflite (FFI) database.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  final repo = SqliteAiActionLogRepository();
  final base = DateTime(2026, 3, 1, 12);

  AiActionLogEntry entry(int minutes,
          {AiActionOutcome outcome = AiActionOutcome.executed,
          String tool = 'create_goal'}) =>
      AiActionLogEntry(
        createdAt: base.add(Duration(minutes: minutes)),
        toolName: tool,
        policyLevel: 'write',
        outcome: outcome,
      );

  test('round-trips every field', () async {
    final e = AiActionLogEntry(
      id: 'a1',
      createdAt: base,
      toolName: 'trash_goal',
      policyLevel: 'destructive',
      policyMode: 'confirmWrites',
      argsSummary: '{id: g1}',
      outcome: AiActionOutcome.declined,
      resultSummary: 'r',
      errorMessage: 'permission_denied: no',
      conversationId: 'c1',
    );
    await repo.record(e);
    final got = (await repo.getEntry('a1'))!;
    expect(got.createdAt, base);
    expect(got.toolName, 'trash_goal');
    expect(got.policyLevel, 'destructive');
    expect(got.policyMode, 'confirmWrites');
    expect(got.argsSummary, '{id: g1}');
    expect(got.outcome, AiActionOutcome.declined);
    expect(got.resultSummary, 'r');
    expect(got.errorMessage, 'permission_denied: no');
    expect(got.conversationId, 'c1');
    expect(await repo.getEntry('missing'), isNull);
  });

  test('newest first, outcome filter and limit', () async {
    await repo.record(entry(1, tool: 'a'));
    await repo.record(entry(3, tool: 'c', outcome: AiActionOutcome.declined));
    await repo.record(entry(2, tool: 'b'));

    expect((await repo.getEntries()).map((e) => e.toolName), ['c', 'b', 'a']);
    expect(
        (await repo.getEntries(outcome: AiActionOutcome.declined))
            .map((e) => e.toolName),
        ['c']);
    expect(
        (await repo.getEntries(limit: 2)).map((e) => e.toolName), ['c', 'b']);
  });

  test('clear removes everything', () async {
    await repo.record(entry(1));
    await repo.record(entry(2));
    expect(await repo.clear(), 2);
    expect(await repo.getEntries(), isEmpty);
  });

  test('purge by age keeps entries younger than maxAge', () async {
    final now = DateTime(2026, 6, 1);
    await repo.record(AiActionLogEntry(
        id: 'old',
        createdAt: now.subtract(const Duration(days: 91)),
        toolName: 't',
        policyLevel: 'write',
        outcome: AiActionOutcome.executed));
    await repo.record(AiActionLogEntry(
        id: 'young',
        createdAt: now.subtract(const Duration(days: 89)),
        toolName: 't',
        policyLevel: 'write',
        outcome: AiActionOutcome.executed));
    expect(await repo.purge(now: now), 1);
    expect((await repo.getEntries()).map((e) => e.id), ['young']);
  });

  test('purge by count keeps the newest maxEntries', () async {
    for (var i = 0; i < 5; i++) {
      await repo.record(entry(i, tool: 't$i'));
    }
    final removed =
        await repo.purge(now: base.add(const Duration(days: 1)), maxEntries: 3);
    expect(removed, 2);
    expect(
        (await repo.getEntries()).map((e) => e.toolName), ['t4', 't3', 't2']);
  });

  test('stamps the current deviceId on insert', () async {
    DatabaseManager.setCurrentDeviceId('dev-test');
    await repo.record(entry(1));
    expect((await repo.getEntries()).single.deviceId, 'dev-test');
  });
}
