import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class ExpandedImageColorAction extends StatelessWidget {
  const ExpandedImageColorAction({
    required this.handleImageSelect,
    required this.imageSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(
            ColorImageProvider.values.length,
            (i) => InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () => handleImageSelect(i),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  borderRadius: BorderRadius.circular(4.0),
                  elevation: imageSelected == ColorImageProvider.values[i] &&
                          colorSelectionMethod == ColorSelectionMethod.image
                      ? 3
                      : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image(
                        image: NetworkImage(ColorImageProvider.values[i].url),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
