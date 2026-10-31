import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/ai/policy/action_policy.dart';
import 'package:my_time_manager/ai/policy/confirmation.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';
import 'package:my_time_manager/domain/models/model_ai_action_log.dart';

import '../support/recording_ai_action_log.dart';

enum _Behaviour { ok, failure, throws }

class _FakeTool extends Tool {
  _FakeTool(this.name, this.risk, [this.behaviour = _Behaviour.ok]);
  @override
  final String name;
  @override
  final ToolRisk risk;
  final _Behaviour behaviour;
  int executed = 0;
  @override
  String get description => 'fake';
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    executed++;
    switch (behaviour) {
      case _Behaviour.ok:
        return const ToolResult.ok({'id': 'new-id', 'title': 'Made'});
      case _Behaviour.failure:
        return const ToolResult.failure(ToolResult.codeDomainError, 'it broke');
      case _Behaviour.throws:
        throw StateError('boom');
    }
  }
}

/// Phase C8b: the executor records every WRITE / DESTRUCTIVE attempt.
void main() {
  late _FakeTool write;
  late _FakeTool failing;
  late _FakeTool throwing;
  late _FakeTool destroy;
  late _FakeTool read;
  late ToolRegistry registry;
  late RecordingAiActionLog log;

  setUp(() {
    write = _FakeTool('write_ok', ToolRisk.write);
    failing = _FakeTool('write_fail', ToolRisk.write, _Behaviour.failure);
    throwing = _FakeTool('write_throw', ToolRisk.write, _Behaviour.throws);
    destroy = _FakeTool('destroy', ToolRisk.destructive);
    read = _FakeTool('read', ToolRisk.readOnly);
    registry = ToolRegistry([write, failing, throwing, destroy, read]);
    log = RecordingAiActionLog();
  });

  ToolExecutor exec({
    PolicyMode? mode,
    ConfirmationHandler? confirm,
    ToolPermissionCheck? permissionCheck,
    String? conversationId,
  }) =>
      ToolExecutor(
        registry,
        policy: mode == null ? null : ActionPolicy(mode: mode),
        confirm: confirm,
        permissionCheck: permissionCheck,
        actionLog: log,
        conversationId: () => conversationId,
        clock: () => DateTime(2026, 1, 1),
      );

  test('executed when approved, with ids and policy captured', () async {
    final r = await exec(
            mode: PolicyMode.confirmWrites,
            confirm: approveAllConfirmation,
            conversationId: 'conv-1')
        .execute('write_ok', {'title': 'Plan'});
    expect(r.success, isTrue);
    final e = log.entries.single;
    expect(e.toolName, 'write_ok');
    expect(e.outcome, AiActionOutcome.executed);
    expect(e.policyLevel, 'write');
    expect(e.policyMode, 'confirmWrites');
    expect(e.conversationId, 'conv-1');
    expect(e.createdAt, DateTime(2026, 1, 1));
    expect(e.resultSummary, contains('new-id'));
    expect(e.errorMessage, isNull);
  });

  test('declined when the user says no', () async {
    final r = await exec(
            mode: PolicyMode.confirmWrites, confirm: denyByDefaultConfirmation)
        .execute('destroy', {'id': 'g1'});
    expect(r.success, isFalse);
    expect(destroy.executed, 0);
    final e = log.entries.single;
    expect(e.outcome, AiActionOutcome.declined);
    expect(e.policyLevel, 'destructive');
    expect(e.argsSummary, '{id: g1}');
  });

  test('failed when the tool returns a failure', () async {
    await exec().execute('write_fail', {});
    final e = log.entries.single;
    expect(e.outcome, AiActionOutcome.failed);
    expect(e.errorMessage, 'domain_error: it broke');
    expect(e.policyMode, isNull);
  });

  test('failed when the tool throws', () async {
    final r = await exec().execute('write_throw', {});
    expect(r.errorCode, ToolResult.codeDomainError);
    expect(log.entries.single.outcome, AiActionOutcome.failed);
    expect(log.entries.single.errorMessage, contains('boom'));
  });

  test('failed for malformed JSON args on a known write tool', () async {
    final r = await exec(
            mode: PolicyMode.confirmWrites, confirm: approveAllConfirmation)
        .executeCall(
            const AiToolCall(id: 'c1', name: 'write_ok', rawArguments: '{bad'));
    expect(r.errorCode, ToolResult.codeInvalidArguments);
    expect(write.executed, 0);
    expect(log.entries.single.outcome, AiActionOutcome.failed);
    expect(log.entries.single.errorMessage, contains('malformed'));
  });

  test('deniedByPolicy in read-only mode; confirm never called', () async {
    var asked = 0;
    final r = await exec(
        mode: PolicyMode.readOnly,
        confirm: (_) async {
          asked++;
          return true;
        }).execute('destroy', {'id': 'g1'});
    expect(r.errorCode, ToolResult.codePermissionDenied);
    expect(asked, 0);
    expect(destroy.executed, 0);
    expect(log.entries.single.outcome, AiActionOutcome.deniedByPolicy);
    expect(log.entries.single.policyMode, 'readOnly');
  });

  test('deniedByPolicy from a permission check', () async {
    await exec(permissionCheck: (_, __) => 'nope').execute('write_ok', {});
    expect(write.executed, 0);
    expect(log.entries.single.outcome, AiActionOutcome.deniedByPolicy);
    expect(log.entries.single.errorMessage, 'permission_denied: nope');
  });

  test('read-only and unknown tools are not logged', () async {
    await exec(mode: PolicyMode.confirmWrites).execute('read', {});
    await exec(mode: PolicyMode.confirmWrites).execute('nope', {});
    await exec().executeCall(
        const AiToolCall(id: 'c', name: 'nope', rawArguments: '{bad'));
    expect(read.executed, 1);
    expect(log.entries, isEmpty);
  });

  test('write without any policy is still logged as executed', () async {
    await exec().execute('write_ok', {});
    expect(log.entries.single.outcome, AiActionOutcome.executed);
  });

  test('argsSummary redacts free text and caps titles', () async {
    await exec().execute('write_ok', {
      'title': 'T' * 100,
      'description': 'secret plans for the weekend',
      'goalId': 'g1',
      'priority': 3,
      'tags': ['a', 'b'],
    });
    final s = log.entries.single.argsSummary;
    expect(s, contains('description: <28 chars>'));
    expect(s, isNot(contains('secret')));
    expect(s, contains('title: ${'T' * 40}…'));
    expect(s, contains('goalId: g1'));
    expect(s, contains('priority: 3'));
    expect(s, contains('tags: [2 items]'));
  });

  test('a throwing sink does not change the result', () async {
    final exec = ToolExecutor(registry,
        actionLog: RecordingAiActionLog(throwOnRecord: true));
    final r = await exec.execute('write_ok', {});
    expect(r.success, isTrue);
    expect(write.executed, 1);
  });
}
