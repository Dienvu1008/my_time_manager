import 'dart:async';

import 'package:flutter/material.dart';

import '../extensions.dart';
import '../modals.dart';
import '../painters.dart';

/// Widget to display tile line according to current time.
class WeekCurrentTimeIndicator extends StatefulWidget {
  /// Width of indicator
  final double indicatorWidth;

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

  /// Toạ độ x nơi cột NGÀY HIỆN TẠI bắt đầu. Nếu null, đường kẻ bắt đầu ngay
  /// sau timeline (hành vi cũ: kéo dài cả tuần).
  final double? dayStartOffset;

  /// Bề rộng của một cột ngày. Nếu cùng với [dayStartOffset] khác null thì
  /// đường kẻ chỉ nằm gọn trong cột ngày hiện tại.
  final double? dayWidth;

  /// Widget to display tile line according to current time.
  const WeekCurrentTimeIndicator(
      {Key? key,
        required this.indicatorWidth,
        required this.height,
        required this.leftSideHourIndicatorWidth,
        required this.currentTimeIndicatorSettings,
        required this.heightPerMinute,
        this.dayStartOffset,
        this.dayWidth})
      : super(key: key);

  @override
  _WeekCurrentTimeIndicatorState createState() => _WeekCurrentTimeIndicatorState();
}

class _WeekCurrentTimeIndicatorState extends State<WeekCurrentTimeIndicator> {
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
    // Toạ độ x bắt đầu: nếu biết cột ngày hiện tại thì bắt đầu ngay tại cột đó,
    // ngược lại bắt đầu sau timeline (hành vi cũ).
    final startDx = widget.dayStartOffset ??
        (widget.leftSideHourIndicatorWidth +
            widget.currentTimeIndicatorSettings.offset);
    // Toạ độ x kết thúc: nếu biết bề rộng cột ngày thì kết thúc ở cuối cột đó
    // (đường chỉ nằm trong đúng ngày hiện tại), ngược lại kẻ hết chiều rộng.
    final endDx = (widget.dayStartOffset != null && widget.dayWidth != null)
        ? widget.dayStartOffset! + widget.dayWidth!
        : null;

    return CustomPaint(
      size: Size(widget.indicatorWidth, widget.height),
      painter: CurrentTimeIndicatorLinePainter(
        color: widget.currentTimeIndicatorSettings.color,
        height: widget.currentTimeIndicatorSettings.height,
        offset: Offset(
          startDx,
          _currentTime.getTotalMinutes * widget.heightPerMinute,
        ),
        endDx: endDx,
      ),
    );
  }
}
