import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Plan D12: lib/domain và lib/application không được phụ thuộc plugin thông
/// báo / timezone thiết bị hay NotificationService.
void main() {
  test('domain and application layers do not import notification adapters',
      () {
    final directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true);
    bool banned(String uri) =>
        uri.startsWith('package:flutter_local_notifications') ||
        uri.startsWith('package:flutter_timezone') ||
        uri.contains('notification_service.dart') ||
        uri.contains('data/notifications/');

    var scanned = 0;
    final offenders = <String>[];
    for (final root in ['lib/domain', 'lib/application']) {
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
