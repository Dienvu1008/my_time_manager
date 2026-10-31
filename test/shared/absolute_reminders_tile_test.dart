import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/shared/absolute_reminders_tile.dart';

import 'test_harness.dart';

void main() {
  late List<List<WallClock>> payloads;

  Future<void> pump(WidgetTester tester,
      {List<WallClock> initial = const []}) async {
    payloads = [];
    await tester.pumpWidget(testApp(
      const [],
      Scaffold(
        body: AbsoluteRemindersTile(initial: initial, onChanged: payloads.add),
      ),
    ));
    await tester.pumpAndSettle(); // AppLocalizations nạp bất đồng bộ
  }

  testWidgets('adds a time via the date and time pickers', (tester) async {
    await pump(tester);
    expect(find.text('At a specific time…'), findsOneWidget);
    expect(find.byTooltip('Delete reminder'), findsNothing);

    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // date picker: keep today
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // time picker: keep now
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(payloads, hasLength(1));
    final added = payloads.single.single;
    expect((added.year, added.month, added.day), (now.year, now.month, now.day));
    expect(find.byTooltip('Delete reminder'), findsOneWidget);
  });

  testWidgets('cancelling the date picker adds nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(payloads, isEmpty);
  });

  testWidgets('removes a time', (tester) async {
    await pump(tester, initial: const [
      WallClock(2026, 6, 2, 9, 30),
      WallClock(2026, 6, 1, 8, 0),
    ]);
    expect(find.byTooltip('Delete reminder'), findsNWidgets(2));
    // Đã sắp xếp: 1/6 trước 2/6 → xóa dòng đầu = 2026-06-01 08:00.
    await tester.tap(find.byTooltip('Delete reminder').first);
    await tester.pumpAndSettle();
    expect(payloads.single, const [WallClock(2026, 6, 2, 9, 30)]);
    expect(find.byTooltip('Delete reminder'), findsOneWidget);
  });
}
