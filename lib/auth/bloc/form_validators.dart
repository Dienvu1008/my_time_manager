/// Các hàm validation dùng chung cho toàn bộ form xác thực.
///
/// Trả về `null` nghĩa là hợp lệ; ngược lại trả về chuỗi thông báo lỗi
/// tiếng Việt để hiển thị ngay dưới ô nhập (dùng với `TextFormField.validator`).
class FormValidators {
  const FormValidators._();

  /// Biểu thức kiểm tra định dạng email cơ bản (đủ dùng cho phía client;
  /// Firebase sẽ kiểm tra kỹ hơn ở phía server).
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.a-zA-Z0-9!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9]'
    r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Kiểm tra email: không rỗng và đúng định dạng.
  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (!_emailRegExp.hasMatch(input)) {
      return 'Email không đúng định dạng.';
    }
    return null;
  }

  /// Kiểm tra mật khẩu khi ĐĂNG NHẬP: chỉ cần không rỗng.
  static String? passwordLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    return null;
  }

  /// Kiểm tra mật khẩu khi ĐĂNG KÝ: yêu cầu độ mạnh tối thiểu.
  /// Firebase bắt buộc tối thiểu 6 ký tự; ta thêm ràng buộc có chữ và số
  /// để mật khẩu an toàn hơn.
  static String? passwordRegister(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    if (input.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (!input.contains(RegExp(r'[0-9]')) ||
        !input.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Mật khẩu nên gồm cả chữ và số.';
    }
    return null;
  }

  /// Kiểm tra ô "xác nhận mật khẩu" khớp với mật khẩu gốc.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }
    if (value != original) {
      return 'Mật khẩu nhập lại không khớp.';
    }
    return null;
  }
}
