import 'package:flutter/material.dart';

Color contrastColor(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  switch (brightness) {
    case Brightness.dark:
      return Colors.white;
    case Brightness.light:
      return Colors.black;
  }
}
