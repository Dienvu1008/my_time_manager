import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

/// Bảng màu dùng chung cho mục tiêu / dự án.
const kEntityColorPalette = <Color>[
  Colors.white,
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
  Colors.blueGrey,
];

/// Chọn một màu từ [kEntityColorPalette]. Nếu [value] không nằm trong bảng màu
/// (vd. dữ liệu cũ), nó được thêm vào đầu danh sách để vẫn hiển thị được.
class ColorChoiceField extends StatelessWidget {
  const ColorChoiceField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final selected = value.toARGB32();
    final inPalette =
        kEntityColorPalette.any((c) => c.toARGB32() == selected);
    final colors = [if (!inPalette) value, ...kEntityColorPalette];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.color, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < colors.length; i++)
              _swatch(
                context,
                colors[i],
                isSelected: colors[i].toARGB32() == selected,
                label: '${l.color} ${i + 1}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _swatch(BuildContext context, Color color,
      {required bool isSelected, required String label}) {
    final outline = Theme.of(context).colorScheme.outline;
    // Màu check tương phản với nền của ô màu.
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onChanged(color),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: outline, width: isSelected ? 3 : 1),
          ),
          child: isSelected
              ? ExcludeSemantics(
                  child: Icon(Icons.check, size: 20, color: checkColor))
              : null,
        ),
      ),
    );
  }
}
