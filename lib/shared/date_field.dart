import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_localizations.dart';

/// Trường chọn ngày có thể xóa: hiển thị `dd/MM/yyyy` hoặc "Chưa đặt"; chạm để
/// mở date picker, nút xóa (chỉ khi có giá trị) trả về `null`.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

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
          suffixIcon: current == null
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
