import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/tools/domain/tool_views.dart';

String _doc(List<Object> children) => jsonEncode({
      'document': {'type': 'page', 'children': children},
    });

Map<String, dynamic> _para(String text, [List<Object> children = const []]) => {
      'type': 'paragraph',
      'data': {
        'delta': [
          {'insert': text}
        ]
      },
      if (children.isNotEmpty) 'children': children,
    };

void main() {
  group('untrusted', () {
    test('wraps text with the untrusted marker', () {
      expect(ToolViews.untrusted('hello'), {'untrusted': true, 'text': 'hello'});
    });

    test('blank text → null (field omitted)', () {
      expect(ToolViews.untrusted(''), isNull);
      expect(ToolViews.untrusted('   '), isNull);
    });

    test('truncates to maxLength and flags it', () {
      final r = ToolViews.untrusted('abcdefghij', maxLength: 4)!;
      expect(r['text'], 'abcd');
      expect(r['truncated'], isTrue);
      expect(ToolViews.untrusted('abc', maxLength: 4)!.containsKey('truncated'),
          isFalse);
    });
  });

  group('plainTextOfDoc', () {
    test('extracts delta inserts of nested nodes, joined by newlines', () {
      final json = _doc([
        {
          'type': 'paragraph',
          'data': {
            'delta': [
              {'insert': 'Hello '},
              {
                'insert': 'world',
                'attributes': {'bold': true}
              },
            ]
          },
        },
        _para('Parent', [_para('Child')]),
      ]);
      expect(ToolViews.plainTextOfDoc(json), 'Hello world\nParent\nChild');
    });

    test('invalid JSON → raw string trimmed', () {
      expect(ToolViews.plainTextOfDoc('  just text  '), 'just text');
    });

    test('non-document JSON → raw string', () {
      expect(ToolViews.plainTextOfDoc('{"a":1}'), '{"a":1}');
    });

    test('empty → empty', () {
      expect(ToolViews.plainTextOfDoc(''), '');
    });
  });

  group('snippet', () {
    test('starts up to 60 chars before the match and caps at 300', () {
      final text = '${'x' * 100}NEEDLE${'y' * 500}';
      final s = ToolViews.snippet(text, 'needle')!;
      expect(s['untrusted'], isTrue);
      final t = s['text'] as String;
      expect(t.length, ToolViews.snippetLength);
      expect(t.startsWith('x' * 60 + 'NEEDLE'), isTrue);
      expect(s['truncated'], isTrue);
    });

    test('no match → from start; short text not truncated', () {
      final s = ToolViews.snippet('short body', 'zzz')!;
      expect(s['text'], 'short body');
      expect(s.containsKey('truncated'), isFalse);
    });

    test('blank → null', () {
      expect(ToolViews.snippet('', 'q'), isNull);
    });
  });
}
