import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class ColorSeedButton extends StatelessWidget {
  const ColorSeedButton({
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleColorSelect;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.palette_outlined,
        //color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Select a seed color',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(ColorSeed.values.length, (index) {
          ColorSeed currentColor = ColorSeed.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentColor != colorSelected ||
                colorSelectionMethod != ColorSelectionMethod.colorSeed,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    currentColor == colorSelected &&
                            colorSelectionMethod != ColorSelectionMethod.image
                        ? Icons.color_lens
                        : Icons.color_lens_outlined,
                    color: currentColor.color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(currentColor.label),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleColorSelect,
    );
  }
}

class ColorSeedSubmenuButton extends StatelessWidget {
  const ColorSeedSubmenuButton({
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleColorSelect;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      menuChildren: List.generate(ColorSeed.values.length, (index) {
        ColorSeed currentColor = ColorSeed.values[index];

        return MenuItemButton(
          onPressed: currentColor != colorSelected ||
                  colorSelectionMethod != ColorSelectionMethod.colorSeed
              ? () => handleColorSelect(index)
              : null,
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(
                  currentColor == colorSelected &&
                          colorSelectionMethod != ColorSelectionMethod.image
                      ? Icons.color_lens
                      : Icons.color_lens_outlined,
                  color: currentColor.color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(currentColor.label),
              ),
            ],
          ),
        );
      }),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(colorSelected.label),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                Icons.color_lens,
                color: colorSelected.color,
              ),
            ),
          )
        ],
      ),
    );
  }
}
