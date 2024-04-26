import 'dart:io';

import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../home/component_widgets/button_brightness.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';
import '../home/component_widgets/button_material3.dart';
import '../home/component_widgets/button_use_bottom_bar.dart';
import '../utils/constants.dart';
import '../utils/utils.dart';

/// [Widget] to display week view.
class WeekViewNew<T extends Object?> extends StatefulWidget {

  final Function handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleUsingBottomBarChange;
  final void Function(int) handleColorSelect;
  final bool useBottomBar;
  final ColorSeed colorSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final void Function(int) handleImageSelect;
  final ColorImageProvider imageSelected;
  final void Function(int) handleLanguageSelect;
  final AppLanguage languageSelected;

  final bool showBrightnessButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;

  /// Builder to build tile for events.
  final TimeIntervalTileBuilder<T>? timeIntervalTileBuilder;

  /// Builder for timeline.
  final DateWidgetBuilder? leftSideHourIndicatorBuilder;

  /// Header builder for week page header.
  final WeekPageHeaderBuilder? weekPageHeaderBuilder;

  /// Builds custom PressDetector widget
  ///
  /// If null, internal PressDetector will be used to handle onDateLongPress()
  ///
  final DetectorBuilder? weekDetectorBuilder;

  /// This function will generate dateString int the calendar header.
  /// Useful for I18n
  final DateTimeStringProvider? headerStringBuilder;

  /// This function will generate the TimeString in the timeline.
  /// Useful for I18n
  final DateTimeStringProvider? displayTimeStringOfLeftSideHourIndicatorBuilder;

  /// This function will generate WeekDayString in the weekday.
  /// Useful for I18n
  final String Function(int)? weekDayStringBuilder;

  /// This function will generate WeekDayDateString in the weekday.
  /// Useful for I18n
  final String Function(int)? weekDayDateStringBuilder;

  /// Arrange events.
  final TimeIntervalArranger<T>? timeIntervalArranger;

  /// Called whenever user changes week.
  final CalendarPageChangeCallBack? onPageChange;

  /// Minimum day to display in week view.
  ///
  /// In calendar first date of the week that contains this data will be
  /// minimum date.
  ///
  /// ex, If minDay is 16th March, 2022 then week containing this date will have
  /// dates from 14th to 20th (Monday to Sunday). adn 14th date will
  /// be the actual minimum date.
  final DateTime? minDay;

  /// Maximum day to display in week view.
  ///
  /// In calendar last date of the week that contains this data will be
  /// maximum date.
  ///
  /// ex, If maxDay is 16th March, 2022 then week containing this date will have
  /// dates from 14th to 20th (Monday to Sunday). adn 20th date will
  /// be the actual maximum date.
  final DateTime? maxDay;

  /// Initial week to display in week view.
  final DateTime? initialDay;

  /// Settings for hour indicator settings.
  final HourIndicatorSettings? hourIndicatorSettings;

  /// A funtion that returns a [CustomPainter].
  ///
  /// Use this if you want to paint custom hour lines.
  final CustomHourLinePainter? hourLinePainter;

  /// Settings for half hour indicator settings.
  final HourIndicatorSettings? halfHourIndicatorSettings;

  /// Settings for quarter hour indicator settings.
  final HourIndicatorSettings? quarterHourIndicatorSettings;

  /// Settings for live time indicator settings.
  final HourIndicatorSettings? currentTimeIndicatorSettings;

  /// duration for page transition while changing the week.
  final Duration pageTransitionDuration;

  /// Transition curve for transition.
  final Curve pageTransitionCurve;

  /// Controller for Week view thia will refresh view when user adds or removes
  /// event from controller.
  final TimeIntervalController<T>? controller;

  /// Defines height occupied by one minute of time span. This parameter will
  /// be used to calculate total height of Week view.
  final double heightPerMinute;

  /// Width of time line.
  final double? leftSideHourIndicatorWidth;

  /// Flag to show live time indicator in all day or only [initialDay]
  final bool showLiveTimeLineInAllDays;

  /// Offset of time line
  final double leftSideHourIndicatorOffset;

  /// Width of week view. If null provided device width will be considered.
  final double? width;

  /// If true this will display vertical lines between each day.
  final bool showVerticalLines;

  /// Height of week day title,
  final double weekTitleHeight;

  /// Builder to build week day.
  final DateWidgetBuilder? weekDayBuilder;

  /// Builder to build week number.
  final WeekNumberBuilder? weekNumberBuilder;

  /// Background color of week view page.
  //final Color backgroundColor;

  /// Scroll offset of week view page.
  final double scrollOffset;

  /// Called when user taps on event tile.
  final CellTapCallback<T>? onTimeIntervalTileTap;

  /// Show weekends or not
  ///
  /// Default value is true.
  ///
  /// If it is false week view will remove weekends from week
  /// even if weekends are added in [weekDays].
  ///
  /// ex, if [showWeekends] is false and [weekDays] are monday, tuesday,
  /// saturday and sunday, only monday and tuesday will be visible in week view.
  final bool showWeekends;

  /// Defines which days should be displayed in one week.
  ///
  /// By default all the days will be visible.
  /// Sequence will be monday to sunday.
  ///
  /// Duplicate values will be removed from list.
  ///
  /// ex, if there are two mondays in list it will display only one.
  final List<WeekDays> weekDays;

  /// This method will be called when user long press on calendar.
  final DatePressCallback? onDateLongPress;

  /// Called when user taps on day view page.
  ///
  /// This callback will have a date parameter which
  /// will provide the time span on which user has tapped.
  ///
  /// Ex, User Taps on Date page with date 11/01/2022 and time span is 1PM to 2PM.
  /// then DateTime object will be  DateTime(2022,01,11,1,0)
  final DateTapCallback? onDateTap;

  /// Defines the day from which the week starts.
  ///
  /// Default value is [WeekDays.monday].
  final WeekDays startDay;

  /// Defines size of the slots that provides long press callback on area
  /// where events are not there.
  final MinuteSlotSize minuteSlotSize;

  /// Style for WeekView header.
  final HeaderStyle headerStyle;

  /// Option for SafeArea.
  final SafeAreaOption safeAreaOption;

  /// Display full day event builder.
  final FullDayTimeIntervalBuilder<T>? fullDayTimeIntervalBuilder;

  ///Show half hour indicator
  final bool showHalfHours;

  ///Show quarter hour indicator
  final bool showQuarterHours;

  ///Emulates offset of vertical line from hour line starts.
  final double emulateVerticalOffsetBy;

  /// Callback for the Header title
  final HeaderTitleCallback? onHeaderTitleTap;

  /// If true this will show week day at bottom position.
  final bool showWeekDayAtBottom;

  /// Main widget for week view.
  const WeekViewNew({
    Key? key,
    this.controller,
    this.timeIntervalTileBuilder,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.ease,
    this.heightPerMinute = 1,
    this.leftSideHourIndicatorOffset = 0,
    this.showLiveTimeLineInAllDays = false,
    this.showVerticalLines = true,
    this.width,
    this.minDay,
    this.maxDay,
    this.initialDay,
    this.hourIndicatorSettings,
    this.hourLinePainter,
    this.halfHourIndicatorSettings,
    this.quarterHourIndicatorSettings,
    this.leftSideHourIndicatorBuilder,
    this.leftSideHourIndicatorWidth,
    this.currentTimeIndicatorSettings,
    this.onPageChange,
    this.weekPageHeaderBuilder,
    this.timeIntervalArranger,
    this.weekTitleHeight = 50,
    this.weekDayBuilder,
    this.weekNumberBuilder,
    this.scrollOffset = 0.0,
    this.onTimeIntervalTileTap,
    this.onDateLongPress,
    this.onDateTap,
    this.weekDays = WeekDays.values,
    this.showWeekends = true,
    this.startDay = WeekDays.monday,
    this.minuteSlotSize = MinuteSlotSize.minutes60,
    this.weekDetectorBuilder,
    this.headerStringBuilder,
    this.displayTimeStringOfLeftSideHourIndicatorBuilder,
    this.weekDayStringBuilder,
    this.weekDayDateStringBuilder,
    this.headerStyle = const HeaderStyle(),
    this.safeAreaOption = const SafeAreaOption(),
    this.fullDayTimeIntervalBuilder,
    this.onHeaderTitleTap,
    this.showHalfHours = false,
    this.showQuarterHours = false,
    this.emulateVerticalOffsetBy = 0,
    this.showWeekDayAtBottom = false,

    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleUsingBottomBarChange,
    required this.handleColorSelect,
    required this.useBottomBar,
    required this.colorSelected,
    required this.colorSelectionMethod,
    required this.handleImageSelect,
    required this.imageSelected,
    required this.handleLanguageSelect,
    required this.languageSelected,
    required this.showBrightnessButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
  })  : assert(!(onHeaderTitleTap != null && weekPageHeaderBuilder != null),
  "can't use [onHeaderTitleTap] & [weekPageHeaderBuilder] simultaneously"),
        assert((leftSideHourIndicatorOffset) >= 0,
        "timeLineOffset must be greater than or equal to 0"),
        assert(width == null || width > 0,
        "Calendar width must be greater than 0."),
        assert(leftSideHourIndicatorWidth == null || leftSideHourIndicatorWidth > 0,
        "Time line width must be greater than 0."),
        assert(
        heightPerMinute > 0, "Height per minute must be greater than 0."),
        assert(
        weekDetectorBuilder == null || onDateLongPress == null,
        """If you use [weekPressDetectorBuilder] 
          do not provide [onDateLongPress]""",
        ),
        super(key: key);

  @override
  WeekViewNewState<T> createState() => WeekViewNewState<T>();
}

class WeekViewNewState<T extends Object?> extends State<WeekViewNew<T>> {
  late double _width;
  late double _height;
  late double _leftSideHourIndicatorWidth;
  late double _hourHeight;
  late DateTime _currentStartDate;
  late DateTime _currentEndDate;
  late DateTime _maxDate;
  late DateTime _minDate;
  late DateTime _currentWeek;
  late int _totalWeeks;
  late int _currentIndex;

  late TimeIntervalArranger<T> _timeIntervalArranger;

  late HourIndicatorSettings _hourIndicatorSettings;
  late CustomHourLinePainter _hourLinePainter;

  late HourIndicatorSettings _halfHourIndicatorSettings;
  late HourIndicatorSettings _currentTimeIndicatorSettings;
  late HourIndicatorSettings _quarterHourIndicatorSettings;

  late PageController _pageController;

  late DateWidgetBuilder _leftSideHourIndicatorBuilder;
  late TimeIntervalTileBuilder<T> _timeIntervalTileBuilder;
  late WeekPageHeaderBuilder _weekHeaderBuilder;
  late DateWidgetBuilder _weekDayBuilder;
  late WeekNumberBuilder _weekNumberBuilder;
  late FullDayTimeIntervalBuilder<T> _fullDayTimeIntervalBuilder;
  late DetectorBuilder _weekDetectorBuilder;

  late double _weekTitleWidth;
  late int _totalDaysInWeek;

  late VoidCallback _reloadCallback;

  TimeIntervalController<T>? _controller;

  late ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  late List<WeekDays> _weekDays;

  final _scrollConfiguration = TimeIntervalScrollConfiguration();

  @override
  void initState() {
    super.initState();

    _reloadCallback = _reload;

    _setWeekDays();
    _setDateRange();

    _currentWeek = (widget.initialDay ?? DateTime.now()).withoutTime;

    _regulateCurrentDate();

    _calculateHeights();
    _scrollController =
        ScrollController(initialScrollOffset: widget.scrollOffset);
    _pageController = PageController(initialPage: _currentIndex);
    _timeIntervalArranger =
        widget.timeIntervalArranger ?? SideTimeIntervalArranger<T>();

    _assignBuilders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = widget.controller ??
        CalendarControllerProvider.of<T>(context).controller;

    if (_controller != newController) {
      _controller = newController;

      _controller!
      // Removes existing callback.
        ..removeListener(_reloadCallback)

      // Reloads the view if there is any change in controller or
      // user adds new events.
        ..addListener(_reloadCallback);
    }
  }

  @override
  void didUpdateWidget(WeekViewNew<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller.
    final newController = widget.controller ??
        CalendarControllerProvider.of<T>(context).controller;

    if (newController != _controller) {
      _controller?.removeListener(_reloadCallback);
      _controller = newController;
      _controller?.addListener(_reloadCallback);
    }

    _setWeekDays();

    // Update date range.
    if (widget.minDay != oldWidget.minDay ||
        widget.maxDay != oldWidget.maxDay) {
      _setDateRange();
      _regulateCurrentDate();

      _pageController.jumpToPage(_currentIndex);
    }

    _timeIntervalArranger =
        widget.timeIntervalArranger ?? SideTimeIntervalArranger<T>();

    // Update heights.
    _calculateHeights();

    // Update builders and callbacks
    _assignBuilders();
  }

  @override
  void dispose() {
    _controller?.removeListener(_reloadCallback);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return
      SafeAreaWrapper(
      option: widget.safeAreaOption,
      child:
      LayoutBuilder(builder: (context, constraint) {
        _width = widget.width ?? constraint.maxWidth;
        _updateViewDimensions();
        return SizedBox(
          width: _width,
          child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: _weekHeaderBuilder(
                _currentStartDate,
                _currentEndDate,),
                  actions: [
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
                        //if(widget.s)
                        UsingBottomBarMenuItemButton(
                            handleUsingBottomBarChange:
                            widget.handleUsingBottomBarChange,
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
                  ]
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background),
                  child: SizedBox(
                    height: _height,
                    width: _width,
                    child: PageView.builder(
                      itemCount: _totalWeeks,
                      controller: _pageController,
                      onPageChanged: _onPageChange,
                      itemBuilder: (_, index) {
                        final dates = DateTime(_minDate.year, _minDate.month,
                            _minDate.day + (index * DateTime.daysPerWeek))
                            .datesOfWeek(start: widget.startDay);

                        return ValueListenableBuilder(
                          valueListenable: _scrollConfiguration,
                          builder: (_, __, ___) => InternalWeekViewPage<T>(
                            key: ValueKey(
                                _hourHeight.toString() + dates[0].toString()),
                            height: _height,
                            width: _width,
                            weekTitleWidth: _weekTitleWidth,
                            weekTitleHeight: widget.weekTitleHeight,
                            weekDayBuilder: _weekDayBuilder,
                            weekNumberBuilder: _weekNumberBuilder,
                            weekDetectorBuilder: _weekDetectorBuilder,
                            currentTimeIndicatorSettings:
                            _currentTimeIndicatorSettings,
                            leftSideHourIndicatorBuilder:
                            _leftSideHourIndicatorBuilder,
                            onTileTap: widget.onTimeIntervalTileTap,
                            onDateLongPress: widget.onDateLongPress,
                            onDateTap: widget.onDateTap,
                            timeIntervalTileBuilder: _timeIntervalTileBuilder,
                            heightPerMinute: widget.heightPerMinute,
                            hourIndicatorSettings: _hourIndicatorSettings,
                            hourLinePainter: _hourLinePainter,
                            halfHourIndicatorSettings:
                            _halfHourIndicatorSettings,
                            quarterHourIndicatorSettings:
                            _quarterHourIndicatorSettings,
                            dates: dates,
                            showLiveLine: widget.showLiveTimeLineInAllDays ||
                                _showLiveTimeIndicator(dates),
                            leftSideHourIndicatorOffset: widget.leftSideHourIndicatorOffset,
                            leftSideHourIndicatorWidth: _leftSideHourIndicatorWidth,
                            verticalLineOffset: 0,
                            showVerticalLine: widget.showVerticalLines,
                            controller: controller,
                            hourHeight: _hourHeight,
                            scrollController: _scrollController,
                            timeIntervalArranger: _timeIntervalArranger,
                            weekDays: _weekDays,
                            minuteSlotSize: widget.minuteSlotSize,
                            scrollConfiguration: _scrollConfiguration,
                            fullDayTimeIntervalBuilder:
                            _fullDayTimeIntervalBuilder,
                            showHalfHours: widget.showHalfHours,
                            showQuarterHours: widget.showQuarterHours,
                            emulateVerticalOffsetBy:
                            widget.emulateVerticalOffsetBy,
                            showWeekDayAtBottom: widget.showWeekDayAtBottom,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Returns [TimeIntervalController] associated with this Widget.
  ///
  /// This will throw [AssertionError] if controller is called before its
  /// initialization is complete.
  TimeIntervalController<T> get controller {
    if (_controller == null) {
      throw "EventController is not initialized yet.";
    }

    return _controller!;
  }

  /// Reloads page.
  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setWeekDays() {
    _weekDays = widget.weekDays.toSet().toList();

    if (!widget.showWeekends) {
      _weekDays
        ..remove(WeekDays.saturday)
        ..remove(WeekDays.sunday);
    }

    assert(
    _weekDays.isNotEmpty,
    "weekDays can not be empty.\n"
        "Make sure you are providing weekdays in initialization of "
        "WeekView. or showWeekends is true if you are providing only "
        "saturday or sunday in weekDays.");
    _totalDaysInWeek = _weekDays.length;
  }

  void _updateViewDimensions() {
    _leftSideHourIndicatorWidth = widget.leftSideHourIndicatorWidth ?? _width * 0.13;

    _currentTimeIndicatorSettings = widget.currentTimeIndicatorSettings ??
        HourIndicatorSettings(
          color: Constants.defaultLiveTimeIndicatorColor,
          height: widget.heightPerMinute,
          offset: 5,
        );

    assert(_currentTimeIndicatorSettings.height < _hourHeight,
    "liveTimeIndicator height must be less than minuteHeight * 60");

    _hourIndicatorSettings = widget.hourIndicatorSettings ??
        HourIndicatorSettings(
          height: widget.heightPerMinute,
          color: Constants.defaultBorderColor,
          offset: 5,
        );

    assert(_hourIndicatorSettings.height < _hourHeight,
    "hourIndicator height must be less than minuteHeight * 60");

    _weekTitleWidth =
        (_width - _leftSideHourIndicatorWidth - _hourIndicatorSettings.offset) /
            _totalDaysInWeek;

    _halfHourIndicatorSettings = widget.halfHourIndicatorSettings ??
        HourIndicatorSettings(
          height: widget.heightPerMinute,
          color: Constants.defaultBorderColor,
          offset: 5,
        );

    assert(_halfHourIndicatorSettings.height < _hourHeight,
    "halfHourIndicator height must be less than minuteHeight * 60");

    _quarterHourIndicatorSettings = widget.quarterHourIndicatorSettings ??
        HourIndicatorSettings(
          color: Constants.defaultBorderColor,
        );

    assert(_quarterHourIndicatorSettings.height < _hourHeight,
    "quarterHourIndicator height must be less than minuteHeight * 60");
  }

  void _calculateHeights() {
    _hourHeight = widget.heightPerMinute * 60;
    _height = _hourHeight * Constants.hoursADay;
  }

  void _assignBuilders() {
    _leftSideHourIndicatorBuilder = widget.leftSideHourIndicatorBuilder ??
        _defaultLeftSideHourIndicatorBuilder;
    _timeIntervalTileBuilder =
        widget.timeIntervalTileBuilder ?? _defaultTimeIntervalTileBuilder;
    _weekHeaderBuilder =
        widget.weekPageHeaderBuilder ?? _defaultWeekPageHeaderBuilder;
    _weekDayBuilder = widget.weekDayBuilder ?? _defaultWeekDayBuilder;
    _weekDetectorBuilder =
        widget.weekDetectorBuilder ?? _defaultPressDetectorBuilder;
    _weekNumberBuilder = widget.weekNumberBuilder ?? _defaultWeekNumberBuilder;
    _fullDayTimeIntervalBuilder =
        widget.fullDayTimeIntervalBuilder ?? _defaultFullDayTimeIntervalBuilder;
    _hourLinePainter = widget.hourLinePainter ?? _defaultHourLinePainter;
  }

  Widget _defaultFullDayTimeIntervalBuilder(
      List<CalendarTimeIntervalData<T>> timeIntervals, DateTime dateTime) {
    return FullDayTimeIntervalView(
      timeIntervals: timeIntervals,
      boxConstraints: BoxConstraints(maxHeight: 65),
      date: dateTime,
    );
  }

  /// Sets the current date of this month.
  ///
  /// This method is used in initState and onUpdateWidget methods to
  /// regulate current date in Month view.
  ///
  /// If maximum and minimum dates are change then first call _setDateRange
  /// and then _regulateCurrentDate method.
  ///
  void _regulateCurrentDate() {
    if (_currentWeek.isBefore(_minDate)) {
      _currentWeek = _minDate;
    } else if (_currentWeek.isAfter(_maxDate)) {
      _currentWeek = _maxDate;
    }

    _currentStartDate = _currentWeek.firstDayOfWeek(start: widget.startDay);
    _currentEndDate = _currentWeek.lastDayOfWeek(start: widget.startDay);
    _currentIndex =
        _minDate.getWeekDifference(_currentEndDate, start: widget.startDay);
  }

  /// Sets the minimum and maximum dates for current view.
  void _setDateRange() {
    _minDate = (widget.minDay ?? CalendarConstants.epochDate)
        .firstDayOfWeek(start: widget.startDay)
        .withoutTime;

    _maxDate = (widget.maxDay ?? CalendarConstants.maxDate)
        .lastDayOfWeek(start: widget.startDay)
        .withoutTime;

    assert(
    _minDate.isBefore(_maxDate),
    "Minimum date must be less than maximum date.\n"
        "Provided minimum date: $_minDate, maximum date: $_maxDate",
    );

    _totalWeeks =
        _minDate.getWeekDifference(_maxDate, start: widget.startDay) + 1;
  }

  /// Default press detector builder. This builder will be used if
  /// [widget.weekDetectorBuilder] is null.
  ///
  Widget _defaultPressDetectorBuilder({
    required DateTime date,
    required double height,
    required double width,
    required double heightPerMinute,
    required MinuteSlotSize minuteSlotSize,
  }) {
    final heightPerSlot = minuteSlotSize.minutes * heightPerMinute;
    final slots = (Constants.hoursADay * 60) ~/ minuteSlotSize.minutes;

    return Container(
      height: height,
      width: width,
      child: Stack(
        children: [
          for (int i = 0; i < slots; i++)
            Positioned(
              top: heightPerSlot * i,
              left: 0,
              right: 0,
              bottom: height - (heightPerSlot * (i + 1)),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPress: () => widget.onDateLongPress?.call(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    0,
                    minuteSlotSize.minutes * i,
                  ),
                ),
                onTap: () => widget.onDateTap?.call(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    0,
                    minuteSlotSize.minutes * i,
                  ),
                ),
                child: SizedBox(width: width, height: heightPerSlot),
              ),
            ),
        ],
      ),
    );
  }

  /// Default builder for week line.
  Widget _defaultWeekDayBuilder(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    String getWeekday(int dayIndex) {
      final weekday = localizations.narrowWeekdays[(dayIndex % 7 + 1) % 7];
      return weekday;
    }
    final List<String> weekTitles = List.generate(7, (index) => getWeekday(index));
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.weekDayStringBuilder?.call(date.weekday - 1) ??
              weekTitles[date.weekday - 1]),
          Text(widget.weekDayDateStringBuilder?.call(date.day) ??
              date.day.toString()),
        ],
      ),
    );
  }

  /// Default builder for week number.
  Widget _defaultWeekNumberBuilder(DateTime date) {
    final daysToAdd = DateTime.thursday - date.weekday;
    final thursday = daysToAdd > 0
        ? date.add(Duration(days: daysToAdd))
        : date.subtract(Duration(days: daysToAdd.abs()));
    final weekNumber =
        (date.difference(DateTime(thursday.year)).inDays / 7).floor() + 1;
    return Center(
      child: Text("$weekNumber"),
    );
  }

  /// Default timeline builder this builder will be used if
  /// [widget.timeIntervalTileBuilder] is null
  ///
  Widget _defaultLeftSideHourIndicatorBuilder(DateTime date) {
    final locale = Localizations.localeOf(context);
    // final hour = ((date.hour - 1) % 12) + 1;
    // final timeLineString = (widget.timeLineStringBuilder != null)
    //     ? widget.timeLineStringBuilder!(date)
    //     : date.minute != 0
    //         ? "$hour:${date.minute}"
    //         : "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}";

    final timeLineString = widget
        .displayTimeStringOfLeftSideHourIndicatorBuilder
        ?.call(date, locale) ??
        date.toString().substring(11, 16);

    return Transform.translate(
      offset: Offset(0, -7.5),
      child: Padding(
        padding: const EdgeInsets.only(right: 7.0),
        child: Text(
          timeLineString,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }

  /// Default timeline builder. This builder will be used if
  /// [widget.timeIntervalTileBuilder] is null
  Widget _defaultTimeIntervalTileBuilder(
      DateTime date,
      List<CalendarTimeIntervalData<T>> events,
      Rect boundary,
      DateTime startDuration,
      DateTime endDuration) {
    if (events.isNotEmpty) {
      return RoundedTimeIntervalTile(
        borderRadius: BorderRadius.circular(6.0),
        title: events[0].title,
        titleStyle: events[0].titleStyle ??
            TextStyle(
              fontSize: 12,
              color: events[0].color.accent,
            ),
        descriptionStyle: events[0].descriptionStyle,
        totalEvents: events.length,
        padding: EdgeInsets.all(7.0),
        backgroundColor: events[0].color,
      );
    } else {
      return Container();
    }
  }

  /// Default view header builder. This builder will be used if
  /// [widget.dayTitleBuilder] is null.
  Widget _defaultWeekPageHeaderBuilder(
      DateTime startDate,
      DateTime endDate,
      ) {
    return WeekPageHeaderNew(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      onNextWeek: nextPage,
      onPreviousWeek: previousPage,
      jumpToCurrentWeek: () => jumpToWeek(DateTime.now()),
      onTitleTapped: () async {
        if (widget.onHeaderTitleTap != null) {
          widget.onHeaderTitleTap!(startDate);
        } else {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: startDate,
            firstDate: _minDate,
            lastDate: _maxDate,
          );

          if (selectedDate == null) return;
          jumpToWeek(selectedDate);
        }
      },
      headerStringBuilder: widget.headerStringBuilder,
      headerStyle: widget.headerStyle,
    );
  }

  HourLinePainter _defaultHourLinePainter(
      Color lineColor,
      double lineHeight,
      double offset,
      double minuteHeight,
      bool showVerticalLine,
      double verticalLineOffset,
      LineStyle lineStyle,
      double dashWidth,
      double dashSpaceWidth,
      double emulateVerticalOffsetBy,
      ) {
    return HourLinePainter(
      lineColor: lineColor,
      lineHeight: lineHeight,
      offset: offset,
      minuteHeight: minuteHeight,
      verticalLineOffset: verticalLineOffset,
      showVerticalLine: showVerticalLine,
      lineStyle: lineStyle,
      dashWidth: dashWidth,
      dashSpaceWidth: dashSpaceWidth,
      emulateVerticalOffsetBy: emulateVerticalOffsetBy,
    );
  }

  /// Called when user change page using any gesture or inbuilt functions.
  void _onPageChange(int index) {
    if (mounted) {
      setState(() {
        _currentStartDate = DateTime(
          _currentStartDate.year,
          _currentStartDate.month,
          _currentStartDate.day + (index - _currentIndex) * 7,
        );
        _currentEndDate = _currentStartDate.add(Duration(days: 6));
        _currentIndex = index;
      });
    }
    widget.onPageChange?.call(_currentStartDate, _currentIndex);
  }

  /// Animate to next page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayView.pageTransitionDuration] and [DayView.pageTransitionCurve]
  /// respectively.
  void nextPage({Duration? duration, Curve? curve}) {
    _pageController.nextPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Animate to previous page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayView.pageTransitionDuration] and [DayView.pageTransitionCurve]
  /// respectively.
  void previousPage({Duration? duration, Curve? curve}) {
    _pageController.previousPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Jumps to page number [page]
  ///
  ///
  void jumpToPage(int page) => _pageController.jumpToPage(page);

  /// Animate to page number [page].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayView.pageTransitionDuration] and [DayView.pageTransitionCurve]
  /// respectively.
  Future<void> animateToPage(int page,
      {Duration? duration, Curve? curve}) async {
    await _pageController.animateToPage(page,
        duration: duration ?? widget.pageTransitionDuration,
        curve: curve ?? widget.pageTransitionCurve);
  }

  /// Returns current page number.
  int get currentPage => _currentIndex;

  /// Jumps to page which gives day calendar for [week]
  void jumpToWeek(DateTime week) {
    if (week.isBefore(_minDate) || week.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    _pageController
        .jumpToPage(_minDate.getWeekDifference(week, start: widget.startDay));
  }

  /// Animate to page which gives day calendar for [week].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [WeekViewNew.pageTransitionDuration] and [WeekViewNew.pageTransitionCurve]
  /// respectively.
  Future<void> animateToWeek(DateTime week,
      {Duration? duration, Curve? curve}) async {
    if (week.isBefore(_minDate) || week.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    await _pageController.animateToPage(
      _minDate.getWeekDifference(week, start: widget.startDay),
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Returns the current visible week's first date.
  DateTime get currentDate => DateTime(
      _currentStartDate.year, _currentStartDate.month, _currentStartDate.day);

  /// Jumps to page which contains given events and make event
  /// tile visible to user.
  ///
  Future<void> jumpToEvent(CalendarTimeIntervalData<T> event) async {
    jumpToWeek(event.date);

    await _scrollConfiguration.setScrollTimeInterval(
      timeInterval: event,
      duration: Duration.zero,
      curve: Curves.ease,
    );
  }

  /// Animate to page which contains given events and make event
  /// tile visible to user.
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayView.pageTransitionDuration] and [DayView.pageTransitionCurve]
  /// respectively.
  ///
  /// Actual duration will be 2 times the given duration.
  ///
  /// Ex, If provided duration is 200 milliseconds then this function will take
  /// 200 milliseconds for animate to page then 200 milliseconds for
  /// scroll to event tile.
  ///
  ///
  Future<void> animateToEvent(CalendarTimeIntervalData<T> event,
      {Duration? duration, Curve? curve}) async {
    await animateToWeek(event.date, duration: duration, curve: curve);
    await _scrollConfiguration.setScrollTimeInterval(
      timeInterval: event,
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Animate to specific scroll controller offset
  void animateTo(
      double offset, {
        Duration duration = const Duration(milliseconds: 200),
        Curve curve = Curves.linear,
      }) {
    _scrollController.animateTo(
      offset,
      duration: duration,
      curve: curve,
    );
  }

  /// check if any dates contains current date or not.
  /// Returns true if it does else false.
  bool _showLiveTimeIndicator(List<DateTime> dates) =>
      dates.any((date) => date.compareWithoutTime(DateTime.now()));
}

class WeekPageHeaderNew extends CalendarPageHeader {
  /// A header widget to display on week view.
  const WeekPageHeaderNew({
    Key? key,
    VoidCallback? onNextWeek,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousWeek,
    VoidCallback? jumpToCurrentWeek,
    required DateTime startDate,
    required DateTime endDate,
    DateTimeStringProvider? headerStringBuilder,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
    key: key,
    date: startDate,
    secondaryDate: endDate,
    onNext: onNextWeek,
    onPrevious: onPreviousWeek,
    jumpToCurrently: jumpToCurrentWeek,
    onTitleTapped: onTitleTapped,
    dateStringBuilder:
    headerStringBuilder ?? WeekPageHeaderNew._weekStringBuilder,
    headerStyle: headerStyle,
  );

  // static String _weekStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} / ${date.month} / ${date.year} to "
  //     "${secondaryDate != null ? "${secondaryDate.day} / "
  //         "${secondaryDate.month} / ${secondaryDate.year}" : ""}";

  static String _weekStringBuilder(DateTime date, Locale locale,  {DateTime? secondaryDate}) {
    final format = DateFormat('MMMM yyyy', locale.languageCode);
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(Theme.of(context).colorScheme.background);
    final locale = Localizations.localeOf(context);
    final thisWeek= DateTime.now().withoutTime;
    final thisWeekString = DateFormat('MMMM yyyy', locale.languageCode).format(thisWeek);

    return Container(
      margin: headerStyle.headerMargin,
      padding: headerStyle.headerPadding,
      decoration:
      headerStyle.decoration ?? BoxDecoration(
          //color: Theme.of(context).colorScheme.background
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Expanded(
            child: InkWell(
              onTap: onTitleTapped,
              child: Text(
                dateStringBuilder(date, locale, secondaryDate: secondaryDate),
                //textAlign: headerStyle.titleAlign,
                //style: headerStyle.headerTextStyle,
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (thisWeekString != dateStringBuilder(date, locale, secondaryDate: secondaryDate))
            IconButton(
              onPressed: jumpToCurrently,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: headerStyle.rightIconPadding,
              icon: Icon(
                Icons.today_outlined,
                size: 30,
                //color: labelColor,
              ),
            ),
          if (headerStyle.leftIconVisible && Platform.isWindows)
            IconButton(
              onPressed: onPrevious,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: headerStyle.leftIconPadding,
              icon: headerStyle.leftIcon ??
                  Icon(
                    Icons.chevron_left,
                    size: 30,
                    //color: labelColor,
                  ),
            ),
          if (headerStyle.rightIconVisible && Platform.isWindows)
            IconButton(
              onPressed: onNext,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: headerStyle.rightIconPadding,
              icon: headerStyle.rightIcon ??
                  Icon(
                    Icons.chevron_right,
                    size: 30,
                    //color: labelColor,
                  ),
            ),
        ],
      ),
    );
  }
}
