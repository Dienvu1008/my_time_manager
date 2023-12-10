import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_calendar/complex_example.dart';
import 'package:my_time_manager/screen_calendar/view_daily.dart';
import 'package:my_time_manager/screen_calendar/view_monthly.dart';
import 'package:my_time_manager/utils/widget_coming_soon.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_localizations.dart';
import '../screen_about_us/page_about_us.dart';
import '../screen_material_design/page_color_palettes.dart';
import '../screen_material_design/page_component.dart';
import '../screen_settings/page_settings_user_interface.dart';
import '../screen_tasks/page_tasks_overview.dart';
import '../screen_tasks/page_tasks_timeline.dart';
import '../screen_tasks/page_tasks_timetable.dart';
import '../utils/constants.dart';
import '../screen_material_design/page_elevation.dart';
import '../screen_material_design/page_typography.dart';
import '../utils/utils.dart';
import 'package:table_calendar/table_calendar.dart';

import 'component_widgets/actions_expanded_trailing.dart';
import 'component_widgets/app_drawer.dart';
import 'component_widgets/app_navigation_bars.dart';
import 'component_widgets/button_brightness.dart';
import 'component_widgets/button_color_image.dart';
import 'component_widgets/button_color_seed.dart';
import 'component_widgets/button_language.dart';
import 'component_widgets/button_material3.dart';
import 'component_widgets/destinations_about_us_screen.dart';
import 'component_widgets/destinations_material_design_screen.dart';
import 'component_widgets/destinations_nav_rail_tasks_screen.dart';
import 'component_widgets/destinations_settings_screen.dart';
import 'component_widgets/destionations_nav_rail_calendar_screen.dart';
import 'component_widgets/transition_navigation.dart';
import 'component_widgets/transition_one_two.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
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
    switch (
        //_selectedNavBarItemIndex
        screenSelected) {
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

    // final Map<List<dynamic>, String> appBarTitles = {
    //   [
    //     ScreenSelected.tasksScreen.value,
    //     PageOfTasksScreenSelected.tasksOverviewPage.value
    //   ]: 'Overview',
    //   [
    //     ScreenSelected.tasksScreen.value,
    //     PageOfTasksScreenSelected.tasksTimelinePage.value
    //   ]: 'Timeline',
    //   [
    //     ScreenSelected.tasksScreen.value,
    //     PageOfTasksScreenSelected.tasksTimetablePage.value
    //   ]: 'Timetable',
    //   [ScreenSelected.settingsScreen.value, null]: localizations!.settings,
    //   [ScreenSelected.aboutUsScreen.value, null]: localizations.About,
    //   [
    //     ScreenSelected.materialDesignScreen.value,
    //     PageOfMaterialDesignScreenSelected.component.value
    //   ]: 'Components',
    //   [
    //     ScreenSelected.materialDesignScreen.value,
    //     PageOfMaterialDesignScreenSelected.color.value
    //   ]: 'Colors',
    //   [
    //     ScreenSelected.materialDesignScreen.value,
    //     PageOfMaterialDesignScreenSelected.typography.value
    //   ]: 'Typography',
    //   [
    //     ScreenSelected.materialDesignScreen.value,
    //     PageOfMaterialDesignScreenSelected.elevation.value
    //   ]: 'Elevation',
    //   [null, null]: '',
    // };

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return NavigationTransition(
            scaffoldKey: scaffoldKey,
            animationController: controller,
            railAnimation: railAnimation,
            appBar: createAppBar((_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value &&
                    _selectedNavBarItemIndex ==
                        PageOfTasksScreenSelected.tasksOverviewPage.value)
                ? localizations!.overview
                : (_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value &&
                        _selectedNavBarItemIndex ==
                            PageOfTasksScreenSelected.tasksTimelinePage.value)
                    ? 'Timeline'
                    : (_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value &&
                            _selectedNavBarItemIndex ==
                                PageOfTasksScreenSelected
                                    .tasksTimetablePage.value)
                        ? 'Timetable'
                        : (_selectedDrawerItemIndex ==
                                ScreenSelected.settingsScreen.value)
                            ? localizations!.settings
                            : (_selectedDrawerItemIndex ==
                                    ScreenSelected.aboutUsScreen.value)
                                ? localizations!.aboutUs
                                : (_selectedDrawerItemIndex ==
                                            ScreenSelected
                                                .materialDesignScreen.value &&
                                        _selectedNavBarItemIndex ==
                                            PageOfMaterialDesignScreenSelected
                                                .component.value)
                                    ? 'Components'
                                    : (_selectedDrawerItemIndex ==
                                                ScreenSelected
                                                    .materialDesignScreen
                                                    .value &&
                                            _selectedNavBarItemIndex ==
                                                PageOfMaterialDesignScreenSelected
                                                    .color.value)
                                        ? 'Colors'
                                        : (_selectedDrawerItemIndex ==
                                                    ScreenSelected
                                                        .materialDesignScreen
                                                        .value &&
                                                _selectedNavBarItemIndex ==
                                                    PageOfMaterialDesignScreenSelected
                                                        .typography.value)
                                            ? 'Typography'
                                            : ''),

            // appBar: createAppBar(appBarTitles[[
            //   _selectedDrawerItemIndex,
            //   _selectedNavBarItemIndex
            // ]]!),
            drawer: MyAppDrawer(_selectedDrawerItemIndex, _onDrawerItemTapped, localizations),
            body: _selectedDrawerItemIndex == ScreenSelected.tasksScreen.value
                ? createPageForTasksScreen() 
                : _selectedDrawerItemIndex == ScreenSelected.settingsScreen.value
                    ? SettingsPage(
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
                        handleDisplayMaterialDesignButtonInAppBarChange: widget
                            .handleDisplayMaterialDesignButtonInAppBarChange,
                        handleImageSelect: widget.handleImageSelect,
                        handleLanguageSelect: widget.handleLanguageSelect,
                        handleMaterialVersionChange:
                            widget.handleMaterialVersionChange,
                        imageSelected: widget.imageSelected,
                        languageSelected: widget.languageSelected,
                        launchCount: widget.launchCount,
                        showBrightnessButtonInAppBar:
                            widget.showBrightnessButtonInAppBar,
                        showColorImageButtonInAppBar:
                            widget.showColorImageButtonInAppBar,
                        showColorSeedButtonInAppBar:
                            widget.showColorSeedButtonInAppBar,
                        showLanguagesButtonInAppBar:
                            widget.showLanguagesButtonInAppBar,
                        showMaterialDesignButtonInAppBar:
                            widget.showMaterialDesignButtonInAppBar,
                        useLightMode: widget.useLightMode,
                        useMaterial3: widget.useMaterial3,
                      )
                    : _selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value
                        ? AboutUsPage()
                        : _selectedDrawerItemIndex == ScreenSelected.calendarScreen.value
                            ? createPageForCalendarScreen()
                            : createPageForMaterialDesignScreen(PageOfMaterialDesignScreenSelected.values[_selectedNavBarItemIndex], controller.value == 1),
            // : _selectedDrawerItemIndex == ScreenSelected.calendarScreen.value
            // ? DatePickerDialog()
            // :,
            navigationRail: NavigationRail(
              extended: showLargeSizeLayout,
              destinations:
                  _selectedDrawerItemIndex == ScreenSelected.tasksScreen.value
                      ? navRailTasksScreenDestinations
                      : _selectedDrawerItemIndex ==
                              ScreenSelected.settingsScreen.value
                          ? navRailSettingsScreenDestinations
                          : _selectedDrawerItemIndex ==
                                  ScreenSelected.aboutUsScreen.value
                              ? navRailAboutUsScreenDestinations
                              : _selectedDrawerItemIndex ==
                                      ScreenSelected.calendarScreen.value
                                  ? navRailCalendarScreenDestinations
                                  : navRailMaterialDesignScreenDestinations,
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
              //bottom navigation bar sẽ không hiện ở các màn hình settings và about us
              visible: _selectedDrawerItemIndex !=
                      ScreenSelected.settingsScreen.value &&
                  _selectedDrawerItemIndex !=
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