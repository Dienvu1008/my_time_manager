@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/domain/models/model_note.dart';
import 'package:my_time_manager/data/repositories/sqlite_note_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Contract test for the SQLite-backed NoteRepository against an in-memory DB.
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

  test('create + getNote round-trips a note', () async {
    final repo = SqliteNoteRepository();
    final n = Note(title: 'My note', contentJson: '{}');

    await repo.createNote(n);
    final fetched = await repo.getNote(n.id);

    expect(fetched, isNotNull);
    expect(fetched!.id, n.id);
    expect(fetched.title, 'My note');
  });

  test('getNotes returns created notes', () async {
    final repo = SqliteNoteRepository();
    final a = Note(title: 'A', contentJson: '{}');
    final b = Note(title: 'B', contentJson: '{}');
    await repo.createNote(a);
    await repo.createNote(b);

    final all = await repo.getNotes();
    expect(all.map((n) => n.id), containsAll([a.id, b.id]));
  });

  test('updateNote persists changes', () async {
    final repo = SqliteNoteRepository();
    final n = Note(title: 'Before', contentJson: '{}');
    await repo.createNote(n);

    await repo.updateNote(n.copyWith(title: 'After'));

    final fetched = await repo.getNote(n.id);
    expect(fetched!.title, 'After');
  });

  test('deleteNote removes the note', () async {
    final repo = SqliteNoteRepository();
    final n = Note(title: 'X', contentJson: '{}');
    await repo.createNote(n);

    await repo.deleteNote(n.id);

    expect(await repo.getNote(n.id), isNull);
  });
}
