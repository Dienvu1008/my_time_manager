import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/home/component_widgets/button_use_bottom_bar.dart';
import 'package:my_time_manager/screen_tasks/page_tasks_timeline.dart';
import '../../app/app_localizations.dart';
import '../../utils/constants.dart';
import 'button_brightness.dart';
import 'button_color_image.dart';
import 'button_color_seed.dart';
import 'button_language.dart';
import 'button_material3.dart';
import 'button_select_calendar_mode.dart';
import 'button_show_timeline_calendar.dart';

String getAppBarTitle(
    selectedDrawerItemIndex, selectedNavBarItemIndex, localizations) {
  if (selectedDrawerItemIndex == ScreenSelected.tasksScreen.value) {
    if (selectedNavBarItemIndex ==
        PageOfTasksScreenSelected.tasksOverviewPage.value) {
      return localizations!.overview;
    } else if (selectedNavBarItemIndex ==
        PageOfTasksScreenSelected.tasksTimelinePage.value) {
      return 'Timeline';
    } else if (selectedNavBarItemIndex ==
        PageOfTasksScreenSelected.tasksTimetablePage.value) {
      return 'Timetable';
    }
  } else if (selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value) {
    return localizations!.aboutUs;
  } else if (selectedDrawerItemIndex ==
      ScreenSelected.materialDesignScreen.value) {
    if (selectedNavBarItemIndex ==
        PageOfMaterialDesignScreenSelected.component.value) {
      return 'Components';
    } else if (selectedNavBarItemIndex ==
        PageOfMaterialDesignScreenSelected.color.value) {
      return 'Colors';
    } else if (selectedNavBarItemIndex ==
        PageOfMaterialDesignScreenSelected.typography.value) {
      return 'Typography';
    } else if (selectedNavBarItemIndex ==
        PageOfMaterialDesignScreenSelected.elevation.value) {
      return 'Elevation';
    }
  }
  if (selectedDrawerItemIndex == ScreenSelected.calendarScreen.value) {
    if (selectedNavBarItemIndex == PageOfCalendarScreenSelected.dayPage.value) {
      return 'Day';
    } else if (selectedNavBarItemIndex ==
        PageOfCalendarScreenSelected.weekPage.value) {
      return 'Week';
    } else if (selectedNavBarItemIndex ==
        PageOfCalendarScreenSelected.monthPage.value) {
      return 'Month';
    } else if (selectedNavBarItemIndex ==
        PageOfCalendarScreenSelected.yearPage.value) {
      return 'Year';
    }
  }
  if (selectedDrawerItemIndex == ScreenSelected.settingsScreen.value) {
    if (selectedNavBarItemIndex == PageOfSettingsScreen.page_ui.value) {
      return 'UI';
    } else if (selectedNavBarItemIndex ==
        PageOfSettingsScreen.page_account.value) {
      return 'Account';
    } else if (selectedNavBarItemIndex ==
        PageOfSettingsScreen.page_data_and_sync.value) {
      return 'Data & Sync';
    }
  }
  return '';
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  //final String title;
  final bool showMediumSizeLayout;
  final bool showLargeSizeLayout;
  final int selectedDrawerItemIndex;
  final int selectedNavBarItemIndex;
  final bool useLightMode;
  final bool useMaterial3;
  final bool useBottomBar;
  final bool showBrightnessButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage languageSelected;
  //final AppLocalizations localizations;

  final void Function(bool useLightMode) handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function() handleDisplayBrightnessButtonInAppBarChange;
  final void Function() handleDisplayMaterialDesignButtonInAppBarChange;
  final void Function() handleDisplayColorSeedButtonInAppBarChange;
  final void Function() handleDisplayColorImageButtonInAppBarChange;
  final void Function() handleDisplayLanguagesButtonInAppBarChange;
  final void Function(int value) handleColorSelect;
  final void Function(int value) handleImageSelect;
  final void Function(int value) handleLanguageSelect;

  // final void Function() onLeftArrowTap;
  // final void Function() onRightArrowTap;
  // final void Function() onTodayButtonTap;
  // final void Function() onClearButtonTap;
  // final void Function(String) onSelectionModeChanged;
  // final RangeSelectionMode rangeSelectionMode;
  // final bool showCalendar;
  // final bool clearButtonVisible;
  // final DateTime focusedDay;
  //
  // final void Function() handleCalendarVisibilityChange;

  CustomAppBar({
    required this.selectedDrawerItemIndex,
    required this.selectedNavBarItemIndex,
    required this.showMediumSizeLayout,
    required this.showLargeSizeLayout,
    required this.useLightMode,
    required this.useMaterial3,
    required this.showBrightnessButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.colorSelected,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleDisplayBrightnessButtonInAppBarChange,
    required this.handleDisplayMaterialDesignButtonInAppBarChange,
    required this.handleDisplayColorSeedButtonInAppBarChange,
    required this.handleDisplayColorImageButtonInAppBarChange,
    required this.handleDisplayLanguagesButtonInAppBarChange,
    required this.handleColorSelect,
    required this.handleImageSelect,
    required this.handleLanguageSelect,
    required this.colorSelectionMethod,
    required this.imageSelected,
    required this.languageSelected,
    // required this.onLeftArrowTap,
    // required this.onRightArrowTap,
    // required this.onTodayButtonTap,
    // required this.onClearButtonTap,
    // required this.onSelectionModeChanged,
    // required this.rangeSelectionMode,
    // required this.showCalendar,
    // required this.focusedDay,
    // required this.clearButtonVisible,
    // required this.handleCalendarVisibilityChange,
    required this.useBottomBar,
    required this.handleUsingBottomBarChange,

  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          // (widget.selectedDrawerItemIndex == ScreenSelected.tasksScreen.value &&
          //         widget.selectedNavBarItemIndex ==
          //             PageOfTasksScreenSelected.tasksTimelinePage.value)
          //     ? CalendarHeader(
          //         focusedDay: widget.focusedDay,
          //         onLeftArrowTap: widget.onLeftArrowTap,
          //         onRightArrowTap: widget.onRightArrowTap,
          //         onTodayButtonTap: widget.onTodayButtonTap,
          //         onClearButtonTap: widget.onClearButtonTap,
          //         clearButtonVisible: widget.clearButtonVisible,
          //         onSelectionModeChanged: widget.onSelectionModeChanged,
          //         rangeSelectionMode: widget.rangeSelectionMode,
          //         showCalendar: widget.showCalendar,
          //       )
          //     :
          Text(getAppBarTitle(
              widget.selectedDrawerItemIndex,
              widget.selectedNavBarItemIndex,
              AppLocalizations.of(context))),
      actions: !widget.showMediumSizeLayout && !widget.showLargeSizeLayout
          ? [
              // if (widget.showBrightnessButtonInAppBar)
              //   BrightnessButton(
              //     handleBrightnessChange: widget.handleBrightnessChange,
              //   ),
              // if (widget.showMaterialDesignButtonInAppBar)
              //   Material3Button(
              //     handleMaterialVersionChange:
              //         widget.handleMaterialVersionChange,
              //   ),
              // if (widget.showColorSeedButtonInAppBar)
              //   ColorSeedButton(
              //     handleColorSelect: widget.handleColorSelect,
              //     colorSelected: widget.colorSelected,
              //     colorSelectionMethod: widget.colorSelectionMethod,
              //   ),
              // if (widget.showColorImageButtonInAppBar)
              //   ColorImageButton(
              //     handleImageSelect: widget.handleImageSelect,
              //     imageSelected: widget.imageSelected,
              //     colorSelectionMethod: widget.colorSelectionMethod,
              //   ),
              // if (widget.showLanguagesButtonInAppBar)
              //   LanguageButton(
              //     handleLanguageSelect: widget.handleLanguageSelect,
              //     languageSelected: widget.languageSelected,
              //   ),
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert_outlined),
                  );
                },
                menuChildren: [
                  if (widget.showBrightnessButtonInAppBar)
                  BrightnessMenuItemButton(
                    handleBrightnessChange: widget.handleBrightnessChange,
                  ),
                  if (widget.showMaterialDesignButtonInAppBar)
                  Material3MenuItemButton(
                    handleMaterialVersionChange:
                        widget.handleMaterialVersionChange,
                  ),
                  UsingBottomBarMenuItemButton(
                      handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
                      useBottomBar: widget.useBottomBar),
                  if (widget.showColorSeedButtonInAppBar)
                  ColorSeedSubmenuButton(
                    handleColorSelect: widget.handleColorSelect,
                    colorSelected: widget.colorSelected,
                    colorSelectionMethod: widget.colorSelectionMethod,
                  ),
                  if (widget.showColorImageButtonInAppBar)
                  ColorImageSubmenuButton(
                    handleImageSelect: widget.handleImageSelect,
                    imageSelected: widget.imageSelected,
                    colorSelectionMethod: widget.colorSelectionMethod,
                  ),
                  if (widget.showLanguagesButtonInAppBar)
                  LanguageSubmenuButton(
                    handleLanguageSelect: widget.handleLanguageSelect,
                    languageSelected: widget.languageSelected,
                  ),
                ],
              ),
              //Container(),
            ]
          : [Container()],
    );
  }
}
