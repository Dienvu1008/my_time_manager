import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Đại diện cho một lỗi xác thực đã được chuyển sang thông báo tiếng Việt,
/// sẵn sàng để hiển thị cho người dùng.
///
/// Toàn bộ tầng UI chỉ làm việc với [AuthFailure] thay vì bắt trực tiếp
/// [FirebaseAuthException]. Nhờ vậy, phần hiển thị lỗi được tập trung một chỗ,
/// dễ bảo trì và luôn bằng tiếng Việt.
///
/// Kế thừa [Equatable] để có thể so sánh bằng `==` (ví dụ kiểm tra
/// `failure == AuthFailure.cancelled`).
class AuthFailure extends Equatable implements Exception {
  const AuthFailure(this.message);

  /// Thông báo lỗi thân thiện, bằng tiếng Việt, dùng để hiển thị trực tiếp.
  final String message;

  /// Tạo [AuthFailure] từ [FirebaseAuthException] bằng cách ánh xạ mã lỗi
  /// (error code) của Firebase sang thông báo tiếng Việt tương ứng.
  ///
  /// Danh sách mã lỗi tham khảo từ tài liệu Firebase Auth. Với những mã không
  /// được liệt kê, ta trả về một thông báo chung để tránh lộ chi tiết kỹ thuật.
  factory AuthFailure.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      // --- Lỗi khi đăng nhập ---
      case 'invalid-email':
        return const AuthFailure('Địa chỉ email không hợp lệ.');
      case 'user-disabled':
        return const AuthFailure('Tài khoản này đã bị vô hiệu hóa.');
      case 'user-not-found':
        return const AuthFailure('Không tìm thấy tài khoản với email này.');
      case 'wrong-password':
        return const AuthFailure('Mật khẩu không chính xác.');
      // Firebase mới gộp "sai email hoặc mật khẩu" vào một mã duy nhất để
      // tránh lộ việc email có tồn tại hay không (chống dò tài khoản).
      case 'invalid-credential':
        return const AuthFailure(
            'Email hoặc mật khẩu không chính xác. Vui lòng thử lại.');

      // --- Lỗi khi đăng ký ---
      case 'email-already-in-use':
        return const AuthFailure('Email này đã được đăng ký. Vui lòng đăng nhập.');
      case 'operation-not-allowed':
        return const AuthFailure(
            'Phương thức đăng nhập này chưa được bật. Vui lòng liên hệ hỗ trợ.');
      case 'weak-password':
        return const AuthFailure('Mật khẩu quá yếu (cần ít nhất 6 ký tự).');

      // --- Lỗi liên quan tới nhà cung cấp (Google) ---
      case 'account-exists-with-different-credential':
        return const AuthFailure(
            'Email này đã được đăng ký bằng phương thức khác. '
            'Hãy đăng nhập bằng phương thức ban đầu.');
      case 'credential-already-in-use':
        return const AuthFailure(
            'Thông tin đăng nhập này đã được liên kết với tài khoản khác.');

      // --- Lỗi mạng / hệ thống ---
      case 'network-request-failed':
        return const AuthFailure(
            'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.');
      case 'too-many-requests':
        return const AuthFailure(
            'Bạn đã thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.');
      case 'requires-recent-login':
        return const AuthFailure(
            'Thao tác này yêu cầu bạn đăng nhập lại để xác minh.');

      default:
        return AuthFailure(
            'Đã có lỗi xảy ra. Vui lòng thử lại. (${e.code})');
    }
  }

  /// Lỗi khi người dùng chủ động hủy flow đăng nhập (ví dụ đóng cửa sổ Google).
  /// Đây không phải lỗi thật sự nên UI có thể chọn bỏ qua, không hiển thị.
  static const AuthFailure cancelled =
      AuthFailure('Đã hủy đăng nhập.');

  /// Lỗi chung cho các trường hợp không xác định (không phải từ Firebase).
  static const AuthFailure unknown =
      AuthFailure('Đã có lỗi không xác định xảy ra. Vui lòng thử lại.');

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthFailure(message: $message)';
}
