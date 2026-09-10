/// The higher-level personal-execution workflows the assistant offers. Each is
/// framed by workflow-specific guidance (appended as a system message) plus an
/// opening user message. They ride the SAME agent loop — tools, action policy,
/// and confirmation all apply — so any data change still requires the usual
/// approval.
enum AgentWorkflow {
  dailyPlanning,
  weeklyReview,
  rescheduling;

  /// A short, user-facing title.
  String get title {
    switch (this) {
      case AgentWorkflow.dailyPlanning:
        return 'Plan my day';
      case AgentWorkflow.weeklyReview:
        return 'Weekly review';
      case AgentWorkflow.rescheduling:
        return 'Reorganize remaining work';
    }
  }

  /// A one-line description for the UI.
  String get description {
    switch (this) {
      case AgentWorkflow.dailyPlanning:
        return 'Analyze today and propose a schedule for approval.';
      case AgentWorkflow.weeklyReview:
        return 'Summarize the week and surface patterns.';
      case AgentWorkflow.rescheduling:
        return 'Re-prioritize unfinished work and propose a new plan.';
    }
  }

  /// The opening user message that kicks off the workflow.
  String get openingMessage {
    switch (this) {
      case AgentWorkflow.dailyPlanning:
        return 'Plan my day.';
      case AgentWorkflow.weeklyReview:
        return 'Review my week.';
      case AgentWorkflow.rescheduling:
        return "I couldn't finish today's work. Reorganize the remaining tasks.";
    }
  }

  /// Workflow-specific behavioural guidance, appended as a system message.
  /// It steers WHICH tools to use and in WHAT order, and reinforces that any
  /// change is proposed for approval — it never bypasses the policy.
  String get guidance {
    switch (this) {
      case AgentWorkflow.dailyPlanning:
        return _dailyPlanning;
      case AgentWorkflow.weeklyReview:
        return _weeklyReview;
      case AgentWorkflow.rescheduling:
        return _rescheduling;
    }
  }

  static const _dailyPlanning = '''
Workflow: Daily Planning.
Goal: propose a realistic schedule for today, then create it only after the user approves.
Steps:
1. Read today's calendar events (list_calendar_events) and existing time blocks (list_time_intervals).
2. Read outstanding tasks (list_tasks with onlyIncomplete=true); note important ones.
3. Consider recent focus capacity (get_focus_summary) to avoid over-planning.
4. Identify free time between fixed commitments.
5. Propose a concrete schedule: which tasks in which time slots, with rationale. Present it as a numbered plan.
6. Only after the user approves, create the time intervals (create_time_interval). Each create is a WRITE and will ask for confirmation — that is expected.
Do not create anything before presenting the plan and getting agreement.''';

  static const _weeklyReview = '''
Workflow: Weekly Review.
Goal: produce an honest, useful summary of the past week. This is READ-ONLY — make no changes.
Steps:
1. Read tasks (list_tasks) to see completed vs outstanding.
2. Read focus statistics for the last 7 days (get_focus_statistics or get_focus_summary).
3. Read the deterministic metrics (get_productivity_metrics) and INTERPRET them — do not recompute numbers yourself.
4. Identify patterns: where estimation was off (estimationBias), whether workload was realistic (workloadScore), execution rate, and any missed deadlines.
5. Give a concise summary with 2-3 concrete suggestions for next week.
Do not create, update, or delete anything.''';

  static const _rescheduling = '''
Workflow: Rescheduling.
Goal: when the user is behind, re-prioritize the remaining work and propose a new plan for approval.
Steps:
1. Read unfinished tasks (list_tasks with onlyIncomplete=true) and their planned blocks (list_time_intervals).
2. Read the remaining calendar (list_calendar_events) to see what time is left.
3. Prioritize: important tasks and near deadlines first; be realistic about available time.
4. Propose a new schedule as a numbered plan, noting anything that must slip to another day.
5. Only after the user approves, apply changes (update_time_interval / create_time_interval). Each write asks for confirmation — that is expected.
Do not change anything before presenting the plan and getting agreement.''';
}
