import 'package:equatable/equatable.dart';

/// Trạng thái submit của một form xác thực.
enum FormSubmissionStatus {
  /// Chưa gửi / đang nhập liệu.
  initial,

  /// Đang xử lý (hiển thị loading, khóa nút bấm).
  loading,

  /// Thành công.
  success,

  /// Thất bại (kèm thông báo lỗi tiếng Việt trong [FormState.errorMessage]).
  failure,
}

/// State cơ sở dùng chung cho Login/Register/ForgotPassword cubit.
///
/// Tách riêng để tránh lặp code: cả ba form đều cần biết đang loading, thành
/// công hay lỗi, và (với forgot password) một cờ báo đã gửi email.
class AuthFormState extends Equatable {
  const AuthFormState({
    this.status = FormSubmissionStatus.initial,
    this.errorMessage,
  });

  final FormSubmissionStatus status;

  /// Thông báo lỗi tiếng Việt để hiển thị (ví dụ qua SnackBar). Null nếu không lỗi.
  final String? errorMessage;

  bool get isLoading => status == FormSubmissionStatus.loading;

  AuthFormState copyWith({
    FormSubmissionStatus? status,
    String? errorMessage,
  }) {
    return AuthFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
