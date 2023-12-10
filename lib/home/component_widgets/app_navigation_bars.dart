import 'package:flutter/material.dart';

import 'destinations_material_design_screen.dart';
import 'destinations_settings_screen.dart';
import 'destinations_nav_rail_tasks_screen.dart';
import 'destinations_about_us_screen.dart';
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

  List<List<NavigationDestination>> destinations = [
    navBarTasksScreenDestinations,
    navBarSettingsScreenDestinations,
    navBarAboutUsScreenDestinations,
    navBarMaterialDesignScreenDestinations,
    navBarCalendarScreenDestinations,
  ];

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
    // App NavigationBar should get first focus.
    Widget navigationBar = Focus(
      autofocus: true,
      child: NavigationBar(
        selectedIndex: selectedNavBarItemIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedNavBarItemIndex = index;
          });
          widget.onSelectItem!(index);
        },
        destinations: destinations[selectedDrawerItemIndex],
      ),
    );
    return navigationBar;
  }
}
