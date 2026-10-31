@TestOn('vm')
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_reminder_rule_repository.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of the Phase R table reminder_rules
/// (update-first import, no REPLACE).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  final rules = SqliteReminderRuleRepository();

  test('export contains reminder_rules', () async {
    await rules.saveRule(ReminderRule.offset(
        entityType: ReminderEntityType.task, entityId: 't1', minutes: 5));

    final (json, _) = await BackupService().buildContent(ExportFormat.json);
    final data = (jsonDecode(json) as Map)['data'] as Map;
    expect((data['reminder_rules'] as List), hasLength(1));
  });

  test('keepIncoming import overwrites a locally edited rule', () async {
    final r = ReminderRule.offset(
        entityType: ReminderEntityType.task, entityId: 't1', minutes: 5);
    await rules.saveRule(r);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await rules.saveRule(r.copyWith(offsetMinutes: 99, enabled: false));

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final all = await rules.getAllRules();
    expect(all, hasLength(1));
    expect(all.single.offsetMinutes, 5);
    expect(all.single.enabled, isTrue);
  });

  test('import into a fresh DB restores the rule', () async {
    final r = ReminderRule.absolute(
      entityType: ReminderEntityType.task,
      entityId: 't1',
      at: const WallClock(2026, 6, 7, 18, 30),
      priority: ReminderPriority.high,
      enabled: false,
    );
    await rules.saveRule(r);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await rules.getRule(r.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);

    final back = await rules.getRule(r.id);
    expect(back, isNotNull);
    expect(back!.kind, ReminderRuleKind.absolute);
    expect(back.absoluteAt, const WallClock(2026, 6, 7, 18, 30));
    expect(back.priority, ReminderPriority.high);
    expect(back.enabled, isFalse);
  });
}
