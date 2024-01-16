import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/complex_example.dart';
import 'package:my_time_manager/screen_calendar/view_daily.dart';
import 'package:my_time_manager/screen_calendar/view_monthly.dart';
import 'package:my_time_manager/utils/widget_coming_soon.dart';
import '../app/app_localizations.dart';
import '../screen_about_us/page_about_us.dart';
import '../screen_focus_timer/page_focus_timer.dart';
import '../screen_material_design/page_color_palettes.dart';
import '../screen_material_design/page_component.dart';
import '../screen_settings/page_settings_user_interface.dart';
import '../screen_tasks/page_tasks_overview.dart';
import '../screen_tasks/page_tasks_timetable.dart';
import '../utils/constants.dart';
import '../screen_material_design/page_elevation.dart';
import '../screen_material_design/page_typography.dart';
import 'component_widgets/actions_expanded_trailing.dart';
import 'component_widgets/app_drawer.dart';
import 'component_widgets/app_navigation_bars.dart';
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
  });

  final bool isProVersion;
  final bool useLightMode;
  final bool useMaterial3;
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

  static final List<Widget> _tasksScreen = <Widget>[
    BlocTasksOverviewPage(),
    //TasksTimelinePage(),
    TableComplexExample(),
    TasksTimetablePage(),
  ];

  static final List<Widget> _calendarScreen = <Widget>[
    TasksDayView(),
    TasksTimetablePage(),
    TasksMonthView(),
    ComingSoonWidget(),
  ];

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

  Widget createPageForTasksScreen() {
    return _tasksScreen.elementAt(_selectedNavBarItemIndex);
  }

  Widget createPageForCalendarScreen() {
    return _calendarScreen.elementAt(_selectedNavBarItemIndex);
  }

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
      return createPageForTasksScreen();
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
      return createPageForCalendarScreen();
    } else if (_selectedDrawerItemIndex ==
        ScreenSelected.focusTimerScreen.value) {
      return TimerPage();
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

  PreferredSizeWidget createAppBar(String title) {
    return AppBar(
      title: Text(title),
      actions: !showMediumSizeLayout && !showLargeSizeLayout
          ? [
              if (widget.showBrightnessButtonInAppBar)
                BrightnessButton(
                  handleBrightnessChange: widget.handleBrightnessChange,
                ),
              if (widget.showMaterialDesignButtonInAppBar)
                Material3Button(
                  handleMaterialVersionChange:
                      widget.handleMaterialVersionChange,
                ),
              if (widget.showColorSeedButtonInAppBar)
                ColorSeedButton(
                  handleColorSelect: widget.handleColorSelect,
                  colorSelected: widget.colorSelected,
                  colorSelectionMethod: widget.colorSelectionMethod,
                ),
              if (widget.showColorImageButtonInAppBar)
                ColorImageButton(
                  handleImageSelect: widget.handleImageSelect,
                  imageSelected: widget.imageSelected,
                  colorSelectionMethod: widget.colorSelectionMethod,
                ),
              if (widget.showLanguagesButtonInAppBar)
                LanguageButton(
                  handleLanguageSelect: widget.handleLanguageSelect,
                  languageSelected: widget.languageSelected,
                ),
              if (_selectedDrawerItemIndex ==
                      ScreenSelected.tasksScreen.value &&
                  _selectedNavBarItemIndex ==
                      PageOfTasksScreenSelected.tasksTimelinePage.value)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_outlined, size: 18.0),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      //value: showCalendar ? 'hide calendar' : 'show calendar',
                      child: Text('Hide Calendar'
                          // showCalendar
                          //     ? localizations!.hideCalendar
                          //     : localizations!.showCalendar,
                          ),
                    ),
                    PopupMenuItem<String>(
                      value: 'multi',
                      child: Text('Multi'
                          // localizations!.selectMultipleDays,
                          // style: TextStyle(
                          //   color: rangeSelectionMode ==
                          //           RangeSelectionMode.toggledOff
                          //       ? Colors.blue
                          //       : null,
                          // ),
                          ),
                    ),
                    PopupMenuItem<String>(
                      value: 'range',
                      child: Text('Range'
                          // localizations.selectDateRange,
                          // style: TextStyle(
                          //   color:
                          //       rangeSelectionMode == RangeSelectionMode.toggledOn
                          //           ? Colors.blue
                          //           : null,
                          // ),
                          ),
                    ),
                  ],
                  //onSelected: key.currentState!._onCalendarSelectionModeChanged(),
                ),
              Container(),
            ]
          : [Container()],
    );
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
            appBar: createAppBar(getAppBarTitle(_selectedDrawerItemIndex,
                _selectedNavBarItemIndex, localizations)),
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
              visible: _selectedDrawerItemIndex !=
                  ScreenSelected.aboutUsScreen.value,
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
            ));
      },
    );
  }
}

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
