import '../../data/database/database_manager.dart';
import 'focus_sync_service.dart';
import 'model_focus_session.dart';

/// Repository cho các phiên focus, theo nguyên tắc LOCAL-FIRST.
///
/// - Nguồn dữ liệu chính là SQLite: mọi phiên luôn được ghi xuống DB trước, nên
///   tính năng chạy được ngay cả khi offline / chưa cấu hình Firebase.
/// - Sau khi lưu local, ta CỐ GẮNG đồng bộ lên Firestore qua [FocusSyncService].
///   Nếu sync không khả dụng hoặc thất bại, phiên vẫn ở local với synced=false
///   và sẽ được thử lại qua [syncPending].
class FocusRepository {
  FocusRepository({
    DatabaseManager? databaseManager,
    FocusSyncService? syncService,
  })  : _db = databaseManager ?? DatabaseManager(),
        _sync = syncService ?? const NoOpFocusSyncService();

  final DatabaseManager _db;
  final FocusSyncService _sync;

  /// Lưu một phiên focus (local trước, rồi thử sync).
  Future<void> saveSession(FocusSession session) async {
    await _db.insertFocusSession(session);
    await _trySync(session);
  }

  /// Cố gắng đồng bộ một phiên; nếu thành công thì đánh dấu synced trong DB.
  Future<void> _trySync(FocusSession session) async {
    if (!_sync.isAvailable) return;
    final ok = await _sync.uploadSession(session);
    if (ok) {
      await _db.updateFocusSession(session.copyWith(synced: true));
    }
  }

  /// Thử đồng bộ lại tất cả phiên còn tồn đọng (ví dụ khi vừa đăng nhập hoặc
  /// vừa có mạng trở lại). An toàn để gọi bất cứ lúc nào.
  Future<void> syncPending() async {
    if (!_sync.isAvailable) return;
    final pending = await _db.unsyncedFocusSessions();
    for (final session in pending) {
      final ok = await _sync.uploadSession(session);
      if (ok) {
        await _db.updateFocusSession(session.copyWith(synced: true));
      }
    }
  }

  /// Tất cả phiên (mới nhất trước).
  Future<List<FocusSession>> allSessions() => _db.focusSessions();

  /// Phiên trong khoảng [start, end).
  Future<List<FocusSession>> sessionsBetween(DateTime start, DateTime end) =>
      _db.focusSessionsBetween(start, end);
}
