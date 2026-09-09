import 'dart:async';

import 'package:flutter/material.dart';

import '../calendar_time_interval_data.dart';

class TimeIntervalScrollConfiguration<T extends Object?> extends ValueNotifier<bool> {
  bool _shouldScroll = false;
  CalendarTimeIntervalData<T>? _timeInterval;
  Duration? _duration;
  Curve? _curve;

  Completer<void>? _completer;

  TimeIntervalScrollConfiguration() : super(false);

  bool get shouldScroll => _shouldScroll;

  CalendarTimeIntervalData<T>? get event => _timeInterval;

  Duration? get duration => _duration;

  Curve? get curve => _curve;

  // This function will be completed once [completeScroll] is called.
  Future<void> setScrollTimeInterval({
    required CalendarTimeIntervalData<T> timeInterval,
    required Duration? duration,
    required Curve? curve,
  }) {
    if (shouldScroll || _completer != null) return Future.value();

    _completer = Completer();

    _duration = duration;
    _curve = curve;
    _timeInterval = timeInterval;
    _shouldScroll = true;
    value = !value;

    return _completer!.future;
  }

  void resetScrollTimeInterval() {
    _timeInterval = null;
    _shouldScroll = false;
    _duration = null;
    _curve = null;
  }

  void completeScroll() {
    _completer?.complete();
    _completer = null;
  }
}
