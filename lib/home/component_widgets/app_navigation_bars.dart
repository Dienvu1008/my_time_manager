import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/home/component_widgets/destinations_focus_timer_screen.dart';
import 'package:my_time_manager/utils/constants.dart';

import 'destinations_material_design_screen.dart';
import 'destinations_settings_screen.dart';
import 'destinations_nav_rail_tasks_screen.dart';
import 'destinations_about_us_screen.dart';
import 'destinations_trash_screen.dart';
import 'destionations_nav_rail_calendar_screen.dart';

class AppNavigationBars extends StatefulWidget {
  const AppNavigationBars({
    super.key,
    this.onSelectItem,
    required this.selectedNavBarItemIndex,
    required this.selectedDrawerItemIndex,
  });

  final void Function(int)? onSelectItem;
  final int selectedNavBarItemIndex;
  final int selectedDrawerItemIndex;

  @override
  State<AppNavigationBars> createState() => _AppNavigationBarsState();
}

class _AppNavigationBarsState extends State<AppNavigationBars> {
  late int selectedNavBarItemIndex;
  late int selectedDrawerItemIndex;

  /// Chọn danh sách destination theo màn hình đang chọn (dùng enum value thay
  /// vì index mảng trực tiếp, để an toàn khi value không liên tục — ví dụ
  /// trashScreen có value 9).
  List<NavigationDestination> _destinationsFor(int drawerItemIndex) {
    if (drawerItemIndex == ScreenSelected.tasksScreen.value) {
      return navBarTasksScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.settingsScreen.value) {
      return navBarSettingsScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.aboutUsScreen.value) {
      return navBarAboutUsScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.materialDesignScreen.value) {
      return navBarMaterialDesignScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.calendarScreen.value) {
      return navBarCalendarScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.focusTimerScreen.value) {
      return navBarFocusTimerScreenDestinations;
    } else if (drawerItemIndex == ScreenSelected.trashScreen.value) {
      return navBarTrashScreenDestinations;
    }
    // Fallback an toàn cho các màn hình chưa có destination riêng.
    return navBarTasksScreenDestinations;
  }

  @override
  void initState() {
    super.initState();
    selectedNavBarItemIndex = widget.selectedNavBarItemIndex;
    selectedDrawerItemIndex = widget.selectedDrawerItemIndex;
  }

  @override
  void didUpdateWidget(covariant AppNavigationBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedNavBarItemIndex != oldWidget.selectedNavBarItemIndex) {
      selectedNavBarItemIndex = widget.selectedNavBarItemIndex;
    }
    if (widget.selectedDrawerItemIndex != oldWidget.selectedDrawerItemIndex) {
      selectedDrawerItemIndex = widget.selectedDrawerItemIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chế độ trong suốt: nền trong hoàn toàn, không đổ bóng, không phủ màu
    // surfaceTint (nếu không NavigationBar vẫn tự vẽ một lớp nền mờ).
    final transparent =
        context.select((AppBloc b) => b.state.transparentBottomBar);

    // App NavigationBar should get first focus.
    Widget navigationBar = Focus(
      autofocus: true,
      child: NavigationBar(
        // Trong suốt -> transparent + không tint/bóng. Ngược lại -> null để
        // dùng nền mặc định (đặc) của Material.
        backgroundColor: transparent ? Colors.transparent : null,
        elevation: transparent ? 0 : null,
        surfaceTintColor: transparent ? Colors.transparent : null,
        shadowColor: transparent ? Colors.transparent : null,
        selectedIndex: selectedNavBarItemIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedNavBarItemIndex = index;
          });
          widget.onSelectItem!(index);
        },
        destinations: _destinationsFor(selectedDrawerItemIndex),
      ),
    );
    return navigationBar;
  }
}
