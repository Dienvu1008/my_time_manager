import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

/// Hộp thoại xác nhận chung (Cancel / [confirmLabel]). Trả về `true` khi người
/// dùng xác nhận, `false` khi hủy hoặc đóng hộp thoại.
///
/// [title] (tùy chọn) hiện tiêu đề; [destructive] tô nút xác nhận bằng màu
/// lỗi cho thao tác xóa (Phase DR2). Mặc định giữ nguyên hành vi cũ.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,
  bool destructive = false,
}) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
