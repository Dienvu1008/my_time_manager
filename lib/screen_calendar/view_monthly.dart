import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/calendar_zoom_wrapper.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';

import '../data/device_calendar/device_calendar_service.dart';
import '../screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import '../utils/constants.dart';
import 'month_view.dart';
import 'page_edit_device_event.dart';

class TasksMonthView extends StatefulWidget {
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

  const TasksMonthView({
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
  _TasksMonthViewState createState() => _TasksMonthViewState();
}

class _TasksMonthViewState extends State<TasksMonthView> {
  // Controller tạo MỘT LẦN (không tạo trong build) để tránh vòng lặp rebuild
  // vô hạn gây đơ khi chuyển tháng.
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
      debugPrint('TasksMonthView._init lỗi: $e');
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
          maxZoom: 2.5,
          builder: (context, zoom, availableHeight) => MonthViewWidget(
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
            // zoom = 1.0 -> 6 hàng vừa khít chiều cao khả dụng (mức nhỏ nhất).
            // Phóng to (zoom > 1) làm ô cao hơn -> aspect ratio nhỏ đi.
            cellAspectRatio: _fitCellAspectRatio(width, availableHeight) / zoom,
          ),
        ),
      ),
    );
  }

  /// Tỉ lệ khung ô để 6 hàng vừa khít [availableHeight] với bề rộng [width].
  double _fitCellAspectRatio(double width, double availableHeight) {
    final cellWidth = width / 7;
    final usable = (availableHeight - 24).clamp(60.0, double.infinity);
    final cellHeight = usable / 6;
    final ratio = cellWidth / cellHeight;
    return ratio <= 0 ? 0.55 : ratio;
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
}

class MonthViewWidget extends StatelessWidget {
  final GlobalKey<MonthViewState>? state;
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

  /// Tỉ lệ khung của ô ngày — điều khiển mức zoom của month view (nhỏ hơn = cao hơn).
  final double cellAspectRatio;

  /// Gọi khi nhấn vào event lịch thiết bị (để xem/sửa).
  final void Function(DeviceEvent)? onDeviceEventTap;

  const MonthViewWidget({
    super.key,
    this.state,
    this.width,
    this.cellAspectRatio = 0.55,
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
    return MonthViewNew(
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
      cellAspectRatio: cellAspectRatio,
      onEventTap: (event, date) async {
        final payload = event.event;
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
    );
  }
}
