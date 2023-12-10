import 'package:flutter/material.dart';

class Material3Button extends StatelessWidget {
  const Material3Button({
    required this.handleMaterialVersionChange,
    this.showTooltipBelow = true,
  });

  final void Function() handleMaterialVersionChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final useMaterial3 = Theme.of(context).useMaterial3;
    return Tooltip(
      preferBelow: showTooltipBelow,
      message: 'Switch to Material ${useMaterial3 ? 2 : 3}',
      child: IconButton(
        icon: useMaterial3
            ? const Icon(Icons.filter_2)
            : const Icon(Icons.filter_3),
        onPressed: handleMaterialVersionChange,
      ),
    );
  }
}
