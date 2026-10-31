import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_localizations.dart';

/// Trường chọn ngày có thể xóa: hiển thị `dd/MM/yyyy` hoặc "Chưa đặt"; chạm để
/// mở date picker, nút xóa (chỉ khi có giá trị) trả về `null`.
///
/// [clearable] = false hides the clear button (required dates);
/// [errorText] shows a validation message under the field.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
    this.clearable = true,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool clearable;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = value;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: current == null || !clearable
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l.clearDate,
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(current == null
            ? l.dateNotSet
            : DateFormat('dd/MM/yyyy').format(current)),
      ),
    );
  }
}
