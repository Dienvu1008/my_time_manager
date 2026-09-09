import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

/// Màn hình tài khoản: hiển thị thông tin người dùng đang đăng nhập và nút
/// Đăng xuất. Được nhúng vào trang "Account" của phần Cài đặt.
///
/// Đăng xuất chỉ cần bắn [AuthSignOutRequested] lên [AuthBloc]; sau đó
/// AuthGate tự chuyển về màn hình đăng nhập nên không cần điều hướng thủ công.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy user hiện tại từ AuthBloc để hiển thị.
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    if (user == null) {
      // Trường hợp hiếm: chưa đăng nhập mà vẫn vào được đây.
      return const Center(child: Text('Chưa đăng nhập.'));
    }

    final theme = Theme.of(context);
    final displayName = user.displayName?.trim();
    final email = user.email ?? 'Không có email';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ảnh đại diện: dùng photoURL nếu có (đăng nhập Google), nếu không
              // thì hiển thị chữ cái đầu.
              CircleAvatar(
                radius: 44,
                backgroundImage: (user.photoURL != null)
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: (user.photoURL == null)
                    ? Text(
                        _initials(displayName, email),
                        style: theme.textTheme.headlineMedium,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              if (displayName != null && displayName.isNotEmpty) ...[
                Text(displayName, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
              ],
              Text(
                email,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  onPressed: () => _confirmSignOut(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hỏi xác nhận trước khi đăng xuất để tránh bấm nhầm.
  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  /// Lấy chữ cái đầu để hiển thị khi không có ảnh đại diện.
  String _initials(String? name, String email) {
    if (name != null && name.isNotEmpty) {
      return name.characters.first.toUpperCase();
    }
    if (email.isNotEmpty) {
      return email.characters.first.toUpperCase();
    }
    return '?';
  }
}
