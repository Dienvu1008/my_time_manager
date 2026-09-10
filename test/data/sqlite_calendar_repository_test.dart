@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for the SQLite-backed CalendarRepository against an in-memory
/// database. Verifies round-trip, visibility filters, and the sync-support
/// methods the calendar sync services rely on.
CalendarEvent _event({String? title, String? googleEventId}) {
  final now = DateTime(2026, 1, 1, 9);
  return CalendarEvent(
    title: title ?? 'Meeting',
    start: EventDateTime(dateTime: now),
    end: EventDateTime(dateTime: now.add(const Duration(hours: 1))),
    color: const Color(0xff2196f3),
    googleEventId: googleEventId,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Fresh unique in-memory DB per test. No tearDown: closing/nulling the
    // shared DatabaseManager singleton between tests races when the whole suite
    // runs in one `flutter test` process. setUp swapping in a fresh DB suffices.
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('create + getCalendarEvent round-trips an event', () async {
    final repo = SqliteCalendarRepository();
    final e = _event(title: 'Standup');

    await repo.createCalendarEvent(e);
    final fetched = await repo.getCalendarEvent(e.id);

    expect(fetched, isNotNull);
    expect(fetched!.id, e.id);
    expect(fetched.title, 'Standup');
  });

  test('getCalendarEvents excludes soft-deleted events', () async {
    final repo = SqliteCalendarRepository();
    final a = _event(title: 'A');
    final b = _event(title: 'B');
    await repo.createCalendarEvent(a);
    await repo.createCalendarEvent(b);

    await repo.softDeleteCalendarEvent(a.id);

    final visible = await repo.getCalendarEvents();
    expect(visible.map((e) => e.id), isNot(contains(a.id)));
    expect(visible.map((e) => e.id), contains(b.id));
  });

  test('archive hides an event; unarchive restores it', () async {
    final repo = SqliteCalendarRepository();
    final a = _event(title: 'A');
    await repo.createCalendarEvent(a);

    await repo.archiveCalendarEvent(a.id);
    expect((await repo.getCalendarEvents()).map((e) => e.id),
        isNot(contains(a.id)));

    await repo.unarchiveCalendarEvent(a.id);
    expect(
        (await repo.getCalendarEvents()).map((e) => e.id), contains(a.id));
  });

  test('getEventByGoogleId finds a synced event by its remote id', () async {
    final repo = SqliteCalendarRepository();
    final a = _event(title: 'A');
    await repo.createCalendarEvent(a);

    await repo.markSynced(a.id, googleEventId: 'g-123', etag: 'etag-1');

    final found = await repo.getEventByGoogleId('g-123');
    expect(found, isNotNull);
    expect(found!.id, a.id);
  });

  test('getEventsPendingSync returns unsynced events, excludes synced',
      () async {
    final repo = SqliteCalendarRepository();
    final a = _event(title: 'A'); // localOnly by default
    final b = _event(title: 'B');
    await repo.createCalendarEvent(a);
    await repo.createCalendarEvent(b);

    // Mark b as synced -> only a should be pending.
    await repo.markSynced(b.id, googleEventId: 'g-b');

    final pending = await repo.getEventsPendingSync();
    expect(pending.map((e) => e.id), contains(a.id));
    expect(pending.map((e) => e.id), isNot(contains(b.id)));
  });
}
