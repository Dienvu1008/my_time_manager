import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_failure.dart';
import '../data/auth_repository.dart';
import 'form_status.dart';

/// Quản lý trạng thái submit của màn hình QUÊN MẬT KHẨU.
///
/// Khi status == success nghĩa là email đặt lại mật khẩu đã được gửi đi.
class ForgotPasswordCubit extends Cubit<AuthFormState> {
  ForgotPasswordCubit(this._authRepository) : super(const AuthFormState());

  final AuthRepository _authRepository;

  Future<void> sendResetEmail(String email) async {
    emit(state.copyWith(status: FormSubmissionStatus.loading));
    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(state.copyWith(status: FormSubmissionStatus.success));
    } on AuthFailure catch (f) {
      emit(state.copyWith(
        status: FormSubmissionStatus.failure,
        errorMessage: f.message,
      ));
    }
  }
}
