import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/form_status.dart';
import '../bloc/form_validators.dart';
import '../bloc/register_cubit.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

/// Màn hình ĐĂNG KÝ tài khoản mới bằng email/mật khẩu.
///
/// Sau khi đăng ký thành công, Firebase tự đăng nhập người dùng, nên AuthGate
/// sẽ chuyển thẳng vào Home. Ta đóng màn hình này để tránh nó nằm lại trên stack.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(context.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterCubit>().signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: BlocListener<RegisterCubit, AuthFormState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == FormSubmissionStatus.failure) {
              _showError(context, state.errorMessage);
            } else if (state.status == FormSubmissionStatus.success) {
              // Đóng màn hình đăng ký; AuthGate lo phần chuyển vào Home.
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Điền thông tin để bắt đầu',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AuthEmailField(
                          controller: _emailController,
                          validator: FormValidators.email,
                        ),
                        const SizedBox(height: 16),
                        AuthPasswordField(
                          controller: _passwordController,
                          validator: FormValidators.passwordRegister,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        // Xác nhận mật khẩu: so khớp với ô mật khẩu ở trên.
                        AuthPasswordField(
                          controller: _confirmController,
                          labelText: 'Nhập lại mật khẩu',
                          validator: (value) => FormValidators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          onFieldSubmitted: (_) => _submit(context),
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<RegisterCubit, AuthFormState>(
                          builder: (context, state) {
                            return AuthPrimaryButton(
                              label: 'Đăng ký',
                              isLoading: state.isLoading,
                              onPressed: () => _submit(context),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Đã có tài khoản?'),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Đăng nhập'),
                            ),
                          ],
                        ),
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
