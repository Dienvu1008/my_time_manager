import '../../data/models/model_note.dart';

/// Domain boundary for **notes** (rich-text notes attachable to tasks, time
/// intervals, and calendar events via their `noteIds` lists).
///
/// Callers (UI, and — in the future — AI tools) depend on this interface, never
/// on [DatabaseManager] / SQLite directly.
abstract class NoteRepository {
  /// All notes, most recently updated first.
  Future<List<Note>> getNotes();

  /// A single note by id, or null if it does not exist.
  Future<Note?> getNote(String id);

  /// Create a new note.
  Future<void> createNote(Note note);

  /// Update an existing note.
  Future<void> updateNote(Note note);

  /// Delete a note.
  Future<void> deleteNote(String id);
}
