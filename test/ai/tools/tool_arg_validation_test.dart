@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/tools/tool.dart';
import 'package:my_time_manager/ai/tools/tool_result.dart';

import '../support/ai_test_env.dart';

/// Phase C8b: registry-wide, table-driven argument validation. Every tool
/// (old and new) must turn missing / wrong-typed / out-of-range arguments and
/// unknown ids into an error [ToolResult] — never throw into the agent loop.
/// Calls go to `tool.execute` directly (no executor safety net).
void main() {
  setUpAll(initAiTestFfi);

  late AiTestEnv env;
  setUp(() async => env = await AiTestEnv.create());

  Map<String, dynamic> props(Tool t) => Map<String, dynamic>.from(
      (t.parametersSchema['properties'] as Map?) ?? const {});
  List<String> required(Tool t) =>
      ((t.parametersSchema['required'] as List?) ?? const []).cast<String>();

  Object garbageFor(Object? schema) {
    final type = schema is Map ? schema['type'] : null;
    return switch (type) {
      'string' => 12345,
      'integer' || 'number' => 'NaN',
      'boolean' => 'yes',
      'array' || 'object' => 'x',
      _ => 12345,
    };
  }

  Future<ToolResult> run(Tool t, Map<String, dynamic> args) async {
    try {
      return await t.execute(args);
    } catch (e) {
      fail('${t.name} threw for $args: $e');
    }
  }

  // Each check iterates the whole registry and reports every offender at once.
  test('registry exposes the full tool set', () async {
    expect(env.registry.tools.length, greaterThanOrEqualTo(40));
  });

  test('every tool rejects {} when it has required args', () async {
    final problems = <String>[];
    for (final t in env.registry.tools) {
      final r = await run(t, {});
      if (required(t).isNotEmpty &&
          (r.success || r.errorCode != ToolResult.codeInvalidArguments)) {
        problems.add('${t.name}: $r');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every tool rejects garbage-typed args', () async {
    final problems = <String>[];
    for (final t in env.registry.tools) {
      final p = props(t);
      if (p.isEmpty) continue;
      final args = {for (final e in p.entries) e.key: garbageFor(e.value)};
      final r = await run(t, args);
      if (r.success || r.errorCode != ToolResult.codeInvalidArguments) {
        problems.add('${t.name}: $r');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every id-taking tool reports unknown ids as an error', () async {
    final problems = <String>[];
    var checked = 0;
    for (final t in env.registry.tools) {
      final req = required(t);
      if (!req.any((k) => k == 'id' || k.endsWith('Id'))) continue;
      checked++;
      final p = props(t);
      final args = <String, dynamic>{
        for (final k in req)
          k: switch ((p[k] as Map?)?['type']) {
            'integer' || 'number' => 5,
            'boolean' => true,
            _ => 'missing-id-0000',
          },
      };
      final r = await run(t, args);
      if (r.success ||
          !{ToolResult.codeNotFound, ToolResult.codeInvalidArguments}
              .contains(r.errorCode)) {
        problems.add('${t.name}: $r');
      }
    }
    expect(checked, greaterThan(10));
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  group('out-of-range values are invalid_arguments', () {
    final cases = <String, Map<String, dynamic>>{
      'list_focus_sessions limit -1': {
        'tool': 'list_focus_sessions',
        'limit': -1
      },
      'get_focus_statistics days 0': {
        'tool': 'get_focus_statistics',
        'days': 0
      },
      'get_focus_statistics days 100000': {
        'tool': 'get_focus_statistics',
        'days': 100000
      },
      'get_focus_summary days -3': {'tool': 'get_focus_summary', 'days': -3},
      'get_productivity_summary days -3': {
        'tool': 'get_productivity_summary',
        'days': -3
      },
      'get_productivity_metrics days -3': {
        'tool': 'get_productivity_metrics',
        'days': -3
      },
      'get_productivity_metrics availableMinutes -1': {
        'tool': 'get_productivity_metrics',
        'availableMinutes': -1
      },
      'add_interval_reminder minutesBefore -1': {
        'tool': 'add_interval_reminder',
        'timeIntervalId': 'x',
        'minutesBefore': -1
      },
      'list_upcoming_reminders withinDays 0': {
        'tool': 'list_upcoming_reminders',
        'withinDays': 0
      },
      'create_time_interval bad time': {
        'tool': 'create_time_interval',
        'startDate': '2026-01-01',
        'startTime': '25:00',
        'endTime': '26:00'
      },
      'create_calendar_event end before start': {
        'tool': 'create_calendar_event',
        'title': 'Meeting',
        'start': '2026-01-01T10:00:00',
        'end': '2026-01-01T09:00:00'
      },
    };
    for (final c in cases.entries) {
      test(c.key, () async {
        final args = Map<String, dynamic>.from(c.value);
        final name = args.remove('tool') as String;
        final tool = env.registry.lookup(name);
        expect(tool, isNotNull, reason: 'missing tool $name');
        final r = await run(tool!, args);
        expect(r.success, isFalse, reason: '$r');
        expect(r.errorCode, ToolResult.codeInvalidArguments, reason: '$r');
      });
    }
  });
}
