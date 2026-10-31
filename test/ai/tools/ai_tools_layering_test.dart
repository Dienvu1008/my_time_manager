import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// C8a: the AI tool and context layers reach data ONLY through domain
/// repositories/services — never lib/data, sqflite or DatabaseManager.
void main() {
  test('lib/ai/tools and lib/ai/context do not import the data layer', () {
    final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true);
    bool banned(String uri) =>
        uri.startsWith('package:sqflite') ||
        uri.startsWith('package:my_time_manager/data/') ||
        uri.contains('/data/') ||
        uri.startsWith('data/') ||
        uri.contains('database_manager');

    var scanned = 0;
    final offenders = <String>[];
    for (final root in ['lib/ai/tools', 'lib/ai/context']) {
      final dir = Directory(root);
      expect(dir.existsSync(), isTrue, reason: '$root not found');
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        scanned++;
        final source = entity.readAsStringSync();
        for (final m in directive.allMatches(source)) {
          final uri = m.group(1)!;
          if (banned(uri)) offenders.add('${entity.path}: $uri');
        }
      }
    }
    expect(scanned, greaterThan(0));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
