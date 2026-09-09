import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/calendar_zoom_wrapper.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';
import 'package:calendar_widgets/calendar_widgets.dart';
import '../data/device_calendar/device_calendar_service.dart';
import '../screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import '../utils/constants.dart';
import 'day_view.dart';
import 'page_edit_device_event.dart';

class TasksDayView extends StatefulWidget {
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



  const TasksDayView({
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

    //this.state
  }) : super(key: key);

  @override
  _TasksDayViewState createState() => _TasksDayViewState();
}

class _TasksDayViewState extends State<TasksDayView> {
  final DatabaseManager _databaseManager = DatabaseManager();

  // QUAN TRỌNG: controller được tạo MỘT LẦN và giữ ở đây, KHÔNG tạo trong build.
  // Trước đây build() tạo controller mới mỗi lần -> DayView thấy controller đổi
  // identity ở didUpdateWidget -> re-listen/setState -> InheritedWidget đổi ->
  // rebuild -> tạo controller mới -> vòng lặp vô hạn -> đơ khi chuyển ngày.
  final TimeIntervalController _controller = TimeIntervalController();
  // Chỉ dựng view lịch SAU KHI đã nạp dữ liệu vào controller, để đảm bảo các
  // time interval hiển thị (view đọc event từ controller khi được tạo).
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await enrichTimeIntervals(_databaseManager, _controller);
    } catch (e) {
      debugPrint('TasksDayView._init lỗi: $e');
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
    // Đọc cài đặt hiện nút zoom từ AppBloc.
    final showZoomButtons =
        context.select((AppBloc b) => b.state.showCalendarZoomButtons);

    return CalendarControllerProvider(
      controller: _controller,
      child: Expanded(
        child: CalendarZoomWrapper(
          showButtons: showZoomButtons,
          builder: (context, zoom, availableHeight) => DayViewWidget(
            onEmptySlotTap: _openCreateTimeInterval,
            onDeviceEventTap: _openEditDeviceEvent,
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
            // zoom = 1.0 -> toàn bộ 24 giờ vừa khít chiều cao khả dụng (mức
            // nhỏ nhất). Phóng to sẽ nhân lên. Trừ một khoảng nhỏ cho phần
            // header/khoảng đệm để tránh tràn ở mức nhỏ nhất.
            heightPerMinute: _fitHeightPerMinute(availableHeight) * zoom,
          ),
        ),
      ),
    );
  }

  /// Chiều cao mỗi phút để 24 giờ vừa khít [availableHeight].
  double _fitHeightPerMinute(double availableHeight) {
    const totalMinutes = 24 * 60;
    // Trừ ~24px cho khoảng đệm/đường kẻ để không tràn ở mức fit.
    final usable = (availableHeight - 24).clamp(60.0, double.infinity);
    final value = usable / totalMinutes;
    // Đảm bảo > 0 (yêu cầu của DayView).
    return value <= 0 ? 0.1 : value;
  }

  /// Nhấn ô trống -> chọn task (giống focus timer) rồi tạo interval mới với
  /// ngày/giờ điền sẵn. Sau khi đóng, nạp lại lịch.
  Future<void> _openCreateTimeInterval(DateTime start) {
    return openCreateOnEmptySlot(
      context: context,
      databaseManager: _databaseManager,
      controller: _controller,
      start: start,
    );
  }

  /// Nhấn vào event lịch thiết bị -> mở trang xem/sửa; nếu có thay đổi thì nạp
  /// lại lịch để cập nhật.
  Future<void> _openEditDeviceEvent(DeviceEvent event) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditDeviceEventPage(existing: event),
      ),
    );
    if (changed == true && mounted) {
      await reloadTimeIntervals(_databaseManager, _controller);
    }
  }
}

class DayViewWidget extends StatelessWidget {
  final DatabaseManager _databaseManager = DatabaseManager();
  final GlobalKey<DayViewState>? state;
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

  /// Chiều cao mỗi phút — điều khiển mức zoom dọc của day view.
  final double heightPerMinute;

  /// Gọi khi người dùng nhấn vào một ô giờ TRỐNG. Tham số là mốc bắt đầu của
  /// ô đã nhấn (đủ cả ngày và giờ). Dùng để mở giao diện tạo interval mới.
  final void Function(DateTime)? onEmptySlotTap;

  /// Gọi khi người dùng nhấn vào một event của lịch thiết bị (để xem/sửa).
  final void Function(DeviceEvent)? onDeviceEventTap;

  DayViewWidget({
    super.key,
    this.state,
    this.width,
    this.heightPerMinute = 3,
    this.onEmptySlotTap,
    this.onDeviceEventTap,
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
    return DayViewNew(
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
      key: state,
      width: width,
      startDuration: Duration(hours: 8),
      showHalfHours: true,
      heightPerMinute: heightPerMinute,
      leftSideHourIndicatorBuilder: _leftSideHourIndicatorBuilder,
      hourIndicatorSettings: HourIndicatorSettings(
        color: Theme.of(context).dividerColor,
      ),
      onEventTap: (events, date) async {
        final payload = events.first.event;
        if (payload is DeviceEvent) {
          onDeviceEventTap?.call(payload);
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
      // halfHourIndicatorSettings: HourIndicatorSettings(
      //   color: Theme.of(context).dividerColor,
      //   lineStyle: LineStyle.dashed,
      // ),

    );
  }

  Widget _dayTitleBuilder(DateTime date){
    return AppBar(
        title: DayPageHeader(date: date)
    );
  }

  Widget _leftSideHourIndicatorBuilder(DateTime date) {
    //if (date.minute != 0) {
    final timeString = date.toString().substring(11, 16);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            timeString,
            //"${date.hour}:${date.minute}",
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

  //   final hour = ((date.hour - 1) % 12) + 1;
  //   return Stack(
  //     clipBehavior: Clip.none,
  //     children: [
  //       Positioned.fill(
  //         top: -8,
  //         right: 8,
  //         child: Text(
  //           "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}",
  //           textAlign: TextAlign.right,
  //           style: TextStyle(
  //             color: Colors.black.withAlpha(50),
  //             fontStyle: FontStyle.italic,
  //             fontSize: 8,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
