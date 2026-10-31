import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/screen_settings/reminder_settings_card.dart';

import '../shared/test_harness.dart';

void main() {
  late List<String> calls;

  Future<void> pump(WidgetTester tester,
      {bool reminders = true,
      bool coordinator = true,
      bool quiet = false}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    calls = [];
    await tester.pumpWidget(testApp(
      const [],
      Scaffold(
        body: SingleChildScrollView(
          child: ReminderSettingsPanel(
            remindersEnabled: reminders,
            coordinatorEnabled: coordinator,
            quietEnabled: quiet,
            quietStartMinutes: 1320,
            quietEndMinutes: 420,
            onRemindersChanged: (v) => calls.add('reminders:$v'),
            onCoordinatorChanged: (v) => calls.add('coordinator:$v'),
            onQuietHoursChanged: (e, s, en) => calls.add('quiet:$e:$s:$en'),
            onOpenUpcoming: () => calls.add('open'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle(); // AppLocalizations nạp bất đồng bộ
  }

  ListTile tile(WidgetTester tester, String title) =>
      tester.widget<ListTile>(find.widgetWithText(ListTile, title));

  testWidgets('keeps the existing reminders switch text', (tester) async {
    await pump(tester);
    expect(find.text('Nhắc'), findsOneWidget);
    expect(find.text('Bật nhắc bằng thông báo'), findsOneWidget);
    await tester.tap(find.text('Bật nhắc bằng thông báo'));
    expect(calls, ['reminders:false']);
  });

  testWidgets('toggles invoke callbacks', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Quiet hours'));
    await tester.tap(find.text('Smart reminder scheduling'));
    await tester.tap(find.text('Upcoming reminders'));
    expect(calls, ['quiet:true:1320:420', 'coordinator:false', 'open']);
  });

  testWidgets('time tiles are disabled when quiet hours are off',
      (tester) async {
    await pump(tester);
    expect(tile(tester, 'Starts').enabled, isFalse);
    expect(tile(tester, 'Ends').enabled, isFalse);
    await tester.tap(find.text('Starts'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('time tiles open a picker when quiet hours are on',
      (tester) async {
    await pump(tester, quiet: true);
    expect(tile(tester, 'Starts').enabled, isTrue);
    expect(find.text('10:00 PM'), findsOneWidget);
    expect(find.text('7:00 AM'), findsOneWidget);
    await tester.tap(find.text('Ends'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(calls, ['quiet:true:1320:420']);
  });

  testWidgets('legacy mode shows the classic-mode note', (tester) async {
    await pump(tester, coordinator: false);
    expect(
        find.text('Classic mode: only time-interval reminders are scheduled.'),
        findsOneWidget);
  });
}
