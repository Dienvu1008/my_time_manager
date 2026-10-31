@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/backup/backup_service.dart';
import 'package:my_time_manager/data/backup/import_service.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/repositories/sqlite_calendar_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_note_repository.dart';
import 'package:my_time_manager/data/repositories/sqlite_task_list_repository.dart';
import 'package:my_time_manager/domain/models/model_calendar_event.dart';
import 'package:my_time_manager/domain/models/model_list.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup (JSON export) + import of `notes` and `calendar_events`. These were
/// exported but previously missing from `ImportService._importOrder`, so they
/// were silently dropped on import.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseManager().resetForTesting(inMemory: true);
  });

  test('import into a fresh DB restores notes and calendar events', () async {
    final lists = SqliteTaskListRepository();
    final notes = SqliteNoteRepository();
    final calendar = SqliteCalendarRepository();

    final list = TaskList(title: 'L');
    await lists.createTaskList(list);
    final note = Note(title: 'My note', contentJson: '{"document":{}}');
    await notes.createNote(note);
    final event = CalendarEvent(
      title: 'Meeting',
      taskListId: list.id,
      start: EventDateTime(dateTime: DateTime(2026, 3, 1, 9)),
      end: EventDateTime(dateTime: DateTime(2026, 3, 1, 10)),
    );
    await calendar.createCalendarEvent(event);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    await DatabaseManager().resetForTesting(inMemory: true);
    expect(await notes.getNote(note.id), isNull);
    expect(await calendar.getCalendarEvent(event.id), isNull);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);
    expect(summary.added, greaterThanOrEqualTo(3));

    final backNote = await notes.getNote(note.id);
    expect(backNote, isNotNull);
    expect(backNote!.title, 'My note');
    expect(backNote.contentJson, '{"document":{}}');

    final backEvent = await calendar.getCalendarEvent(event.id);
    expect(backEvent, isNotNull);
    expect(backEvent!.title, 'Meeting');
    expect(backEvent.taskListId, list.id);
    expect(backEvent.start.dateTime, DateTime(2026, 3, 1, 9));
  });

  test('keepIncoming import overwrites a locally edited note', () async {
    final notes = SqliteNoteRepository();
    final note = Note(title: 'Original');
    await notes.createNote(note);

    final (json, _) = await BackupService().buildContent(ExportFormat.json);

    note.title = 'Local edit';
    await notes.updateNote(note);

    final summary = await ImportService()
        .import(jsonContent: json, policy: ConflictPolicy.keepIncoming);
    expect(summary.failed, 0);
    expect(summary.overwritten, 1);
    expect((await notes.getNote(note.id))!.title, 'Original');
  });
}
