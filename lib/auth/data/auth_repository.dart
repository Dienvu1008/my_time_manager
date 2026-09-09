import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_failure.dart';
import 'google_desktop_sign_in.dart';

/// Lớp trung tâm bọc toàn bộ thao tác xác thực.
///
/// Toàn bộ phần còn lại của ứng dụng (bloc, UI) chỉ nói chuyện với repository
/// này chứ không gọi thẳng FirebaseAuth. Ưu điểm:
/// - Tách biệt logic Firebase khỏi UI (dễ test, dễ thay backend sau này).
/// - Mọi lỗi được chuẩn hóa thành [AuthFailure] bằng tiếng Việt.
/// - Che giấu sự khác biệt giữa Google Sign-In trên Android và trên Windows.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    this.desktopClientId,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: const [calendarScope]);

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Scope OAuth để đọc/ghi Google Calendar (dùng cho đồng bộ sự kiện).
  static const String calendarScope =
      'https://www.googleapis.com/auth/calendar';

  /// OAuth Client ID loại "Desktop app" (lấy từ Google Cloud Console).
  /// Chỉ cần trên Windows. Có thể null trên các nền tảng khác.
  final String? desktopClientId;

  /// Stream phát ra [User] mỗi khi trạng thái đăng nhập thay đổi
  /// (đăng nhập, đăng xuất, token refresh...). Firebase tự khôi phục phiên
  /// đăng nhập từ bộ nhớ cục bộ khi app khởi động lại — đây chính là cơ chế
  /// "persist session" mà ta không cần tự viết.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Người dùng hiện tại (null nếu chưa đăng nhập).
  User? get currentUser => _firebaseAuth.currentUser;

  /// True nếu nền tảng hiện tại là Windows desktop (cần flow OAuth thủ công).
  bool get _isWindows => !kIsWeb && Platform.isWindows;

  /// Đăng nhập bằng email và mật khẩu.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  /// Đăng ký tài khoản mới bằng email và mật khẩu.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  /// Gửi email đặt lại mật khẩu.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  /// Đăng nhập bằng Google. Tự động chọn flow phù hợp với nền tảng:
  /// - Windows: OAuth loopback thủ công ([GoogleDesktopSignIn]).
  /// - Android/iOS: plugin google_sign_in native.
  Future<void> signInWithGoogle() async {
    try {
      final OAuthCredential credential = _isWindows
          ? await _googleCredentialForDesktop()
          : await _googleCredentialForMobile();

      await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    } on AuthFailure {
      rethrow; // đã là lỗi tiếng Việt, giữ nguyên
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }

  /// Tạo credential Google trên Windows qua flow OAuth thủ công.
  Future<OAuthCredential> _googleCredentialForDesktop() async {
    final clientId = desktopClientId;
    if (clientId == null || clientId.isEmpty) {
      throw const AuthFailure(
          'Chưa cấu hình Google Client ID cho Windows. Vui lòng liên hệ hỗ trợ.');
    }

    final tokens = await GoogleDesktopSignIn(clientId: clientId).signIn();
    return GoogleAuthProvider.credential(
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
  }

  /// Tạo credential Google trên Android/iOS qua plugin native.
  Future<OAuthCredential> _googleCredentialForMobile() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    // Người dùng đóng hộp thoại chọn tài khoản -> coi như hủy.
    if (googleUser == null) {
      throw AuthFailure.cancelled;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    return GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  /// Lấy một access token Google có scope Calendar để đồng bộ sự kiện.
  ///
  /// - Android/iOS: dùng plugin `google_sign_in` — thử đăng nhập im lặng
  ///   trước; nếu chưa có phiên thì mở hộp thoại chọn tài khoản; đảm bảo đã cấp
  ///   scope calendar rồi trả `authentication.accessToken`.
  /// - Windows: chạy lại flow OAuth loopback kèm scope calendar để lấy access
  ///   token mới (không có refresh token nên mỗi lần lấy là tương tác).
  ///
  /// Trả về null nếu không lấy được (người dùng hủy, chưa cấu hình, lỗi mạng).
  Future<String?> calendarAccessToken() async {
    try {
      if (_isWindows) {
        final clientId = desktopClientId;
        if (clientId == null || clientId.isEmpty) return null;
        final tokens = await GoogleDesktopSignIn(
          clientId: clientId,
          extraScopes: const [calendarScope],
        ).signIn();
        return tokens.accessToken;
      }

      // Mobile: ưu tiên phiên im lặng, nếu chưa có thì đăng nhập tương tác.
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) return null;

      // Đảm bảo đã được cấp scope calendar.
      final granted = await _googleSignIn.canAccessScopes(const [calendarScope]);
      if (!granted) {
        final ok = await _googleSignIn.requestScopes(const [calendarScope]);
        if (!ok) return null;
      }

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Đăng xuất khỏi cả Firebase lẫn Google (nếu đang đăng nhập Google trên mobile).
  Future<void> signOut() async {
    try {
      // Trên mobile cần signOut khỏi google_sign_in để lần sau hiện lại
      // hộp thoại chọn tài khoản. Trên Windows không dùng plugin nên bỏ qua.
      if (!_isWindows) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
    } catch (_) {
      throw AuthFailure.unknown;
    }
  }
}
