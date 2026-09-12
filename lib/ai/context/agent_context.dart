/// A single task line in the context (minimal projection).
class ContextTask {
  const ContextTask({
    required this.id,
    required this.title,
    required this.isImportant,
  });
  final String id;
  final String title;
  final bool isImportant;

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, if (isImportant) 'important': true};
}

/// A scheduled block (calendar event or planned time interval) in the context.
class ContextScheduleItem {
  const ContextScheduleItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.start,
    this.end,
    this.allDay = false,
  });

  final String id;
  final String title;

  /// 'event' or 'interval'.
  final String kind;
  final DateTime start;
  final DateTime? end;
  final bool allDay;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'start': start.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
        if (allDay) 'allDay': true,
      };
}

/// A compact focus snapshot for the context.
class ContextFocus {
  const ContextFocus({
    required this.windowDays,
    required this.totalMinutes,
    required this.sessionCount,
  });
  final int windowDays;
  final int totalMinutes;
  final int sessionCount;

  Map<String, dynamic> toJson() => {
        'windowDays': windowDays,
        'totalMinutes': totalMinutes,
        'sessionCount': sessionCount,
      };
}

/// A targeted, minimal, deterministic snapshot of the user's current state that
/// the agent can read up front — instead of dumping the whole database. It is
/// inspectable (structured fields), serializable, and renderable to a compact
/// text block for a system/context message.
///
/// The agent can always request MORE detail through tools; this is only the
/// starting context.
class AgentContext {
  const AgentContext({
    required this.now,
    required this.outstandingTasks,
    required this.totalOutstanding,
    required this.todaySchedule,
    required this.upcoming,
    required this.focus,
    this.timezone,
  });

  /// The reference "now" the context was built at.
  final DateTime now;

  /// The user's effective IANA timezone (device or configured). When present it
  /// is surfaced to the model so it interprets/creates times in the user's
  /// local zone rather than UTC. Null when unknown.
  final String? timezone;

  /// A capped list of outstanding (incomplete, visible) tasks.
  final List<ContextTask> outstandingTasks;

  /// Total number of outstanding tasks (may exceed [outstandingTasks].length
  /// when capped).
  final int totalOutstanding;

  /// Events/intervals scheduled for today, sorted by start.
  final List<ContextScheduleItem> todaySchedule;

  /// Upcoming events/intervals after today, sorted by start (capped).
  final List<ContextScheduleItem> upcoming;

  /// Recent focus summary, or null if unavailable.
  final ContextFocus? focus;

  Map<String, dynamic> toJson() => {
        'now': now.toIso8601String(),
        if (timezone != null) 'timezone': timezone,
        'outstandingTasks': outstandingTasks.map((t) => t.toJson()).toList(),
        'totalOutstanding': totalOutstanding,
        'todaySchedule': todaySchedule.map((s) => s.toJson()).toList(),
        'upcoming': upcoming.map((s) => s.toJson()).toList(),
        if (focus != null) 'focus': focus!.toJson(),
      };

  /// A compact, human/LLM-readable rendering for a context message. Deterministic
  /// given the same inputs.
  String render() {
    final b = StringBuffer();
    b.writeln('Current context (as of ${_fmtDateTime(now)}):');
    if (timezone != null && timezone!.isNotEmpty) {
      b.writeln('- User timezone: $timezone. Interpret and create times in this '
          'local timezone (use its UTC offset), not UTC.');
    }

    b.writeln('- Outstanding tasks: $totalOutstanding'
        '${totalOutstanding > outstandingTasks.length ? ' (showing ${outstandingTasks.length})' : ''}');
    for (final t in outstandingTasks) {
      b.writeln('    • ${t.title}${t.isImportant ? ' [important]' : ''} (id: ${t.id})');
    }

    b.writeln('- Today\'s schedule: ${todaySchedule.length} item(s)');
    for (final s in todaySchedule) {
      b.writeln('    • ${_fmtSchedule(s)}');
    }

    if (upcoming.isNotEmpty) {
      b.writeln('- Upcoming: ${upcoming.length} item(s)');
      for (final s in upcoming) {
        b.writeln('    • ${_fmtSchedule(s)}');
      }
    }

    if (focus != null) {
      b.writeln('- Focus (last ${focus!.windowDays}d): '
          '${focus!.totalMinutes} min across ${focus!.sessionCount} session(s)');
    }
    return b.toString().trimRight();
  }

  static String _fmtSchedule(ContextScheduleItem s) {
    final kind = s.kind == 'event' ? 'event' : 'block';
    if (s.allDay) return '${s.title} — all day $kind';
    final startStr = _fmtTime(s.start);
    final endStr = s.end != null ? '–${_fmtTime(s.end!)}' : '';
    return '${s.title} — $startStr$endStr $kind';
  }

  static String _fmtDateTime(DateTime d) =>
      '${_fmtDate(d)} ${_fmtTime(d)}';

  static String _fmtDate(DateTime d) =>
      '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

  static String _fmtTime(DateTime d) => '${_pad2(d.hour)}:${_pad2(d.minute)}';

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
