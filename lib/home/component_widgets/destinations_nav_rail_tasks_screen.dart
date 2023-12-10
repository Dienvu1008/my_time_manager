import 'package:flutter/material.dart';

final List<NavigationRailDestination> navRailTasksScreenDestinations =
    navBarTasksScreenDestinations
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

const List<NavigationDestination> navBarTasksScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.home_outlined),
    label: 'Overview',
    selectedIcon: Icon(Icons.home),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.timeline_outlined),
    label: 'Timeline',
    selectedIcon: Icon(Icons.timeline),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.table_chart_outlined),
    label: 'Timetable',
    selectedIcon: Icon(Icons.table_chart),
  ),
];
