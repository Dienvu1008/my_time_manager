import 'package:sqflite/sqflite.dart';

import '../../../domain/models/model_note.dart';
import '../device_id_helper.dart';

/// DAO cho bảng `notes`. Trích xuất từ `DatabaseManager` (Core Track C4).
///
/// Mỗi DAO sở hữu: tạo bảng (static, gọi bởi DatabaseManager lúc schema setup)
/// + CRUD cho một aggregate. DAO không phụ thuộc DatabaseManager — chỉ nhận
/// một hàm trả về `Future<Database>` (thường là `() => DatabaseManager().database`
/// trong production, hoặc in-memory DB trong test).
class NoteDao {
  NoteDao(this._getDatabase);

  final Future<Database> Function() _getDatabase;

  /// Tạo bảng — gọi bởi DatabaseManager trong `_onCreate` / `_onUpgrade`.
  static Future<void> createTable(Database db) async {
    await db.execute(
      '''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT,
        contentJson TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        deviceId TEXT
      )
      ''',
    );
  }

  Future<List<Note>> getAll() async {
    final db = await _getDatabase();
    final maps = await db.query('notes', orderBy: 'updatedAt DESC');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<Note?> getById(String id) async {
    final db = await _getDatabase();
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<void> insert(Note note) async {
    final db = await _getDatabase();
    await db.insert(
      'notes',
      withDeviceId(note.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Note note) async {
    final db = await _getDatabase();
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _getDatabase();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
