import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/shared/color_choice_field.dart';
import 'package:my_time_manager/shared/date_field.dart';
import 'package:my_time_manager/shared/entity_picker.dart';
import 'package:my_time_manager/shared/entity_picker_sources.dart';

import 'fake_repositories.dart';
import 'test_harness.dart';

const _entries = [
  PickerEntry(id: 'a', title: 'Alpha', icon: Icons.flag_outlined),
  PickerEntry(
      id: 'b', title: 'Beta', subtitle: 'sub b', icon: Icons.flag_outlined),
  PickerEntry(id: 'c', title: 'Gamma', icon: Icons.flag_outlined),
];

Future<void> _openPicker(WidgetTester tester, Widget picker,
    {ValueNotifier<Object?>? result}) async {
  await tester.pumpWidget(testApp(const [], launcher(picker, result: result)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('EntityPickerScreen', () {
    testWidgets('lists entries minus excludeIds', (tester) async {
      await _openPicker(
          tester,
          EntityPickerScreen(
              title: 'Pick', load: () async => _entries, excludeIds: {'b'}));
      expect(find.text('Pick'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('search filters case-insensitively', (tester) async {
      await _openPicker(
          tester, EntityPickerScreen(title: 'Pick', load: () async => _entries));
      expect(find.text('sub b'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'gAm');
      await tester.pumpAndSettle();
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('tapping an entry pops it', (tester) async {
      final result = ValueNotifier<Object?>(null);
      await _openPicker(
          tester, EntityPickerScreen(title: 'Pick', load: () async => _entries),
          result: result);
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(find.text('Pick'), findsNothing);
      expect((result.value as PickerEntry).id, 'b');
    });

    testWidgets('empty → Nothing to choose', (tester) async {
      await _openPicker(
          tester,
          EntityPickerScreen(
              title: 'Pick', load: () async => const <PickerEntry>[]));
      expect(find.text('Nothing to choose'), findsOneWidget);
    });

    testWidgets('entityLoader reads task lists from the repository',
        (tester) async {
      final lists = FakeTaskListRepository()
        ..visible.add(TaskList(id: 'l1', title: 'Inbox'));
      late Future<List<PickerEntry>> Function() load;
      await tester.pumpWidget(testApp(
        [RepositoryProvider<TaskListRepository>.value(value: lists)],
        Builder(builder: (context) {
          load = entityLoader(context, ProjectEntityType.taskList);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      final entries = await load();
      expect(entries.single.id, 'l1');
      expect(entries.single.title, 'Inbox');
      expect(entries.single.icon, Icons.folder_outlined);
    });
  });

  group('DateField', () {
    testWidgets('shows dd/MM/yyyy and Clear date calls onChanged(null)',
        (tester) async {
      DateTime? changed = DateTime(1999);
      await tester.pumpWidget(testApp(
        const [],
        Scaffold(
          body: DateField(
            label: 'Target date',
            value: DateTime(2026, 3, 5),
            onChanged: (d) => changed = d,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('05/03/2026'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pump();
      expect(changed, isNull);
    });

    testWidgets('no value → Not set and no clear button', (tester) async {
      await tester.pumpWidget(testApp(
        const [],
        Scaffold(
          body: DateField(label: 'Target date', onChanged: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
      expect(find.byTooltip('Clear date'), findsNothing);
    });
  });

  group('ColorChoiceField', () {
    testWidgets('tapping swatch 2 selects red', (tester) async {
      Color? picked;
      await tester.pumpWidget(testApp(
        const [],
        Scaffold(
          body: ColorChoiceField(
              value: Colors.white, onChanged: (c) => picked = c),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Color'), findsOneWidget);
      final swatch2 = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Color 2');
      await tester.tap(swatch2);
      await tester.pump();
      expect(picked, Colors.red);
    });
  });
}
