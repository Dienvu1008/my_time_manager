import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';

/// Quản lý trạng thái submit của màn hình ĐĂNG NHẬP.
///
/// Chỉ lo phần "gửi form": loading, thành công, lỗi. Việc validation định dạng
/// input do [FormValidators] + TextFormField xử lý ngay trên UI.
class LoginCubit extends Cubit<AuthFormState> {
  LoginCubit(this._authRepository) : super(const AuthFormState());

  final AuthRepository _authRepository;

  /// Đăng nhập bằng email/mật khẩu.
  Future<void> logInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: FormSubmissionStatus.loading));
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      emit(state.copyWith(status: FormSubmissionStatus.success));
      // Không cần điều hướng ở đây: AuthGate sẽ tự chuyển sang Home khi
      // AuthBloc nhận được sự kiện đăng nhập thành công.
    } on AuthFailure catch (f) {
      emit(state.copyWith(
        status: FormSubmissionStatus.failure,
        errorMessage: f.message,
      ));
    }
  }

  /// Đăng nhập bằng Google (Android native hoặc Windows OAuth).
  Future<void> logInWithGoogle() async {
    emit(state.copyWith(status: FormSubmissionStatus.loading));
    try {
      await _authRepository.signInWithGoogle();
      emit(state.copyWith(status: FormSubmissionStatus.success));
    } on AuthFailure catch (f) {
      // Nếu người dùng chủ động hủy thì quay về initial, không báo lỗi đỏ.
      if (f == AuthFailure.cancelled) {
        emit(state.copyWith(status: FormSubmissionStatus.initial));
      } else {
        emit(state.copyWith(
          status: FormSubmissionStatus.failure,
          errorMessage: f.message,
        ));
      }
    }
  }
}
