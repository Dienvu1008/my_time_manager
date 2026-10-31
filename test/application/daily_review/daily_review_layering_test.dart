import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase DR1: the Daily Review core is pure application code — no Flutter
/// (UI or foundation), no sqflite / data layer, no notification plugins, no
/// AI layer. Complements `test/application/reminder_layering_test.dart`.
void main() {
  test('lib/application/daily_review has no UI / persistence / plugin imports',
      () {
    final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true);
    bool banned(String uri) =>
        uri.startsWith('package:flutter/') ||
        uri.startsWith('package:sqflite') ||
        uri.startsWith('package:flutter_local_notifications') ||
        uri.startsWith('package:flutter_timezone') ||
        uri.startsWith('package:shared_preferences') ||
        uri.contains('notification_service.dart') ||
        uri.contains('/data/') ||
        uri.startsWith('../data') ||
        uri.contains('/ai/') ||
        uri.startsWith('../ai') ||
        uri.contains('screen_') ||
        uri.contains('/app/');

    final dir = Directory('lib/application/daily_review');
    expect(dir.existsSync(), isTrue);
    var scanned = 0;
    final offenders = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      scanned++;
      for (final m in directive.allMatches(entity.readAsStringSync())) {
        final uri = m.group(1)!;
        if (banned(uri)) offenders.add('${entity.path}: $uri');
      }
    }
    expect(scanned, greaterThanOrEqualTo(6));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
