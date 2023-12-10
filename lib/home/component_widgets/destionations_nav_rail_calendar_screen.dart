import 'package:flutter/material.dart';

final List<NavigationRailDestination> navRailCalendarScreenDestinations =
    navBarCalendarScreenDestinations
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

const List<NavigationDestination> navBarCalendarScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.calendar_view_day_outlined),
    label: 'Day',
    selectedIcon: Icon(Icons.calendar_view_day),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.calendar_view_week_outlined),
    label: 'Week',
    selectedIcon: Icon(Icons.calendar_view_week),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.calendar_view_month_outlined),
    label: 'Month',
    selectedIcon: Icon(Icons.calendar_view_month),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.calendar_month_outlined),
    label: 'Year',
    selectedIcon: Icon(Icons.calendar_month),
  )
];
