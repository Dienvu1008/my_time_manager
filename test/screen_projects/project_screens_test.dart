import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_goal.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/repositories/project_repository.dart';
import 'package:my_time_manager/domain/services/goal_progress_service.dart';
import 'package:my_time_manager/domain/services/project_workspace_service.dart';
import 'package:my_time_manager/screen_projects/project_workspace_screen.dart';
import 'package:my_time_manager/screen_projects/projects_list_screen.dart';

/// Only [getProjects] matters for the list screen.
class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this.projects);

  final List<Project> projects;

  @override
  Future<List<Project>> getProjects() async => projects;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Returns a prebuilt workspace (or null).
class _FakeWorkspaceService implements ProjectWorkspaceService {
  _FakeWorkspaceService(this.workspace);

  final ProjectWorkspace? workspace;

  @override
  Future<ProjectWorkspace?> workspaceOf(String projectId) async => workspace;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _harness({
  required Widget home,
  List<Project> projects = const [],
  ProjectWorkspace? workspace,
}) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ProjectRepository>.value(
          value: _FakeProjectRepository(projects)),
      RepositoryProvider<ProjectWorkspaceService>.value(
          value: _FakeWorkspaceService(workspace)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    ),
  );
}

void main() {
  group('ProjectsListScreen', () {
    testWidgets('shows the empty state when there are no projects',
        (tester) async {
      await tester.pumpWidget(_harness(home: const ProjectsListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('No projects yet'), findsOneWidget);
      expect(find.text('Projects will appear here once they are created.'),
          findsOneWidget);
    });

    testWidgets('lists a project with its status', (tester) async {
      await tester.pumpWidget(_harness(
        home: const ProjectsListScreen(),
        projects: [Project(title: 'Website relaunch')],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Website relaunch'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('No projects yet'), findsNothing);
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
      await see('Calendar events');
      await see('Kickoff');
      await see('01/05/2026');
      expect(find.text('Nothing linked yet'), findsNothing);
    });

    testWidgets('empty project shows the empty text in all 5 sections',
        (tester) async {
      // Use a tall surface so every section is built.
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness(
        home: const ProjectWorkspaceScreen(projectId: 'p'),
        workspace: ProjectWorkspace(project: Project(id: 'p', title: 'P')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Nothing linked yet'), findsNWidgets(5));
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
}
