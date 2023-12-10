import 'package:flutter/material.dart';

final List<NavigationRailDestination> navRailAboutUsScreenDestinations =
    navBarAboutUsScreenDestinations
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


//navBarAboutUsScreenDestinations tạo ra hai destinations giả để tránh lỗi 'destinations.length >= 2'
const List<NavigationDestination> navBarAboutUsScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(), //Icon(Icons.info_outlined),
    label: '', //'Info',
    selectedIcon: SizedBox.shrink(), //Icon(Icons.info),
  ),
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(), //Icon(Icons.info_outlined),
    label: '', //'Info',
    selectedIcon: SizedBox.shrink(), //Icon(Icons.info),
  ),
];
