import 'dart:async';
import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/data/models/model_calendar_event.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/calendar_zoom_wrapper.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';
import 'package:my_time_manager/screen_calendar/week_view.dart';
import '../data/device_calendar/device_calendar_service.dart';
import '../screen_tasks/component_widgets/page_add_edit_calendar_event.dart';
import '../screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import '../utils/constants.dart';
import 'page_edit_device_event.dart';

class TasksWeekView extends StatefulWidget {
  //final GlobalKey<WeekViewState>? state;
  //final double? width;
  final Function handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function(int) handleColorSelect;
  final bool useBottomBar;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  final bool showBrightnessButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;

  /// Gọi khi người dùng nhấn vào SỐ NGÀY ở header cột -> nhảy sang day view của
  /// ngày đó.
  final void Function(DateTime date)? onJumpToDay;

  const TasksWeekView({
    Key? key,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleUsingBottomBarChange,
    required this.handleColorSelect,
    required this.useBottomBar,
    required this.colorSelected,
    required this.colorSelectionMethod,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.handleLanguageSelect,
    required this.languageSelected,
    required this.showBrightnessButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    this.onJumpToDay,
    //this.state
  }) : super(key: key);

  @override
  _TasksWeekViewState createState() => _TasksWeekViewState();
}

class _TasksWeekViewState extends State<TasksWeekView> {
  // Controller tạo MỘT LẦN (không tạo trong build) để tránh vòng lặp rebuild
  // vô hạn gây đơ khi chuyển tuần.
  final TimeIntervalController _controller = TimeIntervalController();
  // Chỉ dựng view sau khi nạp xong dữ liệu vào controller (đảm bảo hiển thị).
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await enrichTimeIntervals(_controller);
    } catch (e) {
      debugPrint('TasksWeekView._init lỗi: $e');
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    final width = MediaQuery.of(context).size.width;
    final showZoomButtons =
        context.select((AppBloc b) => b.state.showCalendarZoomButtons);

    return CalendarControllerProvider(
      controller: _controller,
      child: Expanded(
        child: CalendarZoomWrapper(
          showButtons: showZoomButtons,
          builder: (context, zoom, availableHeight) => WeekViewWidget(
            onEmptySlotTap: _openCreateTimeInterval,
            onDeviceEventTap: _openEditDeviceEvent,
            onCalendarEventTap: _openEditCalendarEvent,
            onJumpToDay: widget.onJumpToDay,
            handleBrightnessChange: widget.handleBrightnessChange,
            handleMaterialVersionChange: widget.handleMaterialVersionChange,
            handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
            useBottomBar: widget.useBottomBar,
            handleColorSelect: widget.handleColorSelect,
            colorSelected: widget.colorSelected,
            colorSelectionMethod: widget.colorSelectionMethod,
            handleImageSelect: widget.handleImageSelect,
            imageSelected: widget.imageSelected,
            handleLanguageSelect: widget.handleLanguageSelect,
            languageSelected: widget.languageSelected,
            showBrightnessButtonInAppBar: widget.showBrightnessButtonInAppBar,
            showColorImageButtonInAppBar: widget.showColorImageButtonInAppBar,
            showColorSeedButtonInAppBar: widget.showColorSeedButtonInAppBar,
            showLanguagesButtonInAppBar: widget.showLanguagesButtonInAppBar,
            showMaterialDesignButtonInAppBar:
                widget.showMaterialDesignButtonInAppBar,
            //key: widget.state,
            width: width,
            // zoom = 1.0 -> 24 giờ vừa khít chiều cao khả dụng (mức nhỏ nhất).
            heightPerMinute: _fitHeightPerMinute(availableHeight) * zoom,
          ),
        ),
      ),
    );
  }

  /// Chiều cao mỗi phút để 24 giờ vừa khít [availableHeight].
  double _fitHeightPerMinute(double availableHeight) {
    const totalMinutes = 24 * 60;
    final usable = (availableHeight - 24).clamp(60.0, double.infinity);
    final value = usable / totalMinutes;
    return value <= 0 ? 0.1 : value;
  }

  /// Nhấn ô trống -> chọn task (giống focus timer) rồi tạo interval mới với
  /// ngày/giờ điền sẵn. Sau khi đóng, nạp lại lịch.
  Future<void> _openCreateTimeInterval(DateTime start) {
    return openCreateOnEmptySlot(
      context: context,
      controller: _controller,
      start: start,
    );
  }

  /// Nhấn vào event lịch thiết bị -> mở trang xem/sửa; nếu có thay đổi thì nạp
  /// lại lịch.
  Future<void> _openEditDeviceEvent(DeviceEvent event) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditDeviceEventPage(existing: event),
      ),
    );
    if (changed == true && mounted) {
      await reloadTimeIntervals(_controller);
    }
  }

  /// Nhấn vào sự kiện lịch của app -> mở trang xem/sửa/xóa; nếu có thay đổi thì
  /// nạp lại lịch. Trang trả về một CalendarEvent (khác null) khi lưu hoặc xóa.
  Future<void> _openEditCalendarEvent(CalendarEvent event) async {
    final target = await resolveMasterCalendarEvent(context, event);
    if (!mounted) return;
    final result = await Navigator.of(context).push<CalendarEvent>(
      MaterialPageRoute(
        builder: (_) => AddOrEditCalendarEventPage(event: target),
      ),
    );
    if (result != null && mounted) {
      await reloadTimeIntervals(_controller);
    }
  }
}

class WeekViewWidget extends StatelessWidget {
  final GlobalKey<WeekViewState>? state;
  final double? width;

  final Function handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function(int) handleColorSelect;
  final bool useBottomBar;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  final bool showBrightnessButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;

  /// Chiều cao mỗi phút — điều khiển mức zoom dọc của week view.
  final double heightPerMinute;

  /// Gọi khi người dùng nhấn vào ô giờ TRỐNG (tham số là mốc bắt đầu ô đó).
  final void Function(DateTime)? onEmptySlotTap;

  /// Gọi khi nhấn vào event lịch thiết bị (để xem/sửa).
  final void Function(DeviceEvent)? onDeviceEventTap;

  /// Gọi khi nhấn vào một sự kiện lịch của app (để xem/sửa/xóa).
  final void Function(CalendarEvent)? onCalendarEventTap;

  /// Gọi khi nhấn số ngày ở header cột -> nhảy sang day view của ngày đó.
  final void Function(DateTime date)? onJumpToDay;

  const WeekViewWidget({super.key, this.state, this.width,
    this.heightPerMinute = 1,
    this.onEmptySlotTap,
    this.onJumpToDay,
    this.onDeviceEventTap,
    this.onCalendarEventTap,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleUsingBottomBarChange,
    required this.handleColorSelect,
    required this.useBottomBar,
    required this.colorSelected,
    required this.colorSelectionMethod,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.handleLanguageSelect,
    required this.languageSelected,
    required this.showBrightnessButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
  });

  @override
  Widget build(BuildContext context) {
    return WeekViewNew(
      key: state,
      handleBrightnessChange: handleBrightnessChange,
      handleMaterialVersionChange: handleMaterialVersionChange,
      handleUsingBottomBarChange: handleUsingBottomBarChange,
      useBottomBar: useBottomBar,
      handleColorSelect: handleColorSelect,
      colorSelected: colorSelected,
      colorSelectionMethod: colorSelectionMethod,
      handleImageSelect: handleImageSelect,
      imageSelected: imageSelected,
      handleLanguageSelect: handleLanguageSelect,
      languageSelected: languageSelected,
      showBrightnessButtonInAppBar:
      showBrightnessButtonInAppBar,
      showColorImageButtonInAppBar:
      showColorImageButtonInAppBar,
      showColorSeedButtonInAppBar: showColorSeedButtonInAppBar,
      showLanguagesButtonInAppBar: showLanguagesButtonInAppBar,
      showMaterialDesignButtonInAppBar:
      showMaterialDesignButtonInAppBar,
      heightPerMinute: heightPerMinute,
      //width: width,
      onDayHeaderTap: onJumpToDay,
      onTimeIntervalTileTap: (events, date) async {
        final payload = events.first.event;
        if (payload is DeviceEvent) {
          onDeviceEventTap?.call(payload);
        } else if (payload is CalendarEvent) {
          onCalendarEventTap?.call(payload);
        } else if (payload is TimeInterval) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOrEditTimeIntervalPage(
                timeInterval: payload,
              ),
              fullscreenDialog: false,
            ),
          );
        }
      },
      // Nhấn vào ô giờ trống -> mở giao diện tạo interval mới với giờ điền sẵn.
      onDateTap: onEmptySlotTap,
      leftSideHourIndicatorBuilder: _leftSideHourIndicatorBuilder,
    );
  }

  Widget _leftSideHourIndicatorBuilder(DateTime date) {
    final timeString = date.toString().substring(11, 16);
    //if (date.minute != 0) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            //"${date.hour}:${date.minute}",
            timeString,
            textAlign: TextAlign.right,
            style: TextStyle(
              //color: Colors.black.withAlpha(50),
              //fontStyle: FontStyle.italic,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
