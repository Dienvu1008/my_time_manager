import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

/// "Cổng" xác thực đặt ngay dưới MaterialApp.
///
/// Dựa trên [AuthBloc], nó tự động quyết định hiển thị màn hình nào:
/// - [AuthStatus.unknown]  -> màn hình chờ (đang khôi phục phiên đăng nhập).
/// - [AuthStatus.authenticated]   -> [child] (chính là Home của ứng dụng).
/// - [AuthStatus.unauthenticated] -> [LoginScreen].
///
/// Đây là nơi hiện thực yêu cầu "tự động chuyển hướng dựa trên trạng thái đăng
/// nhập". Vì [AuthBloc] lắng nghe Firebase, mọi thay đổi (đăng nhập, đăng xuất)
/// đều khiến widget này build lại và chuyển màn hình phù hợp — không cần gọi
/// Navigator thủ công ở từng chỗ.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  /// Giao diện chính khi đã đăng nhập (Home đã được dựng đầy đủ tham số).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Chỉ build lại khi status thay đổi để tránh rebuild thừa.
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            return child;
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.unknown:
            return const _SplashScreen();
        }
      },
    );
  }
}

/// Màn hình chờ đơn giản trong lúc Firebase khôi phục phiên đăng nhập lúc mở app.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
