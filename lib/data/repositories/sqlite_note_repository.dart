import '../../domain/repositories/note_repository.dart';
import '../../domain/models/model_note.dart';
import '../database/database_manager.dart';
import '../database/daos/note_dao.dart';

/// SQLite-backed [NoteRepository]. Thin adapter over [NoteDao].
class SqliteNoteRepository implements NoteRepository {
  SqliteNoteRepository({DatabaseManager? databaseManager})
      : _dao = NoteDao(() => (databaseManager ?? DatabaseManager()).database);

  final NoteDao _dao;

  @override
  Future<List<Note>> getNotes() => _dao.getAll();

  @override
  Future<Note?> getNote(String id) => _dao.getById(id);

  @override
  Future<void> createNote(Note note) => _dao.insert(note);

  @override
  Future<void> updateNote(Note note) => _dao.update(note);

  @override
  Future<void> deleteNote(String id) => _dao.delete(id);
}
