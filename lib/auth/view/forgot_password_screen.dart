import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/forgot_password_cubit.dart';
import '../bloc/form_status.dart';
import '../bloc/form_validators.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

/// Màn hình QUÊN MẬT KHẨU: nhập email để nhận liên kết đặt lại mật khẩu.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordCubit(context.read<AuthRepository>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context
          .read<ForgotPasswordCubit>()
          .sendResetEmail(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordCubit, AuthFormState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == FormSubmissionStatus.failure) {
              _showSnack(
                context,
                state.errorMessage ?? 'Đã có lỗi xảy ra.',
                isError: true,
              );
            }
          },
          builder: (context, state) {
            // Sau khi gửi thành công, thay form bằng màn hình xác nhận.
            if (state.status == FormSubmissionStatus.success) {
              return _successView(context);
            }
            return _formView(context, state);
          },
        ),
      ),
    );
  }

  Widget _formView(BuildContext context, AuthFormState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập email của bạn. Chúng tôi sẽ gửi liên kết để bạn '
                  'đặt lại mật khẩu.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AuthEmailField(
                  controller: _emailController,
                  validator: FormValidators.email,
                  onFieldSubmitted: (_) => _submit(context),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Gửi liên kết đặt lại',
                  isLoading: state.isLoading,
                  onPressed: () => _submit(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _successView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Đã gửi email!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Vui lòng kiểm tra hộp thư ${_emailController.text.trim()} '
              '(kể cả mục Spam) và làm theo hướng dẫn để đặt lại mật khẩu.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
  }
}
