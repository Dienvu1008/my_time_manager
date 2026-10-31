import 'package:appflowy_editor/appflowy_editor.dart'
    show AppFlowyEditorLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:my_time_manager/domain/repositories/learning_repository.dart';
import 'package:my_time_manager/domain/services/learning_progress_service.dart';
import 'package:my_time_manager/screen_learning/course_detail_screen.dart';
import 'package:my_time_manager/screen_learning/course_form_screen.dart';
import 'package:my_time_manager/screen_learning/courses_list_screen.dart';
import 'package:my_time_manager/screen_learning/lesson_screen.dart';

import 'fake_learning_repository.dart';

Widget _harness(FakeLearningRepository fake, Widget home) {
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<LearningRepository>.value(value: fake),
      RepositoryProvider<LearningProgressService>.value(
          value: LearningProgressService(fake)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppFlowyEditorLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    ),
  );
}

/// A home screen with an 'open' button that pushes [screen], so the screen
/// can pop (Navigator.pop) back to it.
Widget _launcher(Widget screen) => Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('open'),
        ),
      ),
    );

/// Course 'c' with module 'm' (lessons 'l1' completed, 'l2' not started).
FakeLearningRepository _seeded() {
  final fake = FakeLearningRepository();
  final c = Course(id: 'c', title: 'Flutter basics');
  fake.courses[c.id] = c;
  fake.modules['m'] = CourseModule(id: 'm', courseId: 'c', title: 'Widgets');
  fake.lessons['l1'] =
      Lesson(id: 'l1', moduleId: 'm', title: 'Stateless', sortOrder: 0);
  fake.lessons['l2'] =
      Lesson(id: 'l2', moduleId: 'm', title: 'Stateful', sortOrder: 1);
  fake.progress['l1'] =
      LessonProgress(lessonId: 'l1', status: LessonStatus.completed);
  return fake;
}

void main() {
  group('CoursesListScreen', () {
    testWidgets('shows the empty state and a New course button',
        (tester) async {
      await tester.pumpWidget(
          _harness(FakeLearningRepository(), const CoursesListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('No courses yet'), findsOneWidget);
      expect(find.text('Tap + to create your first course.'), findsOneWidget);
      expect(find.byTooltip('New course'), findsOneWidget);
    });

    testWidgets('lists a course with derived progress', (tester) async {
      await tester.pumpWidget(_harness(_seeded(), const CoursesListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Flutter basics'), findsOneWidget);
      expect(find.text('Lessons completed: 1/2'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('No courses yet'), findsNothing);
    });
  });

  group('CourseFormScreen', () {
    testWidgets('creates a manual course', (tester) async {
      final fake = FakeLearningRepository();
      await tester.pumpWidget(_harness(fake, _launcher(const CourseFormScreen())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('New course'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Dart');
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(fake.courses, hasLength(1));
      final c = fake.courses.values.single;
      expect(c.title, 'Dart');
      expect(c.source, CourseSource.manual);
      expect(find.text('open'), findsOneWidget); // popped back
    });

    testWidgets('empty title shows a validation error', (tester) async {
      final fake = FakeLearningRepository();
      await tester.pumpWidget(_harness(fake, const CourseFormScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Title is required'), findsOneWidget);
      expect(fake.courses, isEmpty);
    });
  });

  group('CourseDetailScreen', () {
    testWidgets('renders modules, lessons and progress', (tester) async {
      await tester.pumpWidget(
          _harness(_seeded(), const CourseDetailScreen(courseId: 'c')));
      await tester.pumpAndSettle();
      expect(find.text('Flutter basics'), findsOneWidget); // AppBar title
      expect(find.text('Widgets'), findsOneWidget);
      expect(find.text('Stateless'), findsOneWidget);
      expect(find.text('Stateful'), findsOneWidget);
      expect(find.text('Lessons completed: 1/2'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byTooltip('Add module'), findsOneWidget);
      expect(find.byTooltip('Edit course'), findsOneWidget);
    });

    testWidgets('missing course shows "Course not found"', (tester) async {
      await tester.pumpWidget(_harness(
          FakeLearningRepository(), const CourseDetailScreen(courseId: 'x')));
      await tester.pumpAndSettle();
      expect(find.text('Course not found'), findsOneWidget);
    });

    testWidgets('move to trash soft-deletes the course', (tester) async {
      final fake = _seeded();
      // Push the detail screen from a launcher so it can pop afterwards.
      await tester.pumpWidget(
          _harness(fake, _launcher(const CourseDetailScreen(courseId: 'c'))));

      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to trash'));
      await tester.pumpAndSettle();
      expect(fake.courses['c']!.isDeleted, isTrue);
      expect(find.byType(CourseDetailScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('LessonScreen', () {
    Future<void> pumpLesson(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('opening marks in progress; Mark complete completes',
        (tester) async {
      final fake = _seeded();
      await tester
          .pumpWidget(_harness(fake, const LessonScreen(lessonId: 'l2')));
      await pumpLesson(tester);

      expect(fake.opened, ['l2']);
      expect(find.text('Stateful'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      await tester.tap(find.text('Mark complete'));
      await pumpLesson(tester);
      expect(fake.completed, ['l2']);
      expect(find.text('Mark as not completed'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(fake.progress['l2']!.status, LessonStatus.completed);

      await tester.tap(find.text('Mark as not completed'));
      await pumpLesson(tester);
      expect(find.text('Mark complete'), findsOneWidget);
      expect(fake.progress['l2']!.completedAt, isNull);
    });

    testWidgets('missing lesson shows "Lesson not found"', (tester) async {
      await tester.pumpWidget(_harness(
          FakeLearningRepository(), const LessonScreen(lessonId: 'x')));
      await pumpLesson(tester);
      expect(find.text('Lesson not found'), findsOneWidget);
    });
  });
}
