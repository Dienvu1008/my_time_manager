import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';

/// Quản lý trạng thái submit của màn hình ĐĂNG KÝ.
class RegisterCubit extends Cubit<AuthFormState> {
  RegisterCubit(this._authRepository) : super(const AuthFormState());

  final AuthRepository _authRepository;

  /// Tạo tài khoản mới bằng email/mật khẩu.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: FormSubmissionStatus.loading));
    try {
      await _authRepository.signUpWithEmail(email: email, password: password);
      // Đăng ký thành công -> Firebase tự đăng nhập luôn -> AuthGate chuyển
      // sang Home. Ta chỉ cần báo success để UI có thể đóng màn hình.
      emit(state.copyWith(status: FormSubmissionStatus.success));
    } on AuthFailure catch (f) {
      emit(state.copyWith(
        status: FormSubmissionStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
