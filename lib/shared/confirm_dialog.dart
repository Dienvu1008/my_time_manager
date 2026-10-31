import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

/// Hộp thoại xác nhận chung (Cancel / [confirmLabel]). Trả về `true` khi người
/// dùng xác nhận, `false` khi hủy hoặc đóng hộp thoại.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
}) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
