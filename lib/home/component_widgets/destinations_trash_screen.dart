import 'package:flutter/material.dart';

/// Destinations cho màn hình Thùng rác. Thùng rác là màn đơn (không có sub-page),
/// nên ta dùng 2 destination "rỗng" để thỏa ràng buộc NavigationRail cần tối
/// thiểu 2 mục — giống cách làm ở màn hình Focus Timer.
final List<NavigationRailDestination> navRailTrashScreenDestinations =
    navBarTrashScreenDestinations
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

const List<NavigationDestination> navBarTrashScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(),
    label: '',
    selectedIcon: SizedBox.shrink(),
  ),
  NavigationDestination(
    tooltip: '',
    icon: SizedBox.shrink(),
    label: '',
    selectedIcon: SizedBox.shrink(),
  ),
];
