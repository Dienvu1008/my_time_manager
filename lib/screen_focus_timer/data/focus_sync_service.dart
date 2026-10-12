import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/model_focus_session.dart';

/// Giao diện đồng bộ phiên focus lên đám mây.
///
/// Tách interface để tầng repository không phụ thuộc trực tiếp vào Firestore.
/// Nhờ đó khi Firebase CHƯA được cấu hình (hoặc chưa đăng nhập), ta dùng
/// [NoOpFocusSyncService] và mọi thứ vẫn chạy bình thường (local-only).
abstract class FocusSyncService {
  /// True nếu hiện có thể đồng bộ (Firebase sẵn sàng + đã đăng nhập).
  bool get isAvailable;

  /// Đẩy một phiên lên đám mây. Trả về true nếu thành công.
  Future<bool> uploadSession(FocusSession session);
}

/// Bản cài đặt "không làm gì" — dùng khi chưa thể sync.
/// Luôn báo không khả dụng để repository bỏ qua bước sync.
class NoOpFocusSyncService implements FocusSyncService {
  const NoOpFocusSyncService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> uploadSession(FocusSession session) async => false;
}

/// Đồng bộ qua Cloud Firestore.
///
/// Cấu trúc dữ liệu: users/{uid}/focus_sessions/{sessionId}
/// Mỗi người dùng có collection riêng, đảm bảo tách biệt dữ liệu.
///
/// LƯU Ý: chỉ hoạt động khi Firebase đã được cấu hình (flutterfire configure)
/// VÀ người dùng đã đăng nhập. Nếu chưa, [isAvailable] trả về false.
class FirestoreFocusSyncService implements FocusSyncService {
  FirestoreFocusSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  bool get isAvailable => _auth.currentUser != null;

  @override
  Future<bool> uploadSession(FocusSession session) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('focus_sessions')
          .doc(session.id)
          .set(session.toFirestore());
      return true;
    } catch (_) {
      // Sync thất bại (mất mạng...) không được làm hỏng luồng chính. Phiên vẫn
      // nằm trong SQLite với synced=false và sẽ được thử lại lần sau.
      return false;
    }
  }
}
