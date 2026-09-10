import '../../domain/repositories/note_repository.dart';
import '../database/database_manager.dart';
import '../models/model_note.dart';

/// SQLite-backed [NoteRepository]. Thin adapter over [DatabaseManager].
class SqliteNoteRepository implements NoteRepository {
  SqliteNoteRepository({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  @override
  Future<List<Note>> getNotes() => _db.notes();

  @override
  Future<Note?> getNote(String id) => _db.note(id);

  @override
  Future<void> createNote(Note note) => _db.insertNote(note);

  @override
  Future<void> updateNote(Note note) => _db.updateNote(note);

  @override
  Future<void> deleteNote(String id) => _db.deleteNote(id);
}
