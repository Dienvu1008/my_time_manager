import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

/// AuthBloc theo dõi trạng thái đăng nhập TOÀN CỤC của ứng dụng.
///
/// Nó lắng nghe [AuthRepository.authStateChanges] và phát ra [AuthState] tương
/// ứng. UI (đặc biệt là AuthGate) dựa vào state này để quyết định hiển thị màn
/// đăng nhập hay màn hình chính.
///
/// Lưu ý phân vai: AuthBloc KHÔNG xử lý form đăng nhập/đăng ký (việc đó thuộc
/// các Cubit riêng). Nó chỉ trả lời câu hỏi: "Người dùng đã đăng nhập chưa?".

// ----------------------------- STATE -----------------------------

/// Ba trạng thái xác thực có thể có của ứng dụng.
enum AuthStatus {
  /// Chưa xác định (đang chờ Firebase khôi phục phiên khi khởi động).
  unknown,

  /// Đã đăng nhập.
  authenticated,

  /// Chưa đăng nhập.
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState._({required this.status, this.user});

  /// Trạng thái ban đầu khi app vừa mở, chưa biết đã đăng nhập hay chưa.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  /// Đã đăng nhập, kèm thông tin [user].
  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  /// Chưa đăng nhập.
  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final User? user;

  @override
  List<Object?> get props => [status, user?.uid];
}

// ----------------------------- EVENTS -----------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Phát ra nội bộ mỗi khi stream Firebase báo thay đổi trạng thái đăng nhập.
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User? user;

  @override
  List<Object?> get props => [user?.uid];
}

/// Yêu cầu đăng xuất (được UI kích hoạt, ví dụ nút Sign Out).
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

// ----------------------------- BLOC -----------------------------

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignOutRequested>(_onSignOutRequested);

    // Đăng ký lắng nghe stream trạng thái đăng nhập của Firebase. Mỗi lần có
    // thay đổi, ta đẩy một event nội bộ để cập nhật state một cách nhất quán
    // qua cơ chế event của bloc.
    _userSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _userSubscription;

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(event.user != null
        ? AuthState.authenticated(event.user!)
        : const AuthState.unauthenticated());
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Không cần emit thủ công: sau khi signOut, stream authStateChanges sẽ
    // phát ra null và _onUserChanged sẽ chuyển state sang unauthenticated.
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
