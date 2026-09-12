import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/agent/text_tool_call_parser.dart';

void main() {
  const known = {'create_calendar_event', 'list_tasks', 'create_task'};
  const parser = TextToolCallParser(known);

  test('parses a bare {name, arguments} JSON object', () {
    final calls = parser.parse(
      '{"name": "create_calendar_event", "arguments": {"title": "ML Class"}}',
    );
    expect(calls, hasLength(1));
    expect(calls.single.name, 'create_calendar_event');
    expect(calls.single.arguments['title'], 'ML Class');
  });

  test('parses JSON inside a ```json fenced block with surrounding prose', () {
    final calls = parser.parse('''
Sure, I'll add that.
```json
{"name": "create_task", "arguments": {"title": "Study"}}
```
Done!''');
    expect(calls.single.name, 'create_task');
    expect(calls.single.arguments['title'], 'Study');
  });

  test('parses a JSON object embedded in prose (no fence)', () {
    final calls = parser.parse(
      'I will call {"name": "list_tasks", "arguments": {}} now.',
    );
    expect(calls.single.name, 'list_tasks');
  });

  test('accepts the function-style {function:{name,arguments}} shape', () {
    final calls = parser.parse(
      '{"function": {"name": "list_tasks", "arguments": {"onlyIncomplete": true}}}',
    );
    expect(calls.single.name, 'list_tasks');
    expect(calls.single.arguments['onlyIncomplete'], true);
  });

  test('parses arguments given as a JSON string', () {
    final calls = parser.parse(
      '{"name": "create_task", "arguments": "{\\"title\\":\\"X\\"}"}',
    );
    expect(calls.single.arguments['title'], 'X');
  });

  test('parses a tool_calls array wrapper', () {
    final calls = parser.parse(
      '{"tool_calls": [{"name": "list_tasks", "arguments": {}}, '
      '{"name": "create_task", "arguments": {"title": "A"}}]}',
    );
    expect(calls.map((c) => c.name), ['list_tasks', 'create_task']);
  });

  test('ignores JSON whose name is not a known tool', () {
    final calls = parser.parse('{"name": "not_a_tool", "arguments": {}}');
    expect(calls, isEmpty);
  });

  test('ignores plain prose with no JSON', () {
    expect(parser.parse('You have 3 tasks today.'), isEmpty);
  });

  test('ignores non-object JSON (e.g. a number)', () {
    expect(parser.parse('42'), isEmpty);
  });

  test('empty text yields no calls', () {
    expect(parser.parse('   '), isEmpty);
  });
}
