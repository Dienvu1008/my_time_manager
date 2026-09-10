import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/policy/action_policy.dart';
import 'package:my_time_manager/ai/policy/confirmation.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';

class _FakeTool extends Tool {
  _FakeTool(this._name, this._risk);
  final String _name;
  final ToolRisk _risk;
  int executed = 0;
  @override
  String get name => _name;
  @override
  String get description => 'fake';
  @override
  ToolRisk get risk => _risk;
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    executed++;
    return const ToolResult.ok('ran');
  }
}

void main() {
  group('ActionPolicy.evaluate', () {
    final readTool = _FakeTool('read', ToolRisk.readOnly);
    final writeTool = _FakeTool('write', ToolRisk.write);
    final destroyTool = _FakeTool('destroy', ToolRisk.destructive);

    test('confirmWrites: read allow, write confirm, destructive confirm', () {
      const p = ActionPolicy(); // default confirmWrites
      expect(p.evaluate(readTool), PolicyDecision.allow);
      expect(p.evaluate(writeTool), PolicyDecision.needsConfirmation);
      expect(p.evaluate(destroyTool), PolicyDecision.needsConfirmation);
    });

    test('autoWrites: write allow, destructive STILL confirm', () {
      const p = ActionPolicy(mode: PolicyMode.autoWrites);
      expect(p.evaluate(writeTool), PolicyDecision.allow);
      expect(p.evaluate(destroyTool), PolicyDecision.needsConfirmation);
    });

    test('readOnly: write and destructive are denied', () {
      const p = ActionPolicy(mode: PolicyMode.readOnly);
      expect(p.evaluate(readTool), PolicyDecision.allow);
      expect(p.evaluate(writeTool), PolicyDecision.deny);
      expect(p.evaluate(destroyTool), PolicyDecision.deny);
    });

    test('destructive is never auto-allowed in any mode', () {
      for (final mode in PolicyMode.values) {
        final d = ActionPolicy(mode: mode).evaluate(destroyTool);
        expect(d, isNot(PolicyDecision.allow),
            reason: 'destructive must never auto-allow in $mode');
      }
    });
  });

  group('ToolExecutor with a policy', () {
    _FakeTool read() => _FakeTool('read', ToolRisk.readOnly);
    _FakeTool write() => _FakeTool('write', ToolRisk.write);
    _FakeTool destroy() => _FakeTool('destroy', ToolRisk.destructive);

    test('read-only runs without confirmation', () async {
      final tool = read();
      final exec = ToolExecutor(ToolRegistry([tool]),
          policy: const ActionPolicy(), confirm: denyByDefaultConfirmation);
      final r = await exec.execute('read', {});
      expect(r.success, isTrue);
      expect(tool.executed, 1);
    });

    test('write is blocked when confirmation is denied', () async {
      final tool = write();
      final exec = ToolExecutor(ToolRegistry([tool]),
          policy: const ActionPolicy(), confirm: denyByDefaultConfirmation);
      final r = await exec.execute('write', {});
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codePermissionDenied);
      expect(tool.executed, 0, reason: 'must not run without approval');
    });

    test('write runs when confirmation is approved', () async {
      final tool = write();
      final exec = ToolExecutor(ToolRegistry([tool]),
          policy: const ActionPolicy(), confirm: approveAllConfirmation);
      final r = await exec.execute('write', {});
      expect(r.success, isTrue);
      expect(tool.executed, 1);
    });

    test('policy with no handler defaults to deny for writes', () async {
      final tool = write();
      // No confirm handler supplied.
      final exec =
          ToolExecutor(ToolRegistry([tool]), policy: const ActionPolicy());
      final r = await exec.execute('write', {});
      expect(r.errorCode, ToolResult.codePermissionDenied);
      expect(tool.executed, 0);
    });

    test('destructive is denied even with autoWrites unless approved', () async {
      final tool = destroy();
      final exec = ToolExecutor(ToolRegistry([tool]),
          policy: const ActionPolicy(mode: PolicyMode.autoWrites),
          confirm: denyByDefaultConfirmation);
      final r = await exec.execute('destroy', {});
      expect(r.errorCode, ToolResult.codePermissionDenied);
      expect(tool.executed, 0);
    });

    test('readOnly mode denies a write outright', () async {
      final tool = write();
      final exec = ToolExecutor(ToolRegistry([tool]),
          policy: const ActionPolicy(mode: PolicyMode.readOnly));
      final r = await exec.execute('write', {});
      expect(r.errorCode, ToolResult.codePermissionDenied);
    });

    test('confirmation request carries tool + args + a summary', () async {
      final tool = write();
      ConfirmationRequest? seen;
      final exec = ToolExecutor(
        ToolRegistry([tool]),
        policy: const ActionPolicy(),
        confirm: (req) async {
          seen = req;
          return true;
        },
        summarizer: (t, a) => 'Create "${a['title']}"',
      );
      await exec.execute('write', {'title': 'X'});
      expect(seen, isNotNull);
      expect(seen!.toolName, 'write');
      expect(seen!.risk, ToolRisk.write);
      expect(seen!.summary, 'Create "X"');
      expect(seen!.arguments['title'], 'X');
    });

    test('no policy preserves the old allow-all behavior', () async {
      final tool = write();
      final exec = ToolExecutor(ToolRegistry([tool])); // no policy
      final r = await exec.execute('write', {});
      expect(r.success, isTrue);
      expect(tool.executed, 1);
    });
  });
}
