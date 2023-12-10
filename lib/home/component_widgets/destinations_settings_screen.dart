import 'package:flutter/material.dart';

final List<NavigationRailDestination> navRailSettingsScreenDestinations =
    navBarSettingsScreenDestinations
        .map(
          (destination) => NavigationRailDestination(
            icon: Tooltip(
              message: destination.label,
              child: destination.icon,
            ),
            selectedIcon: Tooltip(
              message: destination.label,
              child: destination.selectedIcon,
            ),
            label: Text(destination.label),
          ),
        )
        .toList();

//navBarSettingsScreenDestinations tạo ra hai destinations giả để tránh lỗi 'destinations.length >= 2'
const List<NavigationDestination> navBarSettingsScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(), //Icon(Icons.settings_outlined),
    label: '', //'Settings',
    selectedIcon: SizedBox.shrink(), //Icon(Icons.settings),
  ),
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(), //Icon(Icons.settings_outlined),
    label: '', //'Settings',
    selectedIcon: SizedBox.shrink(), //Icon(Icons.settings),
  ),
];
