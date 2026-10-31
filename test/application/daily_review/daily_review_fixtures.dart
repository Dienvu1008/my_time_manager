// Shared fixtures for the Daily Review (DR1) tests.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:my_time_manager/application/daily_review/daily_review.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_task.dart';
import 'package:my_time_manager/domain/models/model_time_interval.dart';
import 'package:my_time_manager/domain/repositories/time_interval_repository.dart';
import 'package:my_time_manager/screen_calendar/recurrence_expander.dart';

import '../../shared/fake_repositories.dart';

/// Fixed clock: Wednesday 2026-03-11 10:00 (local).
final DateTime kNow = DateTime(2026, 3, 11, 10);

/// `DateTime(2026, 3, day, h, m)`.
DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 3, day, h, m);

final DateTime kStamp = DateTime(2026, 1, 1);

TimeInterval timed(
  String id,
  DateTime s,
  DateTime e, {
  String? taskId = 't1',
  String? subtaskId,
  bool completed = false,
  bool important = false,
}) =>
    TimeInterval(
      id: id,
      taskId: taskId,
      subtaskId: subtaskId,
      title: id,
      isCompleted: completed,
      isImportant: important,
      startDate: DateTime(s.year, s.month, s.day),
      endDate: DateTime(e.year, e.month, e.day),
      startTime: TimeOfDay(hour: s.hour, minute: s.minute),
      endTime: TimeOfDay(hour: e.hour, minute: e.minute),
      updateTimeStamp: kStamp,
    );

/// Date-only interval on [day] (unknown duration).
TimeInterval untimed(String id, DateTime day, {String? taskId = 't1'}) =>
    TimeInterval(
      id: id,
      taskId: taskId,
      title: id,
      startDate: DateTime(day.year, day.month, day.day),
      endDate: DateTime(day.year, day.month, day.day),
      isStartTimeUndefined: true,
      isEndTimeUndefined: true,
      updateTimeStamp: kStamp,
    );

CalendarEvent event(
  String id,
  DateTime s,
  DateTime e, {
  EventTransparency transparency = EventTransparency.opaque,
  EventStatus status = EventStatus.confirmed,
  List<String>? recurrence,
}) =>
    CalendarEvent(
      id: id,
      title: id,
      start: EventDateTime(dateTime: s),
      end: EventDateTime(dateTime: e),
      transparency: transparency,
      status: status,
      recurrence: recurrence,
    );

CalendarEvent allDayEvent(String id, DateTime day) => CalendarEvent(
      id: id,
      title: id,
      start: EventDateTime(date: DateTime(day.year, day.month, day.day)),
      end: EventDateTime(date: DateTime(day.year, day.month, day.day + 1)),
    );

/// The app's real recurring-event expander, adapted like Phase R does.
List<DateTime> realExpander(CalendarEvent e, DateTime from, DateTime to) =>
    expandRecurringEvent(e, from, to).map((o) => o.start.effective).toList();

/// In-memory [TimeIntervalRepository] with a write log and failure injection.
class FakeIntervals implements TimeIntervalRepository {
  final Map<String, TimeInterval> store = {};
  final List<String> writes = [];

  /// Called before every write; throw to simulate a failure.
  void Function(String op, String id)? beforeWrite;

  void put(TimeInterval i) => store[i.id] = i;

  @override
  Future<List<TimeInterval>> getTimeIntervals() async => store.values.toList();

  @override
  Future<TimeInterval> getTimeInterval(String id) async {
    final i = store[id];
    if (i == null) throw StateError('missing $id');
    return i;
  }

  @override
  Future<void> createTimeInterval(TimeInterval timeInterval) async {
    beforeWrite?.call('create', timeInterval.id);
    writes.add('create:${timeInterval.id}');
    store[timeInterval.id] = timeInterval;
  }

  @override
  Future<void> updateTimeInterval(TimeInterval timeInterval) async {
    beforeWrite?.call('update', timeInterval.id);
    writes.add('update:${timeInterval.id}');
    store[timeInterval.id] = timeInterval;
  }

  @override
  Future<void> deleteTimeInterval(String id) async {
    beforeWrite?.call('delete', id);
    writes.add('delete:$id');
    store.remove(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// All repositories + the DR services wired together.
class Env {
  Env() {
    tasks.visible.add(Task(id: 't1', title: 'Task 1'));
  }

  final intervals = FakeIntervals();
  final tasks = FakeTaskRepository();
  final calendar = FakeCalendarRepository();
  final habits = FakeHabitRepository();
  EventOccurrenceExpander? expander = realExpander;
  int newIds = 0;

  DailyReviewService get service => DailyReviewService(
        timeIntervals: intervals,
        tasks: tasks,
        calendar: calendar,
        habits: habits,
        expander: expander,
      );

  ReschedulePlanner get planner =>
      ReschedulePlanner(expander: expander, newId: () => 'new-${++newIds}');

  ProposalApplier get applier => ProposalApplier(
        timeIntervals: intervals,
        tasks: tasks,
        calendar: calendar,
        expander: expander,
      );

  Future<DailyReview> review(
          {DateTime? now, Availability availability = const Availability()}) =>
      service.review(now ?? kNow, availability);

  Future<RescheduleProposal> plan(List<ReviewSelection> selections,
      {DateTime? now, Availability availability = const Availability()}) async {
    final r = await review(now: now, availability: availability);
    return planner.plan(
        review: r, selections: selections, availability: availability);
  }
}

/// Confirmation handler that records the requests and answers [answer].
class RecordingConfirm {
  RecordingConfirm(this.answer);
  final bool answer;
  final List<ReviewConfirmationRequest> requests = [];

  Future<bool> call(ReviewConfirmationRequest r) async {
    requests.add(r);
    return answer;
  }
}
