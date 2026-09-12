import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/todo_list_screen.dart';

void main() {
  testWidgets('adds a todo item', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TodoListScreen()));

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));

    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('removes a todo item', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TodoListScreen()));

    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.byIcon(Icons.add));

    await tester.tap(find.byIcon(Icons.delete));

    expect(find.text('Buy milk'), findsNothing);
  });
}
