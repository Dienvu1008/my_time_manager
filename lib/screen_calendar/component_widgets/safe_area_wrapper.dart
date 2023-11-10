import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/safe_area_option.dart';

class SafeAreaWrapper extends SafeArea {
  SafeAreaWrapper({
    SafeAreaOption option = const SafeAreaOption(),
    required Widget child,
  }) : super(
          left: option.left,
          top: option.top,
          right: option.right,
          bottom: option.bottom,
          minimum: option.minimum,
          maintainBottomViewPadding: option.maintainBottomViewPadding,
          child: child,
        );
}

