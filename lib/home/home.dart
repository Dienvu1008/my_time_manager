import 'dart:collection';

import 'package:calendar_widgets/src_table_calendar/customization/calendar_builders.dart';
import 'package:calendar_widgets/src_table_calendar/shared/utils.dart';
import 'package:calendar_widgets/src_table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/home/data_controller_provider.dart';
import 'package:my_time_manager/screen_calendar/view_daily.dart';
import 'package:my_time_manager/screen_calendar/view_monthly.dart';
import 'package:my_time_manager/screen_tasks/page_tasks_timeline_new.dart';
import 'package:my_time_manager/utils/widget_coming_soon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_localizations.dart';
import '../data/database/database_manager.dart';
import '../data/models/model_list.dart';
import '../data/models/model_time_interval.dart';
import '../screen_about_us/page_about_us.dart';
import '../screen_calendar/view_weekly.dart';
import '../screen_focus_timer/page_focus_timer.dart';
import '../screen_material_design/page_color_palettes.dart';
import '../screen_material_design/page_component.dart';
import '../screen_settings/page_settings_user_interface.dart';
import '../screen_tasks/page_tasks_overview.dart';
import '../screen_tasks/page_tasks_timeline.dart';
import '../utils/constants.dart';
import '../screen_material_design/page_elevation.dart';
import '../screen_material_design/page_typography.dart';
import '../utils/utils.dart';
import 'component_widgets/actions_expanded_trailing.dart';
import 'component_widgets/app_drawer.dart';
import 'component_widgets/app_navigation_bars.dart';
import 'component_widgets/appbar.dart';
import 'component_widgets/button_brightness.dart';
import 'component_widgets/button_color_image.dart';
import 'component_widgets/button_color_seed.dart';
import 'component_widgets/button_language.dart';
import 'component_widgets/button_material3.dart';
import 'component_widgets/destinations_about_us_screen.dart';
import 'component_widgets/destinations_focus_timer_screen.dart';
import 'component_widgets/destinations_material_design_screen.dart';
import 'component_widgets/destinations_nav_rail_tasks_screen.dart';
import 'component_widgets/destinations_settings_screen.dart';
import 'component_widgets/destionations_nav_rail_calendar_screen.dart';
import 'component_widgets/transition_navigation.dart';
import 'component_widgets/transition_one_two.dart';
import 'data_controller.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.isProVersion,
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
    required this.launchCount,
    required this.useBottomBar,
    required this.handleUsingBottomBarChange,
  });

  final bool isProVersion;
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
  final int launchCount;

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

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController controller;
  late final CurvedAnimation railAnimation;
  bool controllerInitialized = false;
  bool showMediumSizeLayout = false;
  bool showLargeSizeLayout = false;

  int _selectedDrawerItemIndex = ScreenSelected.tasksScreen.value;
  int _selectedNavBarItemIndex = 0;

  final DatabaseManager _databaseManager = DatabaseManager();
  late SharedPreferences _prefs;
  List<TaskList>? _taskLists;
  List<TimeInterval> _timeIntervals = [];

  // static final List<Widget> _calendarScreen = <Widget>[
  //   const TasksDayView(),
  //   const TasksWeekView(),
  //   const TasksMonthView(),
  //   const ComingSoonWidget(),
  // ];

  Widget createPageForCalendarScreen(PageOfCalendarScreenSelected screenSelected) {
    switch (screenSelected) {
      case PageOfCalendarScreenSelected.dayPage:
        return TasksDayView(
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
        );
      case PageOfCalendarScreenSelected.weekPage:
        return TasksWeekView(
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
        );

      case PageOfCalendarScreenSelected.monthPage:
        return TasksMonthView(
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
        );
      case PageOfCalendarScreenSelected.yearPage:
        return ComingSoonWidget();
    }
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedDrawerItemIndex = index;
      _selectedNavBarItemIndex = 0;
    });
    Navigator.pop(context);
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedNavBarItemIndex = index;
    });
  }

  @override
  initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(milliseconds: transitionLength.toInt() * 2),
      value: 0,
      vsync: this,
    );
    railAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0),
    );
    //_init();
    //_loadData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  //Monitor changes in screen width
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double width = MediaQuery.of(context).size.width;
    final AnimationStatus status = controller.status;
    if (width > mediumWidthBreakpoint) {
      if (width > largeWidthBreakpoint) {
        showMediumSizeLayout = false;
        showLargeSizeLayout = true;
      } else {
        showMediumSizeLayout = true;
        showLargeSizeLayout = false;
      }
      if (status != AnimationStatus.forward &&
          status != AnimationStatus.completed) {
        controller.forward();
      }
    } else {
      showMediumSizeLayout = false;
      showLargeSizeLayout = false;
      if (status != AnimationStatus.reverse &&
          status != AnimationStatus.dismissed) {
        controller.reverse();
      }
    }
    if (!controllerInitialized) {
      controllerInitialized = true;
      controller.value = width > mediumWidthBreakpoint ? 1 : 0;
    }
  }

  Widget createPageForMaterialDesignScreen(
      PageOfMaterialDesignScreenSelected screenSelected,
      bool showNavBarExample) {
    switch (screenSelected) {
      case PageOfMaterialDesignScreenSelected.component:
        return Expanded(
          child: OneTwoTransition(
            animation: railAnimation,
            one: FirstComponentList(
                showNavBottomBar: showNavBarExample,
                scaffoldKey: scaffoldKey,
                showSecondList: showMediumSizeLayout || showLargeSizeLayout),
            two: SecondComponentList(
              scaffoldKey: scaffoldKey,
            ),
          ),
        );
      case PageOfMaterialDesignScreenSelected.color:
        return const ColorPalettesPage();
      case PageOfMaterialDesignScreenSelected.typography:
        return const TypographyPage();
      case PageOfMaterialDesignScreenSelected.elevation:
        return const ElevationPage();
    }
  }

  Widget createPageForTasksScreen(PageOfTasksScreenSelected screenSelected) {
    switch (screenSelected) {
      case PageOfTasksScreenSelected.tasksOverviewPage:
        return TasksOverviewPage(
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
          isProVersion: widget.isProVersion,
        );
      case PageOfTasksScreenSelected.tasksTimelinePage:
        return FutureBuilder(
          future: _databaseManager.timeIntervals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              List<TimeInterval> timeIntervals = snapshot.data ?? [];
              return TableComplexExample(
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
                showBrightnessButtonInAppBar:
                    widget.showBrightnessButtonInAppBar,
                showColorImageButtonInAppBar:
                    widget.showColorImageButtonInAppBar,
                showColorSeedButtonInAppBar: widget.showColorSeedButtonInAppBar,
                showLanguagesButtonInAppBar: widget.showLanguagesButtonInAppBar,
                showMaterialDesignButtonInAppBar:
                    widget.showMaterialDesignButtonInAppBar,
                timeIntervals: timeIntervals,
              );
            }
          },
        );

      case PageOfTasksScreenSelected.tasksTimetablePage:
        return TasksWeekView(
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
        );
    }
  }

  // Widget createPageForCalendarScreen() {
  //   return _calendarScreen.elementAt(_selectedNavBarItemIndex);
  // }

  Widget createPageForSettingsScreen(
    PageOfSettingsScreen screenSelected,
  ) {
    switch (screenSelected) {
      case PageOfSettingsScreen.page_ui:
        return SettingsPage(
          colorSelected: widget.colorSelected,
          colorSelectionMethod: widget.colorSelectionMethod,
          handleBrightnessChange: widget.handleBrightnessChange,
          handleColorSelect: widget.handleColorSelect,
          handleDisplayBrightnessButtonInAppBarChange:
              widget.handleDisplayBrightnessButtonInAppBarChange,
          handleDisplayColorImageButtonInAppBarChange:
              widget.handleDisplayColorImageButtonInAppBarChange,
          handleDisplayColorSeedButtonInAppBarChange:
              widget.handleDisplayColorSeedButtonInAppBarChange,
          handleDisplayLanguagesButtonInAppBarChange:
              widget.handleDisplayLanguagesButtonInAppBarChange,
          handleDisplayMaterialDesignButtonInAppBarChange:
              widget.handleDisplayMaterialDesignButtonInAppBarChange,
          handleImageSelect: widget.handleImageSelect,
          handleLanguageSelect: widget.handleLanguageSelect,
          handleMaterialVersionChange: widget.handleMaterialVersionChange,
          imageSelected: widget.imageSelected,
          languageSelected: widget.languageSelected,
          launchCount: widget.launchCount,
          showBrightnessButtonInAppBar: widget.showBrightnessButtonInAppBar,
          showColorImageButtonInAppBar: widget.showColorImageButtonInAppBar,
          showColorSeedButtonInAppBar: widget.showColorSeedButtonInAppBar,
          showLanguagesButtonInAppBar: widget.showLanguagesButtonInAppBar,
          showMaterialDesignButtonInAppBar:
              widget.showMaterialDesignButtonInAppBar,
          useLightMode: widget.useLightMode,
          useMaterial3: widget.useMaterial3,
        );
      case PageOfSettingsScreen.page_account:
        return ComingSoonWidget();
      case PageOfSettingsScreen.page_data_and_sync:
        return ComingSoonWidget();
    }
  }

  Widget getContentPage() {
    if (_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value) {
      return createPageForTasksScreen(
          PageOfTasksScreenSelected.values[_selectedNavBarItemIndex]);
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.settingsScreen.value) {
      return createPageForSettingsScreen(
        PageOfSettingsScreen.values[_selectedNavBarItemIndex],
      );
    } else if (_selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value) {
      return AboutUsPage(
        isProVersion: widget.isProVersion,
      );
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.calendarScreen.value) {
      return createPageForCalendarScreen(PageOfCalendarScreenSelected.values[_selectedNavBarItemIndex]);
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.focusTimerScreen.value) {
      return const TimerPage();
    } else {
      return createPageForMaterialDesignScreen(
        PageOfMaterialDesignScreenSelected.values[_selectedNavBarItemIndex],
        controller.value == 1,
      );
    }
  }

  List<NavigationRailDestination> getDestinations() {
    if (_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value) {
      return navRailTasksScreenDestinations;
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.settingsScreen.value) {
      return navRailSettingsScreenDestinations;
    } else if (_selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value) {
      return navRailAboutUsScreenDestinations;
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.calendarScreen.value) {
      return navRailCalendarScreenDestinations;
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.focusTimerScreen.value) {
      return navRailFocusTimerScreenDestinations;
    } else {
      return navRailMaterialDesignScreenDestinations;
    }
  }

  Widget _trailingActions() => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: BrightnessButton(
              handleBrightnessChange: widget.handleBrightnessChange,
              showTooltipBelow: false,
            ),
          ),
          Flexible(
            child: Material3Button(
              handleMaterialVersionChange: widget.handleMaterialVersionChange,
              showTooltipBelow: false,
            ),
          ),
          Flexible(
            child: ColorSeedButton(
              handleColorSelect: widget.handleColorSelect,
              colorSelected: widget.colorSelected,
              colorSelectionMethod: widget.colorSelectionMethod,
            ),
          ),
          Flexible(
            child: ColorImageButton(
              handleImageSelect: widget.handleImageSelect,
              imageSelected: widget.imageSelected,
              colorSelectionMethod: widget.colorSelectionMethod,
            ),
          ),
          Flexible(
            child: LanguageButton(
              handleLanguageSelect: widget.handleLanguageSelect,
              languageSelected: widget.languageSelected,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return NavigationTransition(
          scaffoldKey: scaffoldKey,
          animationController: controller,
          railAnimation: railAnimation,
          appBar: _selectedDrawerItemIndex != ScreenSelected.tasksScreen.value //&& _selectedDrawerItemIndex != ScreenSelected.calendarScreen.value
              ? CustomAppBar(
                  selectedDrawerItemIndex: _selectedDrawerItemIndex,
                  selectedNavBarItemIndex: _selectedNavBarItemIndex,
                  showMediumSizeLayout: showMediumSizeLayout,
                  showLargeSizeLayout: showLargeSizeLayout,
                  useLightMode: widget.useLightMode,
                  handleBrightnessChange: widget.handleBrightnessChange,
                  useMaterial3: widget.useMaterial3,
                  handleMaterialVersionChange:
                      widget.handleMaterialVersionChange,
                  handleImageSelect: widget.handleImageSelect,
                  handleColorSelect: widget.handleColorSelect,
                  colorSelectionMethod: widget.colorSelectionMethod,
                  imageSelected: widget.imageSelected,
                  colorSelected: widget.colorSelected,
                  handleLanguageSelect: widget.handleLanguageSelect,
                  languageSelected: widget.languageSelected,
                  showBrightnessButtonInAppBar:
                      widget.showBrightnessButtonInAppBar,
                  showMaterialDesignButtonInAppBar:
                      widget.showMaterialDesignButtonInAppBar,
                  showColorSeedButtonInAppBar:
                      widget.showColorSeedButtonInAppBar,
                  showColorImageButtonInAppBar:
                      widget.showColorImageButtonInAppBar,
                  showLanguagesButtonInAppBar:
                      widget.showLanguagesButtonInAppBar,
                  handleDisplayBrightnessButtonInAppBarChange:
                      widget.handleDisplayBrightnessButtonInAppBarChange,
                  handleDisplayMaterialDesignButtonInAppBarChange:
                      widget.handleDisplayMaterialDesignButtonInAppBarChange,
                  handleDisplayColorSeedButtonInAppBarChange:
                      widget.handleDisplayColorSeedButtonInAppBarChange,
                  handleDisplayColorImageButtonInAppBarChange:
                      widget.handleDisplayColorImageButtonInAppBarChange,
                  handleDisplayLanguagesButtonInAppBarChange:
                      widget.handleDisplayLanguagesButtonInAppBarChange,
                  useBottomBar: widget.useBottomBar,
                  handleUsingBottomBarChange: widget.handleUsingBottomBarChange,
                )
              : null,
          drawer: MyAppDrawer(_selectedDrawerItemIndex, _onDrawerItemTapped,
              localizations, widget.isProVersion),
          body: getContentPage(),
          navigationRail: NavigationRail(
            extended: showLargeSizeLayout,
            destinations: getDestinations(),
            selectedIndex: _selectedNavBarItemIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavBarItemIndex = index;
                _onNavBarItemTapped(_selectedNavBarItemIndex);
              });
            },
            trailing: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: showLargeSizeLayout
                    ? ExpandedTrailingActions(
                        useLightMode: widget.useLightMode,
                        handleBrightnessChange: widget.handleBrightnessChange,
                        useMaterial3: widget.useMaterial3,
                        handleMaterialVersionChange:
                            widget.handleMaterialVersionChange,
                        handleImageSelect: widget.handleImageSelect,
                        handleColorSelect: widget.handleColorSelect,
                        colorSelectionMethod: widget.colorSelectionMethod,
                        imageSelected: widget.imageSelected,
                        colorSelected: widget.colorSelected,
                        handleLanguageSelect: widget.handleLanguageSelect,
                        languageSelected: widget.languageSelected,
                      )
                    : _trailingActions(),
              ),
            ),
          ),
          navigationBar: Visibility(
            //bottom navigation bar sẽ không hiện ở màn hình about us
            visible: widget.useBottomBar &&
                _selectedDrawerItemIndex != ScreenSelected.aboutUsScreen.value,
            child: AppNavigationBars(
              onSelectItem: (index) {
                setState(() {
                  _selectedNavBarItemIndex = index;
                  _onNavBarItemTapped(_selectedNavBarItemIndex);
                });
              },
              selectedDrawerItemIndex: _selectedDrawerItemIndex,
              selectedNavBarItemIndex: _selectedNavBarItemIndex,
            ),
          ),
        );
      },
    );
  }
}
