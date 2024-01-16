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

const List<NavigationDestination> navBarSettingsScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.design_services_outlined),
    label: 'UI',
    selectedIcon: Icon(Icons.design_services),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.account_circle_outlined),
    label: 'Account',
    selectedIcon: Icon(Icons.account_circle),
  ),
    NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.cloud_sync_outlined),
    label: 'Data & Sync',
    selectedIcon: Icon(Icons.cloud_sync),
  ),
];
