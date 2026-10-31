import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/core/ai_tool_call.dart';
import 'package:my_time_manager/ai/policy/action_policy.dart';
import 'package:my_time_manager/ai/policy/confirmation.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_args.dart';
import 'package:my_time_manager/ai/tools/tool_executor.dart';
import 'package:my_time_manager/ai/tools/tool_registry.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';

/// A trivial tool used to exercise the registry/executor/args plumbing.
class _EchoTool extends Tool {
  const _EchoTool();
  @override
  String get name => 'echo';
  @override
  String get description => 'Echo a message back.';
  @override
  ToolRisk get risk => ToolRisk.readOnly;
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'message': {'type': 'string'}
        },
        'required': ['message'],
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async {
    try {
      final args = ToolArgs(arguments);
      return ToolResult.ok({'echo': args.requireString('message')});
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }
}

class _ThrowingTool extends Tool {
  const _ThrowingTool();
  @override
  String get name => 'boom';
  @override
  String get description => 'Always throws.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async =>
      throw StateError('kaboom');
}

class _DescribedWriteTool extends Tool implements ConfirmationDescriber {
  const _DescribedWriteTool();
  @override
  String get name => 'described';
  @override
  String get description => 'A write tool with its own summary.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  String confirmationSummary(Map<String, dynamic> a) => 'Do "${a['x']}".';
  @override
  Future<ToolResult> execute(Map<String, dynamic> arguments) async =>
      const ToolResult.ok(null);
}

void main() {
  group('ConfirmationDescriber', () {
    test('executor uses the tool summary when no summarizer is given',
        () async {
      ConfirmationRequest? seen;
      final exec = ToolExecutor(
        ToolRegistry([const _DescribedWriteTool(), const _ThrowingTool()]),
        policy: const ActionPolicy(),
        confirm: (r) async {
          seen = r;
          return false;
        },
      );
      await exec.execute('described', {'x': 'it'});
      expect(seen!.summary, 'Do "it".');
      await exec.execute('boom', {});
      expect(seen!.summary, 'Run "boom" (write).');
    });

    test('an explicit summarizer still wins', () async {
      ConfirmationRequest? seen;
      final exec = ToolExecutor(
        ToolRegistry([const _DescribedWriteTool()]),
        policy: const ActionPolicy(),
        confirm: (r) async {
          seen = r;
          return false;
        },
        summarizer: (t, a) => 'custom',
      );
      await exec.execute('described', {'x': 'it'});
      expect(seen!.summary, 'custom');
    });
  });

  group('ToolResult', () {
    test('ok serializes data', () {
      expect(const ToolResult.ok({'a': 1}).toJson(),
          {'success': true, 'data': {'a': 1}});
    });
    test('failure serializes code + message', () {
      final json = const ToolResult.failure('x', 'msg').toJson();
      expect(json['success'], false);
      expect((json['error'] as Map)['code'], 'x');
    });
  });

  group('ToolArgs', () {
    test('requireString rejects missing/blank/non-string', () {
      expect(() => const ToolArgs({}).requireString('k'),
          throwsA(isA<ToolArgumentError>()));
      expect(() => const ToolArgs({'k': '  '}).requireString('k'),
          throwsA(isA<ToolArgumentError>()));
      expect(() => const ToolArgs({'k': 5}).requireString('k'),
          throwsA(isA<ToolArgumentError>()));
      expect(const ToolArgs({'k': 'v'}).requireString('k'), 'v');
    });
    test('optInt accepts num and null', () {
      expect(const ToolArgs({'n': 3}).optInt('n'), 3);
      expect(const ToolArgs({'n': 3.0}).optInt('n'), 3);
      expect(const ToolArgs({}).optInt('n'), isNull);
    });
    test('optDateTime parses ISO and rejects garbage', () {
      expect(const ToolArgs({'d': '2026-03-01'}).optDateTime('d'),
          DateTime.parse('2026-03-01'));
      expect(() => const ToolArgs({'d': 'nope'}).optDateTime('d'),
          throwsA(isA<ToolArgumentError>()));
      expect(const ToolArgs({}).optDateTime('d'), isNull);
    });
    test('requireDouble accepts int and double', () {
      expect(const ToolArgs({'x': 2}).requireDouble('x'), 2.0);
      expect(const ToolArgs({'x': 2.5}).requireDouble('x'), 2.5);
    });
  });

  group('ToolRegistry', () {
    test('registers, looks up, exposes definitions', () {
      final reg = ToolRegistry([const _EchoTool()]);
      expect(reg.contains('echo'), isTrue);
      expect(reg.lookup('echo'), isNotNull);
      expect(reg.definitions.single.name, 'echo');
      expect(reg.definitions.single.parametersSchema['required'], ['message']);
    });
    test('rejects duplicate names', () {
      final reg = ToolRegistry([const _EchoTool()]);
      expect(() => reg.register(const _EchoTool()), throwsStateError);
    });
  });

  group('ToolExecutor', () {
    test('executes a known tool', () async {
      final exec = ToolExecutor(ToolRegistry([const _EchoTool()]));
      final r = await exec.execute('echo', {'message': 'hi'});
      expect(r.success, isTrue);
      expect((r.data as Map)['echo'], 'hi');
    });

    test('unknown tool -> unknown_tool failure', () async {
      final exec = ToolExecutor(ToolRegistry([const _EchoTool()]));
      final r = await exec.execute('nope', {});
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codeUnknownTool);
    });

    test('invalid arguments -> invalid_arguments failure (tool-level)', () async {
      final exec = ToolExecutor(ToolRegistry([const _EchoTool()]));
      final r = await exec.execute('echo', {});
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codeInvalidArguments);
    });

    test('a throwing tool is contained as a domain_error failure', () async {
      final exec = ToolExecutor(ToolRegistry([const _ThrowingTool()]));
      final r = await exec.execute('boom', {});
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codeDomainError);
    });

    test('executeCall rejects malformed tool-call arguments', () async {
      final exec = ToolExecutor(ToolRegistry([const _EchoTool()]));
      final call = AiToolCall.fromRawArguments(
        id: 'c1',
        name: 'echo',
        rawArguments: '{bad json',
      );
      final r = await exec.executeCall(call);
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codeInvalidArguments);
    });

    test('permission check can deny a call', () async {
      final exec = ToolExecutor(
        ToolRegistry([const _EchoTool()]),
        permissionCheck: (tool, args) =>
            tool.risk == ToolRisk.readOnly ? 'blocked' : null,
      );
      final r = await exec.execute('echo', {'message': 'hi'});
      expect(r.success, isFalse);
      expect(r.errorCode, ToolResult.codePermissionDenied);
    });
  });
}
