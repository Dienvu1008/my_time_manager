import 'package:flutter/material.dart';

class BrightnessButton extends StatelessWidget {
  const BrightnessButton({
    required this.handleBrightnessChange,
    this.showTooltipBelow = true,
  });

  final Function handleBrightnessChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final isBright = Theme.of(context).brightness == Brightness.light;
    return Tooltip(
      preferBelow: showTooltipBelow,
      message: 'Toggle brightness',
      child: IconButton(
        icon: isBright
            ? const Icon(Icons.dark_mode_outlined)
            : const Icon(Icons.light_mode_outlined),
        onPressed: () => handleBrightnessChange(!isBright),
      ),
    );
  }
}

class BrightnessMenuItemButton extends StatelessWidget {
  const BrightnessMenuItemButton({
    required this.handleBrightnessChange,
    this.showTooltipBelow = true,
  });

  final Function handleBrightnessChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final isBright = Theme.of(context).brightness == Brightness.light;
    return MenuItemButton(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text('Brightness'),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          // Switch(
          //     value: isBright,
          //     onChanged: (value) {
          //       handleBrightnessChange(value);
          //     })
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child:            Switch(
                  value: isBright,
                  onChanged: (value) {
                    handleBrightnessChange(value);
                  })
            ),
          )
        ],
      ),
    );
  }
}
