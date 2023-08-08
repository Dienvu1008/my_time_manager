import 'package:flutter/material.dart';
import '../app/app_localizations.dart';
import '../screen_about_us/about_us_page.dart';
import '../screen_material_design/color_palettes_page.dart';
import '../screen_material_design/component_page.dart';
import '../screen_settings/settings_page.dart';
import '../screen_tasks/tasks_overview_page.dart';
import '../screen_tasks/tasks_timeline_page.dart';
import '../screen_tasks/tasks_timetable_page.dart';
import '../utils/constants.dart';
import '../screen_material_design/elevation_page.dart';
import '../screen_material_design/typography_page.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.useLightMode,
    required this.useMaterial3,
    required this.colorSelected,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleColorSelect,
    required this.handleImageSelect,
    required this.handleLanguageSelect,
    required this.colorSelectionMethod,
    required this.imageSelected,
    required this.languageSelected,
  });

  final bool useLightMode;
  final bool useMaterial3;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage languageSelected;

  final void Function(bool useLightMode) handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
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
    TasksOverviewPage(),
    TasksTimelinePage(),
    TasksTimetablePage(),
  ];

  static final List<Widget> _materialDesignScreen = <Widget>[
    ColorPalettesPage(),
    TypographyPage(),
    ElevationPage()
  ];

  // late final List<Widget> _screens = <Widget>[
  //   createPageForTasksScreen(),
  //   SettingsPage(),
  //   AboutUsPage(),
  //   createPageForMaterialDesignScreen(
  //     screenSelected,
  //     showNavBarExample)];

  //       static PageOfMaterialDesignScreenSelected get screenSelected => null;

  //         static bool get showNavBarExample => null;

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

  PreferredSizeWidget createAppBar(String title) {
    return AppBar(
      title: Text(title),
      actions: !showMediumSizeLayout && !showLargeSizeLayout
          ? [
              _BrightnessButton(
                handleBrightnessChange: widget.handleBrightnessChange,
              ),
              _Material3Button(
                handleMaterialVersionChange: widget.handleMaterialVersionChange,
              ),
              _ColorSeedButton(
                handleColorSelect: widget.handleColorSelect,
                colorSelected: widget.colorSelected,
                colorSelectionMethod: widget.colorSelectionMethod,
              ),
              _ColorImageButton(
                handleImageSelect: widget.handleImageSelect,
                imageSelected: widget.imageSelected,
                colorSelectionMethod: widget.colorSelectionMethod,
              ),
              _LanguageButton(
                handleLanguageSelect: widget.handleLanguageSelect,
                languageSelected: widget.languageSelected,
              ),
            ]
          : [Container()],
    );
  }

  Widget _trailingActions() => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: _BrightnessButton(
              handleBrightnessChange: widget.handleBrightnessChange,
              showTooltipBelow: false,
            ),
          ),
          Flexible(
            child: _Material3Button(
              handleMaterialVersionChange: widget.handleMaterialVersionChange,
              showTooltipBelow: false,
            ),
          ),
          Flexible(
            child: _ColorSeedButton(
              handleColorSelect: widget.handleColorSelect,
              colorSelected: widget.colorSelected,
              colorSelectionMethod: widget.colorSelectionMethod,
            ),
          ),
          Flexible(
            child: _ColorImageButton(
              handleImageSelect: widget.handleImageSelect,
              imageSelected: widget.imageSelected,
              colorSelectionMethod: widget.colorSelectionMethod,
            ),
          ),
          Flexible(
            child: _LanguageButton(
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
            appBar: createAppBar((_selectedDrawerItemIndex == ScreenSelected.tasksScreen.value &&
                    _selectedNavBarItemIndex ==
                        PageOfTasksScreenSelected.tasksOverviewPage.value)
                ? 'Overview' //localizations!.tasks
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
                                ? localizations!.about
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
                                            : 'Elevation'),
            drawer: Drawer(
              //backgroundColor: Theme.of(context).colorScheme.background,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                    ),
                    child: Text('My Time Manager'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.checklist_outlined),
                    title: Text(localizations!.tasks),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.tasksScreen.value,
                    onTap: () =>
                        _onDrawerItemTapped(ScreenSelected.tasksScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.design_services_outlined),
                    title: const Text('Material Design'),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.materialDesignScreen.value,
                    onTap: () => _onDrawerItemTapped(
                        ScreenSelected.materialDesignScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(localizations!.settings),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.settingsScreen.value,
                    onTap: () => _onDrawerItemTapped(
                        ScreenSelected.settingsScreen.value),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outlined),
                    title: Text(localizations.about),
                    selected: _selectedDrawerItemIndex ==
                        ScreenSelected.aboutUsScreen.value,
                    onTap: () =>
                        _onDrawerItemTapped(ScreenSelected.aboutUsScreen.value),
                  ),
                ],
              ),
            ),
            body: _selectedDrawerItemIndex == ScreenSelected.tasksScreen.value
                ? createPageForTasksScreen() //_homePages.elementAt(_selectedNavBarItemIndex)
                : _selectedDrawerItemIndex == ScreenSelected.settingsScreen.value
                    ? const SettingsPage()
                    : _selectedDrawerItemIndex == ScreenSelected.aboutUsScreen.value
                        ? AboutUsPage()
                        : createPageForMaterialDesignScreen(PageOfMaterialDesignScreenSelected.values[_selectedNavBarItemIndex], controller.value == 1),
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
                      ? _ExpandedTrailingActions(
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
                selectedNavBarItemIndex: _selectedNavBarItemIndex,
                selectedDrawerItemIndex: _selectedDrawerItemIndex,
              ),
            ));
      },
    );
  }
}

class _BrightnessButton extends StatelessWidget {
  const _BrightnessButton({
    required this.handleBrightnessChange,
    this.showTooltipBelow = true,
  });

  final Function handleBrightnessChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final isBright = Theme.of(context).brightness == Brightness.light;
    return Tooltip(
      preferBelow: showTooltipBelow,
      message: 'Toggle brightness',
      child: IconButton(
        icon: isBright
            ? const Icon(Icons.dark_mode_outlined)
            : const Icon(Icons.light_mode_outlined),
        onPressed: () => handleBrightnessChange(!isBright),
      ),
    );
  }
}

class _Material3Button extends StatelessWidget {
  const _Material3Button({
    required this.handleMaterialVersionChange,
    this.showTooltipBelow = true,
  });

  final void Function() handleMaterialVersionChange;
  //final void Function() handleMaterialVersionChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final useMaterial3 = Theme.of(context).useMaterial3;
    return Tooltip(
      preferBelow: showTooltipBelow,
      message: 'Switch to Material ${useMaterial3 ? 2 : 3}',
      child: IconButton(
        icon: useMaterial3
            ? const Icon(Icons.filter_2)
            : const Icon(Icons.filter_3),
        onPressed: handleMaterialVersionChange,
      ),
    );
  }
}

class _ColorSeedButton extends StatelessWidget {
  const _ColorSeedButton({
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleColorSelect;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.palette_outlined,
        //color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Select a seed color',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(ColorSeed.values.length, (index) {
          ColorSeed currentColor = ColorSeed.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentColor != colorSelected ||
                colorSelectionMethod != ColorSelectionMethod.colorSeed,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    currentColor == colorSelected &&
                            colorSelectionMethod != ColorSelectionMethod.image
                        ? Icons.color_lens
                        : Icons.color_lens_outlined,
                    color: currentColor.color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(currentColor.label),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleColorSelect,
    );
  }
}

class _ColorImageButton extends StatelessWidget {
  const _ColorImageButton({
    required this.handleImageSelect,
    required this.imageSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.image_outlined,
        //color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Select a color extraction image',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(ColorImageProvider.values.length, (index) {
          ColorImageProvider currentImageProvider =
              ColorImageProvider.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentImageProvider != imageSelected ||
                colorSelectionMethod != ColorSelectionMethod.image,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 48),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image(
                          image: NetworkImage(
                              ColorImageProvider.values[index].url),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(currentImageProvider.label),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleImageSelect,
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton(
      {required this.handleLanguageSelect, required this.languageSelected});

  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopupMenuButton(
      icon: Icon(
        Icons.language_outlined,
        //color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Select a language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) {
        return List.generate(AppLanguage.values.length, (index) {
          AppLanguage currentLanguage = AppLanguage.values[index];

          return PopupMenuItem(
            value: index,
            enabled: currentLanguage != languageSelected,
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 48),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Text(currentLanguage.short_language),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child:
                      Text(localizations!.translate(currentLanguage.language)),
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleLanguageSelect,
    );
  }
}

class _ExpandedTrailingActions extends StatelessWidget {
  const _ExpandedTrailingActions({
    required this.useLightMode,
    required this.handleBrightnessChange,
    required this.useMaterial3,
    required this.handleMaterialVersionChange,
    required this.handleColorSelect,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.colorSelected,
    required this.colorSelectionMethod,
  });

  final void Function(bool) handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function(int) handleImageSelect;
  final void Function(int) handleColorSelect;

  final bool useLightMode;
  final bool useMaterial3;

  final ColorImageProvider imageSelected;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final trailingActionsBody = Container(
      constraints: const BoxConstraints.tightFor(width: 250),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Brightness'),
              Expanded(child: Container()),
              Switch(
                  value: useLightMode,
                  onChanged: (value) {
                    handleBrightnessChange(value);
                  })
            ],
          ),
          Row(
            children: [
              useMaterial3
                  ? const Text('Material 3')
                  : const Text('Material 2'),
              Expanded(child: Container()),
              Switch(
                  value: useMaterial3,
                  onChanged: (_) {
                    handleMaterialVersionChange();
                  })
            ],
          ),
          const Divider(),
          _ExpandedColorSeedAction(
            handleColorSelect: handleColorSelect,
            colorSelected: colorSelected,
            colorSelectionMethod: colorSelectionMethod,
          ),
          const Divider(),
          _ExpandedImageColorAction(
            handleImageSelect: handleImageSelect,
            imageSelected: imageSelected,
            colorSelectionMethod: colorSelectionMethod,
          ),
        ],
      ),
    );
    return screenHeight > 740
        ? trailingActionsBody
        : SingleChildScrollView(child: trailingActionsBody);
  }
}

class _ExpandedColorSeedAction extends StatelessWidget {
  const _ExpandedColorSeedAction({
    required this.handleColorSelect,
    required this.colorSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleColorSelect;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200.0),
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(
          ColorSeed.values.length,
          (i) => IconButton(
            icon: const Icon(Icons.radio_button_unchecked),
            color: ColorSeed.values[i].color,
            isSelected: colorSelected.color == ColorSeed.values[i].color &&
                colorSelectionMethod == ColorSelectionMethod.colorSeed,
            selectedIcon: const Icon(Icons.circle),
            onPressed: () {
              handleColorSelect(i);
            },
          ),
        ),
      ),
    );
  }
}

class _ExpandedImageColorAction extends StatelessWidget {
  const _ExpandedImageColorAction({
    required this.handleImageSelect,
    required this.imageSelected,
    required this.colorSelectionMethod,
  });

  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(
            ColorImageProvider.values.length,
            (i) => InkWell(
              borderRadius: BorderRadius.circular(4.0),
              onTap: () => handleImageSelect(i),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  borderRadius: BorderRadius.circular(4.0),
                  elevation: imageSelected == ColorImageProvider.values[i] &&
                          colorSelectionMethod == ColorSelectionMethod.image
                      ? 3
                      : 0,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image(
                        image: NetworkImage(ColorImageProvider.values[i].url),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationTransition extends StatefulWidget {
  const NavigationTransition(
      {super.key,
      required this.scaffoldKey,
      required this.animationController,
      required this.railAnimation,
      required this.navigationRail,
      this.navigationBar,
      required this.drawer,
      required this.appBar,
      required this.body});

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController animationController;
  final CurvedAnimation railAnimation;
  final Widget navigationRail;
  final Widget? navigationBar;
  final Widget drawer;
  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  State<NavigationTransition> createState() => _NavigationTransitionState();
}

class _NavigationTransitionState extends State<NavigationTransition> {
  late final AnimationController controller;
  late final CurvedAnimation railAnimation;
  late final ReverseAnimation barAnimation;
  bool controllerInitialized = false;
  bool showDivider = false;

  @override
  void initState() {
    super.initState();

    controller = widget.animationController;
    railAnimation = widget.railAnimation;

    barAnimation = ReverseAnimation(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: widget.scaffoldKey,
      appBar: widget.appBar,
      body: Row(
        children: <Widget>[
          RailTransition(
            animation: railAnimation,
            backgroundColor: colorScheme.surface,
            child: widget.navigationRail,
          ),
          widget.body,
        ],
      ),
      bottomNavigationBar: BarTransition(
        animation: barAnimation,
        backgroundColor: colorScheme.surface,
        child: widget.navigationBar,
      ),
      drawer: Drawer(
        //animation: railAnimation,
        backgroundColor: colorScheme.surface,
        child: widget.drawer,
      ),
      endDrawer: const NavigationDrawerSection(),
    );
  }
}

class AppNavigationBars extends StatefulWidget {
  const AppNavigationBars({
    super.key,
    this.onSelectItem,
    required this.selectedNavBarItemIndex,
    required this.selectedDrawerItemIndex,
  });

  final void Function(int)? onSelectItem;
  final int selectedNavBarItemIndex;
  final int selectedDrawerItemIndex;

  @override
  State<AppNavigationBars> createState() => _AppNavigationBarsState();
}

class _AppNavigationBarsState extends State<AppNavigationBars> {
  late int selectedNavBarItemIndex;
  late int selectedDrawerItemIndex;

  List<List<NavigationDestination>> destinations = [
    navBarTasksScreenDestinations,
    navBarSettingsScreenDestinations,
    navBarAboutUsScreenDestinations,
    navBarMaterialDesignScreenDestinations,
  ];

  @override
  void initState() {
    super.initState();
    selectedNavBarItemIndex = widget.selectedNavBarItemIndex;
    selectedDrawerItemIndex = widget.selectedDrawerItemIndex;
  }

  @override
  void didUpdateWidget(covariant AppNavigationBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedNavBarItemIndex != oldWidget.selectedNavBarItemIndex) {
      selectedNavBarItemIndex = widget.selectedNavBarItemIndex;
    }
    if (widget.selectedDrawerItemIndex != oldWidget.selectedDrawerItemIndex) {
      selectedDrawerItemIndex = widget.selectedDrawerItemIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    // App NavigationBar should get first focus.
    Widget navigationBar = Focus(
      autofocus: true,
      child: NavigationBar(
        selectedIndex: selectedNavBarItemIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedNavBarItemIndex = index;
          });
          widget.onSelectItem!(index);
        },
        destinations: destinations[selectedDrawerItemIndex],
      ),
    );
    return navigationBar;
  }
}

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

final List<NavigationRailDestination> navRailMaterialDesignScreenDestinations =
    navBarMaterialDesignScreenDestinations
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

const List<NavigationDestination> navBarSettingsScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.settings_outlined),
    label: 'Settings',
    selectedIcon: Icon(Icons.settings),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.settings_outlined),
    label: 'Settings',
    selectedIcon: Icon(Icons.settings),
  ),
];

const List<NavigationDestination> navBarAboutUsScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.info_outlined),
    label: 'Info',
    selectedIcon: Icon(Icons.info),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.info_outlined),
    label: 'Info',
    selectedIcon: Icon(Icons.info),
  ),
];

const List<NavigationDestination> navBarMaterialDesignScreenDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.widgets_outlined),
    label: 'Components',
    selectedIcon: Icon(Icons.widgets),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.format_paint_outlined),
    label: 'Color',
    selectedIcon: Icon(Icons.format_paint),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.text_snippet_outlined),
    label: 'Typography',
    selectedIcon: Icon(Icons.text_snippet),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.invert_colors_on_outlined),
    label: 'Elevation',
    selectedIcon: Icon(Icons.opacity),
  )
];

class SizeAnimation extends CurvedAnimation {
  SizeAnimation(Animation<double> parent)
      : super(
          parent: parent,
          curve: const Interval(
            0.2,
            0.8,
            curve: Curves.easeInOutCubicEmphasized,
          ),
          reverseCurve: Interval(
            0,
            0.2,
            curve: Curves.easeInOutCubicEmphasized.flipped,
          ),
        );
}

class OffsetAnimation extends CurvedAnimation {
  OffsetAnimation(Animation<double> parent)
      : super(
          parent: parent,
          curve: const Interval(
            0.4,
            1.0,
            curve: Curves.easeInOutCubicEmphasized,
          ),
          reverseCurve: Interval(
            0,
            0.2,
            curve: Curves.easeInOutCubicEmphasized.flipped,
          ),
        );
}

class RailTransition extends StatefulWidget {
  const RailTransition(
      {super.key,
      required this.animation,
      required this.backgroundColor,
      required this.child});

  final Animation<double> animation;
  final Widget child;
  final Color backgroundColor;

  @override
  State<RailTransition> createState() => _RailTransition();
}

class _RailTransition extends State<RailTransition> {
  late Animation<Offset> offsetAnimation;
  late Animation<double> widthAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The animations are only rebuilt by this method when the text
    // direction changes because this widget only depends on Directionality.
    final bool ltr = Directionality.of(context) == TextDirection.ltr;

    widthAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(SizeAnimation(widget.animation));

    offsetAnimation = Tween<Offset>(
      begin: ltr ? const Offset(-1, 0) : const Offset(1, 0),
      end: Offset.zero,
    ).animate(OffsetAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Align(
          alignment: Alignment.topLeft,
          widthFactor: widthAnimation.value,
          child: FractionalTranslation(
            translation: offsetAnimation.value,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class BarTransition extends StatefulWidget {
  const BarTransition(
      {super.key,
      required this.animation,
      required this.backgroundColor,
      this.child});

  final Animation<double> animation;
  final Color backgroundColor;
  final Widget? child;

  @override
  State<BarTransition> createState() => _BarTransition();
}

class _BarTransition extends State<BarTransition> {
  late final Animation<Offset> offsetAnimation;
  late final Animation<double> heightAnimation;

  @override
  void initState() {
    super.initState();

    offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(OffsetAnimation(widget.animation));

    heightAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(SizeAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Align(
          alignment: Alignment.topLeft,
          heightFactor: heightAnimation.value,
          child: FractionalTranslation(
            translation: offsetAnimation.value,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class OneTwoTransition extends StatefulWidget {
  const OneTwoTransition({
    super.key,
    required this.animation,
    required this.one,
    required this.two,
  });

  final Animation<double> animation;
  final Widget one;
  final Widget two;

  @override
  State<OneTwoTransition> createState() => _OneTwoTransitionState();
}

class _OneTwoTransitionState extends State<OneTwoTransition> {
  late final Animation<Offset> offsetAnimation;
  late final Animation<double> widthAnimation;

  @override
  void initState() {
    super.initState();

    offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(OffsetAnimation(widget.animation));

    widthAnimation = Tween<double>(
      begin: 0,
      end: mediumWidthBreakpoint,
    ).animate(SizeAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          flex: mediumWidthBreakpoint.toInt(),
          child: widget.one,
        ),
        if (widthAnimation.value.toInt() > 0) ...[
          Flexible(
            flex: widthAnimation.value.toInt(),
            child: FractionalTranslation(
              translation: offsetAnimation.value,
              child: widget.two,
            ),
          )
        ],
      ],
    );
  }
}