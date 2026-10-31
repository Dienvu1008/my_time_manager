import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_ai_action_log.dart';
import 'package:my_time_manager/domain/repositories/ai_action_log_repository.dart';
import 'package:my_time_manager/screen_ai/ai_action_log_screen.dart';

import '../shared/test_harness.dart';

/// List-backed [AiActionLogRepository] for widget tests.
class _FakeLog implements AiActionLogRepository {
  _FakeLog(this.entries);
  final List<AiActionLogEntry> entries;
  int clearCalls = 0;

  @override
  Future<void> record(AiActionLogEntry entry) async => entries.add(entry);

  @override
  Future<List<AiActionLogEntry>> getEntries(
          {AiActionOutcome? outcome, int limit = 500}) async =>
      (entries.where((e) => outcome == null || e.outcome == outcome).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(limit)
          .toList();

  @override
  Future<AiActionLogEntry?> getEntry(String id) async =>
      entries.where((e) => e.id == id).firstOrNull;

  @override
  Future<int> clear() async {
    clearCalls++;
    final n = entries.length;
    entries.clear();
    return n;
  }

  @override
  Future<int> purge(
          {required DateTime now,
          int maxEntries = AiActionLogRetention.maxEntries,
          Duration maxAge = AiActionLogRetention.maxAge}) async =>
      0;
}

AiActionLogEntry _e(String tool, AiActionOutcome outcome, int hour,
        {String args = '{}'}) =>
    AiActionLogEntry(
      createdAt: DateTime(2026, 3, 2, hour),
      toolName: tool,
      policyLevel: 'write',
      policyMode: 'confirmWrites',
      argsSummary: args,
      outcome: outcome,
    );

void main() {
  Future<_FakeLog> open(WidgetTester tester, List<AiActionLogEntry> e) async {
    final log = _FakeLog(e);
    await tester.pumpWidget(testApp(
      [RepositoryProvider<AiActionLogRepository>.value(value: log)],
      launcher(const AiActionLogScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return log;
  }

  testWidgets('lists entries newest first', (tester) async {
    await open(tester, [
      _e('create_goal', AiActionOutcome.executed, 9),
      _e('trash_goal', AiActionOutcome.declined, 11),
    ]);
    expect(find.text('AI activity log'), findsOneWidget);
    final newer = tester.getTopLeft(find.text('trash_goal'));
    final older = tester.getTopLeft(find.text('create_goal'));
    expect(newer.dy, lessThan(older.dy));
    expect(find.text('Declined · 2026-03-02 11:00'), findsOneWidget);
    expect(find.bySemanticsLabel('Executed'), findsOneWidget);
  });

  testWidgets('outcome filter shows only matching entries', (tester) async {
    await open(tester, [
      _e('create_goal', AiActionOutcome.executed, 9),
      _e('trash_goal', AiActionOutcome.declined, 11),
    ]);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Declined'));
    await tester.pumpAndSettle();
    expect(find.text('trash_goal'), findsOneWidget);
    expect(find.text('create_goal'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('create_goal'), findsOneWidget);
  });

  testWidgets('empty state', (tester) async {
    await open(tester, []);
    expect(find.text('No AI actions recorded yet.'), findsOneWidget);
  });

  testWidgets('clear asks first: Cancel keeps, Delete empties', (tester) async {
    final log =
        await open(tester, [_e('create_goal', AiActionOutcome.executed, 9)]);

    await tester.tap(find.byTooltip('Clear log'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all entries from the AI activity log?'),
        findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(log.clearCalls, 0);
    expect(find.text('create_goal'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear log'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(log.clearCalls, 1);
    expect(find.text('No AI actions recorded yet.'), findsOneWidget);
  });

  testWidgets('tapping an entry shows its details', (tester) async {
    await open(tester, [
      _e('create_goal', AiActionOutcome.executed, 9,
          args: '{title: Learn Spanish}'),
    ]);
    await tester.tap(find.text('create_goal'));
    await tester.pumpAndSettle();
    expect(find.text('Arguments'), findsOneWidget);
    expect(find.text('{title: Learn Spanish}'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Arguments'), findsNothing);
  });
}
