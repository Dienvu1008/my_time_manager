import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';

class EventScrollConfiguration<T extends Object?> extends ValueNotifier<bool> {
  bool _shouldScroll = false;
  TimeInterval? _event;
  Duration? _duration;
  Curve? _curve;

  Completer<void>? _completer;

  EventScrollConfiguration() : super(false);

  bool get shouldScroll => _shouldScroll;
  TimeInterval? get event => _event;
  Duration? get duration => _duration;
  Curve? get curve => _curve;

  // This function will be completed once [completeScroll] is called.
  Future<void> setScrollEvent({
    required TimeInterval event,
    required Duration? duration,
    required Curve? curve,
  }) {
    if (shouldScroll || _completer != null) return Future.value();

    _completer = Completer();

    _duration = duration;
    _curve = curve;
    _event = event;
    _shouldScroll = true;
    value = !value;

    return _completer!.future;
  }

  void resetScrollEvent() {
    _event = null;
    _shouldScroll = false;
    _duration = null;
    _curve = null;
  }

  void completeScroll() {
    _completer?.complete();
    _completer = null;
  }
}
