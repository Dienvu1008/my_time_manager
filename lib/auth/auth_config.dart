/// Cấu hình cho phần xác thực.
///
/// TÁCH RIÊNG để bạn dễ điền giá trị mà không phải lục trong code logic.
class AuthConfig {
  const AuthConfig._();

  /// CỜ TẠM: bỏ qua màn hình đăng nhập để test các tính năng khác khi Firebase
  /// chưa được cấu hình.
  ///
  /// Khi = true, app vào thẳng Home mà không qua AuthGate/Login.
  /// ĐẶT LẠI = false (hoặc bỏ --dart-define) sau khi đã cấu hình Firebase xong.
  ///
  /// Có thể bật khi chạy mà không cần sửa code:
  ///   flutter run -d windows --dart-define=BYPASS_AUTH=true
  static const bool bypassAuth = bool.fromEnvironment(
    'BYPASS_AUTH',
    defaultValue: true,
  );

  /// OAuth Client ID loại "Desktop app" tạo trong Google Cloud Console.
  /// CHỈ dùng cho Google Sign-In trên Windows (flow OAuth thủ công).
  ///
  /// Cách lấy (xem hướng dẫn chi tiết ở phần cuối câu trả lời):
  ///   Google Cloud Console > APIs & Services > Credentials
  ///   > Create Credentials > OAuth client ID > Application type: Desktop app
  ///
  /// Dán chuỗi có dạng: 'xxxxxxxx-xxxx.apps.googleusercontent.com'
  ///
  /// Nếu để trống, nút Google trên Windows sẽ báo lỗi "chưa cấu hình" một cách
  /// an toàn thay vì crash. Email/password vẫn hoạt động bình thường.
  static const String googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );
}
