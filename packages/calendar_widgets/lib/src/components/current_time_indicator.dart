import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions.dart';
import '../modals.dart';
import '../painters.dart';

/// Widget to display tile line according to current time.
class CurrentTimeIndicator extends StatefulWidget {
  /// Width of indicator
  final double width;

  /// Height of total display area indicator will be displayed
  /// within this height.
  final double height;

  /// Width of time line use to calculate offset of indicator.
  final double leftSideHourIndicatorWidth;

  /// settings for time line. Defines color, extra offset,
  /// and height of indicator.
  final HourIndicatorSettings currentTimeIndicatorSettings;

  /// Defines height occupied by one minute.
  final double heightPerMinute;

  /// Widget to display tile line according to current time.
  const CurrentTimeIndicator(
      {Key? key,
        required this.width,
        required this.height,
        required this.leftSideHourIndicatorWidth,
        required this.currentTimeIndicatorSettings,
        required this.heightPerMinute})
      : super(key: key);

  @override
  _CurrentTimeIndicatorState createState() => _CurrentTimeIndicatorState();
}

class _CurrentTimeIndicatorState extends State<CurrentTimeIndicator> {
  late Timer _timer;
  late TimeOfDay _currentTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Creates an recursive call that runs every 1 seconds.
  /// This will rebuild TimeLineIndicator every second. This will allow us
  /// to indicate live time in Week and Day view.
  void _onTick(Timer? timer) {
    final time = TimeOfDay.now();
    if (time != _currentTime && mounted) {
      _currentTime = time;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: CurrentTimeIndicatorLinePainter(
        color: widget.currentTimeIndicatorSettings.color,
        height: widget.currentTimeIndicatorSettings.height,
        offset: Offset(
          widget.leftSideHourIndicatorWidth + widget.currentTimeIndicatorSettings.offset,
          _currentTime.getTotalMinutes * widget.heightPerMinute,
        ),
      ),
    );
  }
}
