import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/listtile_alarm.dart';

import '../shared/test_harness.dart';

void main() {
  late List<List<int>> payloads;

  Future<void> pump(WidgetTester tester,
      {List<int>? initial, int? maxCount}) async {
    // Màn cao để bảng chọn mốc hiển thị đủ mọi dòng.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    payloads = [];
    await tester.pumpWidget(testApp(
      const [],
      Scaffold(
        body: SingleChildScrollView(
          child: AlarmListTile(
            initial: initial,
            maxCount: maxCount,
            onChanged: payloads.add,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle(); // AppLocalizations nạp bất đồng bộ
  }

  IconButton addButton(WidgetTester tester) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add));

  testWidgets('adds a preset from the picker', (tester) async {
    await pump(tester);
    expect(find.text('No reminders set'), findsOneWidget);
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Choose when to remind'), findsOneWidget);
    await tester.tap(find.text('15 minutes before'));
    await tester.pumpAndSettle();
    expect(payloads.last, [15]);
    // Hàng của mốc + phụ đề tiêu đề.
    expect(find.text('15 minutes before'), findsNWidgets(2));
  });

  testWidgets('adds a custom value', (tester) async {
    await pump(tester, initial: [10]);
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom (minutes before)...'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '45');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(payloads.last, [10, 45]);
  });

  testWidgets('tapping a row replaces that offset; duplicates ignored',
      (tester) async {
    await pump(tester, initial: [10, 60]);
    // Hàng "10 minutes before" (dense row, không phải phụ đề tiêu đề).
    await tester.tap(find.widgetWithText(ListTile, '10 minutes before').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit reminder'), findsOneWidget);
    await tester.tap(find.text('30 minutes before'));
    await tester.pumpAndSettle();
    expect(payloads.last, [30, 60]);

    // Chọn mốc đã có (1 hour) → bỏ qua (mục bị vô hiệu nên tap không có tác dụng).
    await tester.tap(find.widgetWithText(ListTile, '30 minutes before').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 hour before').last);
    await tester.pumpAndSettle();
    expect(payloads.length, 1);
  });

  testWidgets('delete via tooltip', (tester) async {
    await pump(tester, initial: [5, 1440]);
    expect(find.byTooltip('Delete reminder'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Delete reminder').first);
    await tester.pumpAndSettle();
    expect(payloads.last, [1440]);
    expect(find.byTooltip('Delete reminder'), findsOneWidget);
  });

  testWidgets('maxCount disables add', (tester) async {
    await pump(tester, initial: [5], maxCount: 2);
    expect(addButton(tester).onPressed, isNotNull);
    await tester.tap(find.byTooltip('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 day before'));
    await tester.pumpAndSettle();
    expect(payloads.last, [5, 1440]);
    expect(addButton(tester).onPressed, isNull);
    // Xóa một mốc → thêm được lại.
    await tester.tap(find.byTooltip('Delete reminder').first);
    await tester.pumpAndSettle();
    expect(addButton(tester).onPressed, isNotNull);
  });
}
