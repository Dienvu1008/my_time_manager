import '../../application/reminders/reminder_ids.dart';
import '../../application/reminders/reminder_reconcile_trigger.dart';
import '../../domain/models/model_reminder_rule.dart';
import '../../domain/repositories/reminder_rule_repository.dart';
import '../database/daos/reminder_rule_dao.dart';
import '../database/database_manager.dart';

/// SQLite-backed [ReminderRuleRepository] (Phase R) over [ReminderRuleDao].
/// After every mutation it asks the injected [ReminderReconcileTrigger] to
/// reconcile, passing the ids of the old/deleted rules as `alsoCancel`.
class SqliteReminderRuleRepository implements ReminderRuleRepository {
  SqliteReminderRuleRepository({
    DatabaseManager? databaseManager,
    ReminderReconcileTrigger? reminderTrigger,
  })  : _dao = ReminderRuleDao(
            () => (databaseManager ?? DatabaseManager()).database),
        _trigger = reminderTrigger ?? const NoOpReminderReconcileTrigger();

  final ReminderRuleDao _dao;
  final ReminderReconcileTrigger _trigger;

  Future<void> _reconcile(Iterable<ReminderRule> oldRules) =>
      _trigger.requestReconcile(alsoCancel: {
        for (final r in oldRules) ...ruleCandidateIds(r),
      });

  @override
  Future<List<ReminderRule>> getAllRules() => _dao.getAll();

  @override
  Future<List<ReminderRule>> getRulesFor(String entityType, String entityId) =>
      _dao.getFor(entityType, entityId);

  @override
  Future<ReminderRule?> getRule(String id) => _dao.getById(id);

  @override
  Future<void> saveRule(ReminderRule rule) async {
    _validateRule(rule);
    final old = await _dao.getById(rule.id);
    await _dao.save(rule);
    await _reconcile([if (old != null) old]);
  }

  @override
  Future<void> deleteRule(String id) async {
    final old = await _dao.getById(id);
    await _dao.delete(id);
    await _reconcile([if (old != null) old]);
  }

  @override
  Future<void> replaceRulesFor(
    String entityType,
    String entityId,
    List<ReminderRule> rules, {
    required ReminderRuleKind kind,
  }) async {
    _validateEntity(entityType, entityId);
    for (final rule in rules) {
      _validateRule(rule);
      if (rule.entityType != entityType || rule.entityId != entityId) {
        throw ArgumentError.value(
            rule, 'rules', 'Rule does not belong to $entityType:$entityId');
      }
      if (rule.kind != kind) {
        throw ArgumentError.value(
            rule, 'rules', 'Rule kind must be ${kind.name}');
      }
    }
    final old = (await _dao.getFor(entityType, entityId))
        .where((r) => r.kind == kind)
        .toList();
    await _dao.replaceFor(entityType, entityId, kind, rules);
    await _reconcile(old);
  }

  static void _validateEntity(String entityType, String entityId) {
    if (entityType.trim().isEmpty) {
      throw ArgumentError.value(
          entityType, 'entityType', 'Entity type must not be empty');
    }
    if (entityId.trim().isEmpty) {
      throw ArgumentError.value(
          entityId, 'entityId', 'Entity id must not be empty');
    }
  }

  static void _validateRule(ReminderRule rule) {
    _validateEntity(rule.entityType, rule.entityId);
    switch (rule.kind) {
      case ReminderRuleKind.offset:
        final m = rule.offsetMinutes;
        if (m == null || m < 0) {
          throw ArgumentError.value(m, 'offsetMinutes',
              'Offset rules need offsetMinutes >= 0');
        }
      case ReminderRuleKind.absolute:
        if (rule.absoluteAt == null) {
          throw ArgumentError.value(
              null, 'absoluteAt', 'Absolute rules need absoluteAt');
        }
    }
  }
}
