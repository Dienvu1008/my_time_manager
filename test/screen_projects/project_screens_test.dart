import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/calendar_repository.dart';
import 'package:my_time_manager/domain/repositories/goal_repository.dart';
import 'package:my_time_manager/domain/repositories/learning_repository.dart';
import 'package:my_time_manager/domain/repositories/note_repository.dart';
import 'package:my_time_manager/domain/repositories/project_repository.dart';
import 'package:my_time_manager/domain/repositories/task_list_repository.dart';
import 'package:my_time_manager/domain/repositories/task_repository.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';
import 'package:my_time_manager/domain/services/learning_progress_service.dart';
import 'package:my_time_manager/domain/services/project_workspace_service.dart';
import 'package:my_time_manager/screen_projects/project_form_screen.dart';
import 'package:my_time_manager/screen_projects/project_workspace_screen.dart';
import 'package:my_time_manager/screen_projects/projects_list_screen.dart';

import '../screen_learning/fake_learning_repository.dart';
import '../shared/fake_repositories.dart';
import '../shared/test_harness.dart';

/// Returns a prebuilt workspace (or null).
class _FakeWorkspaceService implements ProjectWorkspaceService {
  _FakeWorkspaceService(this.workspace);

  final ProjectWorkspace? workspace;

  @override
  Future<ProjectWorkspace?> workspaceOf(String projectId) async => workspace;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [FakeProjectRepository] whose project creation throws.
class _FailingProjectRepository extends FakeProjectRepository {
  @override
  Future<void> createProject(Project project) async =>
      throw Exception('boom');
}

FakeProjectRepository _projectsWith(List<Project> projects) {
  final fake = FakeProjectRepository();
  for (final p in projects) {
    fake.projects[p.id] = p;
  }
  return fake;
}

Widget _harness({
  required Widget home,
  FakeProjectRepository? projects,
  ProjectWorkspace? workspace,
}) {
  return testApp([
    RepositoryProvider<ProjectRepository>.value(
        value: projects ?? FakeProjectRepository()),
    RepositoryProvider<ProjectWorkspaceService>.value(
        value: _FakeWorkspaceService(workspace)),
  ], home);
}

void main() {
  group('ProjectsListScreen', () {
    testWidgets('shows the empty state when there are no projects',
        (tester) async {
      await tester.pumpWidget(_harness(home: const ProjectsListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('No projects yet'), findsOneWidget);
      expect(find.text('Tap + to create your first project.'), findsOneWidget);
    });

    testWidgets('lists a project with its status', (tester) async {
      await tester.pumpWidget(_harness(
        home: const ProjectsListScreen(),
        projects: _projectsWith([Project(title: 'Website relaunch')]),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('No projects yet'), findsNothing);
    });

    testWidgets('FAB creates a project and the list shows it',
        (tester) async {
      final fake = FakeProjectRepository();
      await tester.pumpWidget(
          _harness(home: const ProjectsListScreen(), projects: fake));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('New project'));
      await tester.pumpAndSettle();
      expect(find.text('New project'), findsOneWidget); // form AppBar
      await tester.enterText(find.byType(TextFormField).first, 'My project');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(fake.projects.values.single.title, 'My project');
      expect(find.text('My project'), findsOneWidget);
      expect(find.text('No projects yet'), findsNothing);
    });
  });

  group('ProjectFormScreen', () {
    testWidgets('empty title shows a validation error', (tester) async {
      final fake = FakeProjectRepository();
      await tester.pumpWidget(
          _harness(home: const ProjectFormScreen(), projects: fake));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsOneWidget);
      expect(fake.projects, isEmpty);
    });

    testWidgets('save failure shows an error SnackBar and re-enables Save',
        (tester) async {
      await tester.pumpWidget(_harness(
          home: const ProjectFormScreen(),
          projects: _FailingProjectRepository()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'My project');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Error: Exception: boom'), findsOneWidget);
      expect(find.text('New project'), findsOneWidget); // still on the form
      final save = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.check));
      expect(save.onPressed, isNotNull);
    });

    testWidgets('target before start shows an error and saves nothing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final p = Project(
        id: 'p',
        title: 'Inverted',
        startDate: DateTime(2026, 5, 10),
        targetDate: DateTime(2026, 5, 1),
      );
      final fake = _projectsWith([p]);
      await tester.pumpWidget(_harness(
          home: launcher(ProjectFormScreen(project: p)), projects: fake));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Changed');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Target date cannot be before start date'),
          findsOneWidget);
      expect(find.text('Edit project'), findsOneWidget); // still on the form
      expect(fake.projects['p']!.title, 'Inverted');
    });

    testWidgets('edit saves the new title and clearing the start date',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final p = Project(
          id: 'p', title: 'Old', startDate: DateTime(2026, 5, 10));
      final fake = _projectsWith([p]);
      await tester.pumpWidget(_harness(
          home: launcher(ProjectFormScreen(project: p)), projects: fake));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('10/05/2026'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'New');
      await tester.tap(find.byTooltip('Clear date'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      expect(find.text('result: true'), findsOneWidget);
      expect(fake.projects['p']!.title, 'New');
      expect(fake.projects['p']!.startDate, isNull);
    });
  });

  group('ProjectWorkspaceScreen', () {
    testWidgets('renders all sections with their content', (tester) async {
      final project = Project(id: 'p', title: 'Website', description: 'Desc');
      final list = TaskList(id: 'L', title: 'L');
      final ws = ProjectWorkspace(
        project: project,
        taskLists: [list],
        tasks: [
          WorkspaceTask(
            task: Task(id: 't1', taskListId: 'L', title: 'Via task',
                isCompleted: true),
            isDirect: false,
            viaTaskListId: 'L',
          ),
          WorkspaceTask(
            task: Task(id: 't2', title: 'Direct task'),
            isDirect: true,
          ),
        ],
        notes: [Note(id: 'n', title: 'Meeting note')],
        goals: [
          WorkspaceGoal(
            goal: Goal(id: 'g', title: 'Launch goal'),
            progress: const GoalProgress(
              goalId: 'g',
              ratio: 0.5,
              doneMilestones: 0,
              totalMilestones: 0,
              directCompletedTasks: 1,
              directTotalTasks: 2,
              milestones: [],
            ),
          ),
        ],
        courses: [
          WorkspaceCourse(
            course: Course(id: 'c', title: 'Flutter course'),
            progress: const CourseProgress(
              courseId: 'c',
              totalLessons: 4,
              completedLessons: 1,
              inProgressLessons: 0,
              totalModules: 1,
              doneModules: 0,
              ratio: 0.25,
              isDone: false,
              modules: [],
            ),
          ),
        ],
        calendarEvents: [
          CalendarEvent(
            id: 'e',
            title: 'Kickoff',
            start: EventDateTime(dateTime: DateTime(2026, 5, 1, 9)),
            end: EventDateTime(dateTime: DateTime(2026, 5, 1, 10)),
          ),
        ],
      );
      await tester.pumpWidget(_harness(
        home: const ProjectWorkspaceScreen(projectId: 'p'),
        workspace: ws,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Website'), findsOneWidget); // AppBar title
      expect(find.text('Desc'), findsOneWidget);
      expect(find.text('Tasks completed: 1/2'), findsOneWidget);

      // Sections are laid out in a scrollable list; scroll to each.
      Future<void> see(String text) async {
        await tester.scrollUntilVisible(find.text(text), 100,
            scrollable: find.byType(Scrollable).first);
        expect(find.text(text), findsOneWidget);
      }

      await see('Task lists');
      await see('L');
      await see('Tasks');
      await see('Via task');
      await see('Via list: L');
      await see('Direct task');
      await see('Linked directly');
      await see('Notes');
      await see('Meeting note');
      await see('Goals');
      await see('Launch goal');
      await see('50%');
      await see('Courses');
      await see('Flutter course');
      await see('25%');
      await see('Calendar events');
      await see('Kickoff');
      await see('01/05/2026');
      expect(find.text('Nothing linked yet'), findsNothing);
    });

    testWidgets('empty project shows the empty text in all 6 sections',
        (tester) async {
      // Use a tall surface so every section is built.
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness(
        home: const ProjectWorkspaceScreen(projectId: 'p'),
        workspace: ProjectWorkspace(project: Project(id: 'p', title: 'P')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nothing linked yet'), findsNWidgets(6));
      expect(find.text('Tasks completed: 0/0'), findsOneWidget);
    });

    testWidgets('null workspace shows "Project not found"', (tester) async {
      await tester.pumpWidget(_harness(
        home: const ProjectWorkspaceScreen(projectId: 'missing'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Project not found'), findsOneWidget);
      expect(find.text('Project workspace'), findsOneWidget);
    });
  });

  group('ProjectWorkspaceScreen interactions', () {
    late FakeProjectRepository projects;
    late FakeTaskListRepository taskLists;
    late FakeTaskRepository tasks;
    late FakeNoteRepository notes;
    late FakeCalendarRepository calendar;
    late FakeGoalRepository goals;
    late FakeLearningRepository learning;

    setUp(() {
      projects = FakeProjectRepository();
      taskLists = FakeTaskListRepository();
      tasks = FakeTaskRepository();
      notes = FakeNoteRepository();
      calendar = FakeCalendarRepository();
      goals = FakeGoalRepository();
      learning = FakeLearningRepository();
      projects.projects['p'] = Project(id: 'p', title: 'Website');
    });

    Widget app(Widget home) => testApp([
          RepositoryProvider<ProjectRepository>.value(value: projects),
          RepositoryProvider<TaskListRepository>.value(value: taskLists),
          RepositoryProvider<TaskRepository>.value(value: tasks),
          RepositoryProvider<NoteRepository>.value(value: notes),
          RepositoryProvider<CalendarRepository>.value(value: calendar),
          RepositoryProvider<GoalRepository>.value(value: goals),
          RepositoryProvider<LearningRepository>.value(value: learning),
          RepositoryProvider<ProjectWorkspaceService>.value(
            value: ProjectWorkspaceService(
              projects: projects,
              taskLists: taskLists,
              tasks: tasks,
              notes: notes,
              calendar: calendar,
              goals: goals,
              goalProgress: GoalProgressService(goals, tasks),
              learning: learning,
              learningProgress: LearningProgressService(learning),
            ),
          ),
        ], home);

    Future<void> pump(WidgetTester tester, Widget home) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(home));
      await tester.pumpAndSettle();
    }

    Future<void> chooseType(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('Add item'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(SimpleDialog), matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    testWidgets('add a note via the picker, then remove it (link only)',
        (tester) async {
      notes.visible.add(Note(id: 'n1', title: 'Meeting note'));
      await pump(tester, const ProjectWorkspaceScreen(projectId: 'p'));
      expect(find.text('Meeting note'), findsNothing);

      await chooseType(tester, 'Notes');
      expect(find.byType(ListTile), findsOneWidget); // picker row
      await tester.tap(find.text('Meeting note'));
      await tester.pumpAndSettle();

      final item = projects.items.values.single;
      expect(item.entityType, ProjectEntityType.note);
      expect(item.entityId, 'n1');
      expect(find.text('Meeting note'), findsOneWidget);

      // Already linked → no longer offered.
      await chooseType(tester, 'Notes');
      expect(find.text('Nothing to choose'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Remove')));
      await tester.pumpAndSettle();

      expect(projects.items, isEmpty);
      expect(find.text('Meeting note'), findsNothing);
      expect(notes.visible.map((n) => n.id), ['n1']);
    });

    testWidgets('implicit tasks (via linked list) have no remove action',
        (tester) async {
      taskLists.visible.add(TaskList(id: 'L', title: 'List L'));
      tasks.visible.addAll([
        Task(id: 't1', taskListId: 'L', title: 'Implicit task'),
        Task(id: 't2', taskListId: 'L', title: 'Direct task'),
      ]);
      await projects.addItem('p', ProjectEntityType.taskList, 'L');
      await projects.addItem('p', ProjectEntityType.task, 't2',
          sortOrder: 1);
      await pump(tester, const ProjectWorkspaceScreen(projectId: 'p'));

      expect(find.text('Implicit task'), findsOneWidget);
      expect(find.byTooltip('Remove'), findsNWidgets(2));
      final t1Tile = find.ancestor(
          of: find.text('Implicit task'), matching: find.byType(ListTile));
      expect(find.descendant(of: t1Tile, matching: find.byTooltip('Remove')),
          findsNothing);
      final t2Tile = find.ancestor(
          of: find.text('Direct task'), matching: find.byType(ListTile));
      expect(find.descendant(of: t2Tile, matching: find.byTooltip('Remove')),
          findsOneWidget);
    });

    testWidgets('edit button opens the project form', (tester) async {
      await pump(tester, const ProjectWorkspaceScreen(projectId: 'p'));
      await tester.tap(find.byTooltip('Edit project'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectFormScreen), findsOneWidget);
      expect(find.text('Edit project'), findsOneWidget);
    });

    testWidgets('archive after confirm archives the project and pops',
        (tester) async {
      await pump(tester,
          launcher(const ProjectWorkspaceScreen(projectId: 'p')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Archive')));
      await tester.pumpAndSettle();

      expect(projects.projects['p']!.isArchived, isTrue);
      expect(projects.projects['p']!.isDeleted, isFalse);
      expect(find.text('result: true'), findsOneWidget);
    });

    testWidgets('move to trash soft-deletes the project and pops',
        (tester) async {
      await pump(tester,
          launcher(const ProjectWorkspaceScreen(projectId: 'p')));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to trash'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog), matching: find.text('Move to trash')));
      await tester.pumpAndSettle();

      expect(projects.projects['p']!.isDeleted, isTrue);
      expect(find.text('result: true'), findsOneWidget);
    });
  });
}
