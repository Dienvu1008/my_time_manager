import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_goal_link.dart';
import 'package:my_time_manager/domain/models/model_milestone.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/goal_repository.dart';
import 'package:my_time_manager/domain/repositories/learning_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';
import 'package:my_time_manager/screen_goals/goal_detail_screen.dart';
import 'package:my_time_manager/screen_goals/goal_form_screen.dart';
import 'package:my_time_manager/screen_goals/goals_list_screen.dart';

import '../screen_learning/fake_learning_repository.dart';
import '../shared/fake_repositories.dart';
import '../shared/test_harness.dart';

/// [FakeGoalRepository] whose goal writes throw.
class _FailingGoalRepository extends FakeGoalRepository {
  @override
  Future<void> createGoal(Goal goal) async => throw Exception('boom');
}

void main() {
  late FakeGoalRepository goals;
  late FakeTaskRepository tasks;
  late FakeLearningRepository learning;

  setUp(() {
    goals = FakeGoalRepository();
    tasks = FakeTaskRepository();
    learning = FakeLearningRepository();
  });

  Widget app(Widget home) => testApp([
        RepositoryProvider<GoalRepository>.value(value: goals),
        RepositoryProvider<TaskRepository>.value(value: tasks),
        RepositoryProvider<LearningRepository>.value(value: learning),
        RepositoryProvider<GoalProgressService>.value(
            value: GoalProgressService(goals, tasks)),
      ], home);

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Goal seedGoal(String title,
      {GoalStatus status = GoalStatus.active, DateTime? targetDate}) {
    final g = Goal(title: title, status: status, targetDate: targetDate);
    goals.goals[g.id] = g;
    return g;
  }

  Milestone seedMilestone(Goal g, String title, {int sortOrder = 0}) {
    final m = Milestone(goalId: g.id, title: title, sortOrder: sortOrder);
    goals.milestones[m.id] = m;
    return m;
  }

  group('GoalsListScreen', () {
    testWidgets('empty state and New goal FAB', (tester) async {
      await pump(tester, const GoalsListScreen());
      expect(find.text('No goals yet'), findsOneWidget);
      expect(find.text('Tap + to create your first goal.'), findsOneWidget);
      expect(find.byTooltip('New goal'), findsOneWidget);
    });

    testWidgets('seeded goal shows status, target date and derived percent',
        (tester) async {
      final g = seedGoal('Learn Dart', targetDate: DateTime(2030, 2, 1));
      tasks.visible.addAll([
        Task(id: 't1', title: 'Done', isCompleted: true),
        Task(id: 't2', title: 'Open'),
      ]);
      await goals.linkTask(g.id, 't1');
      await goals.linkTask(g.id, 't2');
      await pump(tester, const GoalsListScreen());
      expect(find.text('Learn Dart'), findsOneWidget);
      expect(find.text('Active · Target date: 01/02/2030'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('status filter chip hides non-matching goals', (tester) async {
      seedGoal('Active goal');
      seedGoal('Paused goal', status: GoalStatus.paused);
      await pump(tester, const GoalsListScreen());
      expect(find.text('Active goal'), findsOneWidget);
      expect(find.text('Paused goal'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
      await tester.pumpAndSettle();
      expect(find.text('Active goal'), findsNothing);
      expect(find.text('Paused goal'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Abandoned'));
      await tester.pumpAndSettle();
      expect(find.text('No goals with this status'), findsOneWidget);
    });
  });

  group('GoalFormScreen', () {
    testWidgets('creates a goal and pops true', (tester) async {
      await pump(tester, launcher(const GoalFormScreen()));
      await open(tester);
      expect(find.text('New goal'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Run a marathon');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(goals.goals.length, 1);
      expect(goals.goals.values.single.title, 'Run a marathon');
      expect(goals.goals.values.single.status, GoalStatus.active);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('save failure shows an error SnackBar and re-enables Save',
        (tester) async {
      goals = _FailingGoalRepository();
      await pump(tester, launcher(const GoalFormScreen()));
      await open(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Run a marathon');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: boom'), findsOneWidget);
      expect(find.text('New goal'), findsOneWidget); // still on the form
      expect(find.text('result: true'), findsNothing);
      final save = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.check));
      expect(save.onPressed, isNotNull);
    });

    testWidgets('empty title shows validation and creates nothing',
        (tester) async {
      await pump(tester, launcher(const GoalFormScreen()));
      await open(tester);
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsOneWidget);
      expect(goals.goals, isEmpty);
    });

    testWidgets('edit pre-fills, saves title/status and clears target date',
        (tester) async {
      final g = seedGoal('Old title', targetDate: DateTime(2030, 1, 15));
      await pump(tester, launcher(GoalFormScreen(goal: g)));
      await open(tester);
      expect(find.text('Edit goal'), findsOneWidget);
      expect(find.text('Old title'), findsOneWidget);
      expect(find.text('15/01/2030'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'New title');
      await tester.tap(find.byType(DropdownButtonFormField<GoalStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paused').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      final saved = goals.goals[g.id]!;
      expect(saved.title, 'New title');
      expect(saved.status, GoalStatus.paused);
      expect(saved.targetDate, isNull);
      expect(find.text('result: true'), findsOneWidget);
    });
  });

  group('GoalDetailScreen', () {
    testWidgets('renders header, milestones and direct links',
        (tester) async {
      final g = Goal(title: 'G', description: 'Goal description');
      goals.goals[g.id] = g;
      final m = seedMilestone(g, 'M1');
      tasks.visible.addAll([
        Task(id: 't1', title: 'Milestone task', isCompleted: true),
        Task(id: 't2', title: 'Direct task'),
      ]);
      final course = Course(title: 'Course X');
      learning.courses[course.id] = course;
      await goals.linkTask(g.id, 't1', milestoneId: m.id);
      await goals.linkTask(g.id, 't2');
      await goals.linkCourse(g.id, course.id);
      // Link to a non-live task is not rendered.
      await goals.linkTask(g.id, 'gone');

      await pump(tester, GoalDetailScreen(goalId: g.id));
      expect(find.text('Goal description'), findsOneWidget);
      expect(find.text('Milestones done: 1/1'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('M1'), findsOneWidget);
      expect(find.text('Tasks completed: 1/1 · 100%'), findsOneWidget);
      expect(find.text('Milestone task'), findsOneWidget);
      expect(find.text('Direct task'), findsOneWidget);
      expect(find.text('Course X'), findsOneWidget);
      expect(find.byTooltip('Unlink'), findsNWidgets(3));
    });

    testWidgets('adds a milestone via the dialog', (tester) async {
      final g = seedGoal('G');
      await pump(tester, GoalDetailScreen(goalId: g.id));
      expect(find.text('No milestones yet'), findsOneWidget);

      await tester.tap(find.text('Add milestone'));
      await tester.pumpAndSettle();
      expect(find.text('New milestone'), findsOneWidget);
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextFormField)),
          'First step');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final ms = await goals.getMilestones(g.id);
      expect(ms.single.title, 'First step');
      expect(ms.single.sortOrder, 0);
      expect(find.text('First step'), findsOneWidget);
    });

    testWidgets('new milestone after a gap gets max(sortOrder)+1 and is last',
        (tester) async {
      final g = seedGoal('G');
      // Gap left by a deleted milestone at sortOrder 0.
      seedMilestone(g, 'Beta', sortOrder: 1);
      seedMilestone(g, 'Gamma', sortOrder: 2);
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.text('Add milestone'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextFormField)),
          'Alpha');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      final ms = await goals.getMilestones(g.id);
      expect([for (final m in ms) m.title], ['Beta', 'Gamma', 'Alpha']);
      expect(ms.last.sortOrder, 3);
    });

    testWidgets('toggling the checkbox completes the milestone',
        (tester) async {
      final g = seedGoal('G');
      final m = seedMilestone(g, 'M1');
      await pump(tester, GoalDetailScreen(goalId: g.id));
      expect(find.text('Milestones done: 0/1'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(goals.milestones[m.id]!.isCompleted, isTrue);
      expect(find.text('Milestones done: 1/1'), findsOneWidget);
    });

    testWidgets('move down reorders milestones', (tester) async {
      final g = seedGoal('G');
      seedMilestone(g, 'Alpha', sortOrder: 0);
      seedMilestone(g, 'Beta', sortOrder: 1);
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.descendant(
          of: find.widgetWithText(Card, 'Alpha'),
          matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();
      expect(find.text('Move up'), findsNothing);
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();

      final ms = await goals.getMilestones(g.id);
      expect([for (final m in ms) m.title], ['Beta', 'Alpha']);
    });

    testWidgets('deleting a milestone after confirm makes its links direct',
        (tester) async {
      final g = seedGoal('G');
      final m = seedMilestone(g, 'M1');
      tasks.visible.add(Task(id: 't1', title: 'Task one'));
      final link = await goals.linkTask(g.id, 't1', milestoneId: m.id);
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.descendant(
          of: find.widgetWithText(Card, 'M1'),
          matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(
          find.text('Delete this milestone? Its linked items stay linked '
              'directly to the goal.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(goals.milestones, isEmpty);
      expect(goals.links[link.id]!.milestoneId, isNull);
      expect(find.text('Task one'), findsOneWidget);
    });

    testWidgets('link task: picker excludes linked, target milestone chosen',
        (tester) async {
      final g = seedGoal('G');
      final m = seedMilestone(g, 'M1');
      tasks.visible.addAll([
        Task(id: 't1', title: 'Already linked'),
        Task(id: 't2', title: 'Other task'),
      ]);
      await goals.linkTask(g.id, 't1');
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.text('Link task'));
      await tester.pumpAndSettle();
      expect(find.text('Already linked'), findsNothing);
      await tester.tap(find.text('Other task'));
      await tester.pumpAndSettle();

      expect(find.text('Link to'), findsOneWidget);
      expect(find.text('Directly to the goal'), findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byType(SimpleDialog), matching: find.text('M1')));
      await tester.pumpAndSettle();

      final link = (await goals.getLinksForEntity(GoalEntityType.task, 't2'))
          .single;
      expect(link.milestoneId, m.id);
      expect(find.text('Other task'), findsOneWidget);
    });

    testWidgets('dismissing the target dialog cancels the link',
        (tester) async {
      final g = seedGoal('G');
      seedMilestone(g, 'M1');
      tasks.visible.add(Task(id: 't2', title: 'Other task'));
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.text('Link task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other task'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(goals.links, isEmpty);
    });

    testWidgets('link task without milestones links directly', (tester) async {
      final g = seedGoal('G');
      tasks.visible.add(Task(id: 't2', title: 'Other task'));
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.text('Link task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other task'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsNothing);
      final link = goals.links.values.single;
      expect(link.entityId, 't2');
      expect(link.milestoneId, isNull);
    });

    testWidgets('link course links directly', (tester) async {
      final g = seedGoal('G');
      final course = Course(title: 'Course X');
      learning.courses[course.id] = course;
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.text('Link course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Course X'));
      await tester.pumpAndSettle();

      final link = goals.links.values.single;
      expect(link.entityType, GoalEntityType.course);
      expect(link.entityId, course.id);
      expect(link.milestoneId, isNull);
      expect(find.text('Course X'), findsOneWidget);
    });

    testWidgets('unlink after confirm removes the link, task remains',
        (tester) async {
      final g = seedGoal('G');
      tasks.visible.add(Task(id: 't1', title: 'Task one'));
      await goals.linkTask(g.id, 't1');
      await pump(tester, GoalDetailScreen(goalId: g.id));

      await tester.tap(find.byTooltip('Unlink'));
      await tester.pumpAndSettle();
      expect(find.text('Remove this link? The item itself is not deleted.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Unlink'));
      await tester.pumpAndSettle();

      expect(goals.links, isEmpty);
      expect(tasks.visible.single.id, 't1');
      expect(find.text('Task one'), findsNothing);
    });

    testWidgets('move to trash after confirm soft-deletes and pops',
        (tester) async {
      final g = seedGoal('G');
      await pump(tester, launcher(GoalDetailScreen(goalId: g.id)));
      await open(tester);

      await tester.tap(find.descendant(
          of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to trash'));
      await tester.pumpAndSettle();
      expect(find.text('Move this goal to trash?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Move to trash'));
      await tester.pumpAndSettle();

      expect(goals.goals[g.id]!.isDeleted, isTrue);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('archive after confirm archives and pops', (tester) async {
      final g = seedGoal('G');
      await pump(tester, launcher(GoalDetailScreen(goalId: g.id)));
      await open(tester);

      await tester.tap(find.descendant(
          of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Archive')));
      await tester.pumpAndSettle();

      expect(goals.goals[g.id]!.isArchived, isTrue);
      expect(goals.goals[g.id]!.isDeleted, isFalse);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('missing goal shows Goal not found', (tester) async {
      await pump(tester, const GoalDetailScreen(goalId: 'missing'));
      expect(find.text('Goal not found'), findsOneWidget);
    });
  });
}
