import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;

import '../bloc/form_status.dart';
import '../bloc/form_validators.dart';
import '../bloc/login_cubit.dart';
import '../data/auth_repository.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_widgets.dart';

/// Màn hình ĐĂNG NHẬP: email/password + nút Google, kèm liên kết sang
/// Đăng ký và Quên mật khẩu.
///
/// Dùng [BlocProvider] để tạo [LoginCubit] cục bộ cho màn hình này. Repository
/// được lấy từ context (đã cung cấp ở tầng trên qua RepositoryProvider).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Google Sign-In được hỗ trợ trên Android/iOS/web và (qua flow tự làm) trên
  /// Windows. Ta hiện nút ở các nền tảng này.
  bool get _googleSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows;
  }

  void _submit(BuildContext context) {
    // Ẩn bàn phím và bỏ chọn ô nhập trước khi submit.
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().logInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<LoginCubit, AuthFormState>(
          // Chỉ phản ứng khi trạng thái submit đổi (tránh lắng nghe thừa).
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == FormSubmissionStatus.failure) {
              _showError(context, state.errorMessage);
            }
            // Thành công: không làm gì ở đây. AuthGate sẽ tự chuyển sang Home.
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(context),
                        const SizedBox(height: 32),
                        AuthEmailField(
                          controller: _emailController,
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: 16),
                        AuthPasswordField(
                          controller: _passwordController,
                          validator: FormValidators.passwordLogin,
                          onFieldSubmitted: (_) => _submit(context),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _openForgotPassword(context),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Nút đăng nhập chính, gắn loading state từ cubit.
                        BlocBuilder<LoginCubit, AuthFormState>(
                          builder: (context, state) {
                            return AuthPrimaryButton(
                              label: 'Đăng nhập',
                              isLoading: state.isLoading,
                              onPressed: () => _submit(context),
                            );
                          },
                        ),
                        if (_googleSupported) ...[
                          const SizedBox(height: 20),
                          _orDivider(context),
                          const SizedBox(height: 20),
                          _googleButton(context),
                        ],
                        const SizedBox(height: 24),
                        _registerRow(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.calendar_month,
            size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Chào mừng trở lại',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Đăng nhập để tiếp tục quản lý thời gian của bạn',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _orDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('HOẶC',
              style: Theme.of(context).textTheme.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _googleButton(BuildContext context) {
    return BlocBuilder<LoginCubit, AuthFormState>(
      builder: (context, state) {
        return SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () => context.read<LoginCubit>().logInWithGoogle(),
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Đăng nhập bằng Google'),
          ),
        );
      },
    );
  }

  Widget _registerRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chưa có tài khoản?'),
        TextButton(
          onPressed: () => _openRegister(context),
          child: const Text('Đăng ký ngay'),
        ),
      ],
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _openForgotPassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _showError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message ?? 'Đã có lỗi xảy ra.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }
}
