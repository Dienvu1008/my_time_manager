import 'package:flutter/material.dart';

/// This class defines default tile to display in day view.
class RoundedEventTile extends StatelessWidget {
  /// Title of the tile.
  final String title;

  /// Description of the tile.
  final String description;

  /// Background color of tile.
  /// Default color is [Colors.blue]
  final Color backgroundColor;

  /// If same tile can have multiple events.
  /// In most cases this value will be 1 less than total events.
  final int totalEvents;

  /// Padding of the tile. Default padding is [EdgeInsets.zero]
  final EdgeInsets padding;

  /// Margin of the tile. Default margin is [EdgeInsets.zero]
  final EdgeInsets margin;

  /// Border radius of tile.
  final BorderRadius borderRadius;

  /// Style for title
  final TextStyle? titleStyle;

  /// Style for description
  final TextStyle? descriptionStyle;

  /// This is default tile to display in day view.
  const RoundedEventTile({
    Key? key,
    required this.title,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.description = "",
    this.borderRadius = BorderRadius.zero,
    this.totalEvents = 1,
    this.backgroundColor = const Color.fromARGB(255, 39, 4, 164),
    this.titleStyle,
    this.descriptionStyle,
  }) : super(key: key);

  Color contrastColor(Color backgroundColor) {
    final brightness = (backgroundColor.red * 299 +
            backgroundColor.green * 587 +
            backgroundColor.blue * 114) /
        1000;
    if (brightness >= 128) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(backgroundColor);
    final textTheme = TextTheme(
      labelSmall: TextStyle(color: labelColor),
    );

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Expanded(
              child: Text(
                title,
                style: textTheme.labelSmall,
                softWrap: true,
                overflow: TextOverflow.fade,
              ),
            ),
          if (description.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  description,
                  style: descriptionStyle ??
                      TextStyle(
                        fontSize: 11,
                        //color: backgroundColor.accent.withAlpha(200),
                      ),
                ),
              ),
            ),
          if (totalEvents > 1)
            Expanded(
              child: Text(
                "+${totalEvents - 1} more",
                style: (descriptionStyle ??
                        TextStyle(
                            //color: backgroundColor.accent.withAlpha(200),
                            ))
                    .copyWith(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
