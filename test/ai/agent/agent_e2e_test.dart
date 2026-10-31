@TestOn('vm')
library;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/agent/agent_result.dart';
import 'package:my_time_manager/ai/agent/agent_runtime.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/policy/confirmation.dart';
import 'package:my_time_manager/domain/models/model_ai_action_log.dart';
import 'package:my_time_manager/domain/models/model_course.dart';
import 'package:my_time_manager/domain/models/model_course_module.dart';
import 'package:my_time_manager/domain/models/model_lesson.dart';
import 'package:my_time_manager/domain/models/model_lesson_progress.dart';
import 'package:my_time_manager/domain/models/model_project.dart';
import 'package:my_time_manager/domain/models/model_project_item.dart';
import 'package:my_time_manager/domain/models/model_reminder_rule.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';

import '../support/ai_test_env.dart';
import '../support/scripted_ai_engine.dart';

/// Phase C8b evaluation harness: end-to-end agent-loop runs through
/// [AgentRuntime] + real domain tools over in-memory SQLite, driven by
/// [ScriptedAiEngine]. No Ollama / llama.cpp needed.
void main() {
  setUpAll(initAiTestFfi);

  late AiTestEnv env;
  setUp(() async => env = await AiTestEnv.create());

  Future<AgentResult> runScript(List<AiResponse> script,
      {ConfirmationHandler confirm = approveAllConfirmation}) async {
    final result = await AgentRuntime(
      engine: ScriptedAiEngine(script),
      registry: env.registry,
      executor: env.executor(confirm: confirm),
    ).run('please help');
    expect(result.stopReason, AgentStopReason.completed);
    return result;
  }

  test('create_goal → confirmed → goal exists, logged executed', () async {
    await runScript([
      ScriptedAiEngine.toolCall('create_goal', {'title': 'Learn Spanish'}),
      ScriptedAiEngine.say('Created.'),
    ]);
    expect((await env.goals.getGoals()).map((g) => g.title), ['Learn Spanish']);
    final log = await env.actionLogs.getEntries();
    expect(log.single.toolName, 'create_goal');
    expect(log.single.outcome, AiActionOutcome.executed);
    expect(log.single.policyMode, 'confirmWrites');
  });

  test('create_goal declined → no goal, logged declined', () async {
    await runScript([
      ScriptedAiEngine.toolCall('create_goal', {'title': 'Learn Spanish'}),
      ScriptedAiEngine.say('OK, not created.'),
    ], confirm: denyByDefaultConfirmation);
    expect(await env.goals.getGoals(), isEmpty);
    expect((await env.actionLogs.getEntries()).single.outcome,
        AiActionOutcome.declined);
  });

  test('get_project_workspace reads a project; read-only is not logged',
      () async {
    final project = Project(title: 'Launch');
    await env.projects.createProject(project);
    final task = Task(title: 'Write copy');
    await env.tasks.createTask(task);
    await env.projects.addItem(project.id, ProjectEntityType.task, task.id);

    final result = await runScript([
      ScriptedAiEngine.toolCall('get_project_workspace', {'id': project.id}),
      ScriptedAiEngine.say('Here it is.'),
    ]);
    final r = toolResultsOf(result).single['result'] as Map;
    expect(r['success'], isTrue);
    final data = r['data'] as Map;
    expect(data['title'], 'Launch');
    expect((data['tasks'] as List).single['title'], 'Write copy');
    expect(await env.actionLogs.getEntries(), isEmpty);
  });

  test('set_lesson_completed via a text-format tool call', () async {
    final course = Course(title: 'Spanish');
    await env.learning.createCourse(course);
    final module = CourseModule(courseId: course.id, title: 'Basics');
    await env.learning.createModule(module);
    final lesson = Lesson(moduleId: module.id, title: 'Greetings');
    await env.learning.createLesson(lesson);

    await runScript([
      ScriptedAiEngine.textToolCall(
          'set_lesson_completed', {'lessonId': lesson.id}),
      ScriptedAiEngine.say('Marked.'),
    ]);
    expect((await env.learning.getLessonProgress(lesson.id))!.status,
        LessonStatus.completed);
    final log = await env.actionLogs.getEntries();
    expect(log.single.toolName, 'set_lesson_completed');
    expect(log.single.outcome, AiActionOutcome.executed);
  });

  test('add_interval_reminder creates an offset rule', () async {
    final interval = TimeInterval(
      title: 'Study',
      startDate: DateTime(2026, 3, 2),
      endDate: DateTime(2026, 3, 2),
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );
    await env.timeIntervals.createTimeInterval(interval);

    await runScript([
      ScriptedAiEngine.toolCall('add_interval_reminder',
          {'timeIntervalId': interval.id, 'minutesBefore': 15}),
      ScriptedAiEngine.say('Reminder set.'),
    ]);
    final rules = await env.reminderRules
        .getRulesFor(ReminderEntityType.timeInterval, interval.id);
    expect(rules.single.kind, ReminderRuleKind.offset);
    expect(rules.single.offsetMinutes, 15);
    final log = await env.actionLogs.getEntries();
    expect(log.single.outcome, AiActionOutcome.executed);
    expect(log.single.resultSummary, contains(rules.single.id));
  });
}
