import 'dart:async';
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

class DayViewNew<T extends Object?> extends StatefulWidget {
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

  /// A function that returns a [Widget] that determines appearance of each
  /// cell in day calendar.
  final TimeIntervalTileBuilder<T>? eventTileBuilder;

  /// A function to generate the DateString in the calendar title.
  /// Useful for I18n
  final DateTimeStringProvider? dateStringBuilder;

  /// A function to generate the TimeString in the timeline.
  /// Useful for I18n
  final DateTimeStringProvider? displayTimeStringOfLeftSideHourIndicatorBuilder;

  /// A function that returns a [Widget] that will be displayed left side of
  /// day view.
  ///
  /// If null is provided then no time line will be visible.
  ///
  final DateWidgetBuilder? leftSideHourIndicatorBuilder;

  /// Builds day title bar.
  final DateWidgetBuilder? dayTitleBuilder;

  /// Builds custom PressDetector widget
  ///
  /// If null, internal PressDetector will be used to handle onDateLongPress()
  ///
  final DetectorBuilder? dayDetectorBuilder;

  /// Defines how events are arranged in day view.
  /// User can define custom event arranger by implementing [TimeIntervalArranger]
  /// class and pass object of that class as argument.
  final TimeIntervalArranger<T>? timeIntervalArranger;

  /// This callback will run whenever page will change.
  final CalendarPageChangeCallBack? onPageChange;

  /// Determines the lower boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.epochDate] is default.
  final DateTime? minDay;

  /// Determines upper boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.maxDate] is default.
  final DateTime? maxDay;

  /// Defines initial display day.
  ///
  /// If not provided [DateTime.now] is default date.
  final DateTime? initialDay;

  /// Defines settings for hour indication lines.
  ///
  /// Pass [HourIndicatorSettings.none] to remove Hour lines.
  final HourIndicatorSettings? hourIndicatorSettings;

  /// A funtion that returns a [CustomPainter].
  ///
  /// Use this if you want to paint custom hour lines.
  final CustomHourLinePainter? hourLinePainter;

  /// Defines settings for live time indicator.
  ///
  /// Pass [HourIndicatorSettings.none] to remove live time indicator.
  final HourIndicatorSettings? liveTimeIndicatorSettings;

  /// Defines settings for half hour indication lines.
  ///
  /// Pass [HourIndicatorSettings.none] to remove half hour lines.
  final HourIndicatorSettings? halfHourIndicatorSettings;

  /// Defines settings for quarter hour indication lines.
  ///
  /// Pass [HourIndicatorSettings.none] to remove quarter hour lines.
  final HourIndicatorSettings? quarterHourIndicatorSettings;

  /// Page transition duration used when user try to change page using
  /// [DayViewNewState.nextPage] or [DayViewNewState.previousPage]
  final Duration pageTransitionDuration;

  /// Page transition curve used when user try to change page using
  /// [DayViewNewState.nextPage] or [DayViewNewState.previousPage]
  final Curve pageTransitionCurve;

  /// A required parameters that controls events for day view.
  ///
  /// This will auto update day view when user adds events in controller.
  /// This controller will store all the events. And returns events
  /// for particular day.
  final TimeIntervalController<T>? controller;

  /// Defines height occupied by one minute of interval.
  /// This will be used to calculate total height of day view.
  final double heightPerMinute;

  /// Defines the width of timeline. If null then it will
  /// occupies 13% of [width].
  final double? leftSideHourIndicatorWidth;

  /// if parsed true then live time line will be displayed in all days.
  /// else it will be displayed in [DateTime.now] only.
  ///
  /// Parse [HourIndicatorSettings.none] as argument in
  /// [DayViewNew.liveTimeIndicatorSettings]
  /// to remove time line completely.
  final bool showLiveTimeLineInAllDays;

  /// Defines offset for timeline.
  ///
  /// This will translate all the widgets returned by
  /// [DayViewNew.leftSideHourIndicatorBuilder] by provided offset.
  ///
  /// If offset is positive all the widgets will be translated up.
  ///
  /// If offset is negative all the widgets will be translated down.
  /// Default value is 0.
  final double leftSideHourIndicatorOffset;

  /// Width of day page.
  ///
  /// if null provided then device width will be considered.
  final double? width;

  /// If true this will display vertical line in day view.
  final bool showVerticalLine;

  /// Defines offset of vertical line from hour line starts.
  final double verticalLineOffset;

  /// Background colour of day view page.
  //final Color? backgroundColor;

  /// Defines initial offset of first page that will be displayed when
  /// [DayViewNew] is initialized.
  ///
  /// If [scrollOffset] is null then [startDuration] will be considered for
  /// initial offset.
  final double? scrollOffset;

  /// This method will be called when user taps on event tile.
  final CellTapCallback<T>? onEventTap;

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

  /// Defines size of the slots that provides long press callback on area
  /// where events are not there.
  final MinuteSlotSize minuteSlotSize;

  /// Use this field to disable the calendar scrolling
  final ScrollPhysics? scrollPhysics;

  /// Use this field to disable the page view scrolling behavior
  final ScrollPhysics? pageViewPhysics;

  /// Style for DayView header.
  final HeaderStyle headerStyle;

  /// Option for SafeArea.
  final SafeAreaOption safeAreaOption;

  /// Display full day event builder.
  final FullDayTimeIntervalBuilder<T>? fullDayEventBuilder;

  /// Show half hour indicator
  final bool showHalfHours;

  /// Show quarter hour indicator(15min & 45min).
  final bool showQuarterHours;

  /// It define the starting duration from where day view page will be visible
  /// By default it will be Duration(hours:0)
  final Duration startDuration;

  /// Callback for the Header title
  final HeaderTitleCallback? onHeaderTitleTap;

  /// Emulate vertical line offset from hour line starts.
  final double emulateVerticalOffsetBy;

  /// Main widget for day view.
  const DayViewNew({
    Key? key,
    this.eventTileBuilder,
    this.dateStringBuilder,
    this.displayTimeStringOfLeftSideHourIndicatorBuilder,
    this.controller,
    this.showVerticalLine = true,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.ease,
    this.width,
    this.minDay,
    this.maxDay,
    this.initialDay,
    this.hourIndicatorSettings,
    this.hourLinePainter,
    this.heightPerMinute = 0.7,
    this.leftSideHourIndicatorBuilder,
    this.leftSideHourIndicatorWidth,
    this.leftSideHourIndicatorOffset = 0,
    this.showLiveTimeLineInAllDays = false,
    this.liveTimeIndicatorSettings,
    this.onPageChange,
    this.dayTitleBuilder,
    this.timeIntervalArranger,
    this.verticalLineOffset = 10,
    //this.backgroundColor = Colors.white,
    this.scrollOffset,
    this.onEventTap,
    this.onDateLongPress,
    this.onDateTap,
    this.minuteSlotSize = MinuteSlotSize.minutes60,
    this.headerStyle = const HeaderStyle(),
    this.fullDayEventBuilder,
    this.safeAreaOption = const SafeAreaOption(),
    this.scrollPhysics,
    this.pageViewPhysics,
    this.dayDetectorBuilder,
    this.showHalfHours = false,
    this.showQuarterHours = false,
    this.halfHourIndicatorSettings,
    this.quarterHourIndicatorSettings,
    this.startDuration = const Duration(hours: 0),
    this.onHeaderTitleTap,
    this.emulateVerticalOffsetBy = 0,
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
  })  : assert(!(onHeaderTitleTap != null && dayTitleBuilder != null),
            "can't use [onHeaderTitleTap] & [dayTitleBuilder] simultaneously"),
        assert(leftSideHourIndicatorOffset >= 0,
            "timeLineOffset must be greater than or equal to 0"),
        assert(width == null || width > 0,
            "Calendar width must be greater than 0."),
        assert(
            leftSideHourIndicatorWidth == null ||
                leftSideHourIndicatorWidth > 0,
            "Time line width must be greater than 0."),
        assert(
            heightPerMinute > 0, "Height per minute must be greater than 0."),
        assert(
          dayDetectorBuilder == null || onDateLongPress == null,
          """If you use [dayPressDetectorBuilder]
          do not provide [onDateLongPress]""",
        ),
        super(key: key);

  @override
  DayViewNewState<T> createState() => DayViewNewState<T>();
}

class DayViewNewState<T extends Object?> extends State<DayViewNew<T>> {
  late double _width;
  late double _height;
  late double _leftSideHourIndicatorWidth;
  late double _hourHeight;
  late DateTime _currentDate;
  late DateTime _maxDate;
  late DateTime _minDate;
  late int _totalDays;
  late int _currentIndex;

  late TimeIntervalArranger<T> _timeIntervalArranger;

  late HourIndicatorSettings _hourIndicatorSettings;
  late HourIndicatorSettings _halfHourIndicatorSettings;
  late HourIndicatorSettings _quarterHourIndicatorSettings;
  late CustomHourLinePainter _hourLinePainter;

  late HourIndicatorSettings _liveTimeIndicatorSettings;

  late PageController _pageController;

  late DateWidgetBuilder _leftSideHourIndicatorBuilder;

  late TimeIntervalTileBuilder<T> _timeIntervalTileBuilder;

  late DateWidgetBuilder _dayTitleBuilder;

  late FullDayTimeIntervalBuilder<T> _fullDayEventBuilder;

  late DetectorBuilder _dayDetectorBuilder;

  TimeIntervalController<T>? _controller;

  late ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  late VoidCallback _reloadCallback;

  final _scrollConfiguration = TimeIntervalScrollConfiguration<T>();

  @override
  void initState() {
    super.initState();

    _reloadCallback = _reload;
    _setDateRange();

    _currentDate = (widget.initialDay ?? DateTime.now()).withoutTime;

    _regulateCurrentDate();

    _calculateHeights();
    _scrollController = ScrollController(
        initialScrollOffset: widget.scrollOffset ??
            widget.startDuration.inMinutes * widget.heightPerMinute);
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

    if (newController != _controller) {
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
  void didUpdateWidget(DayViewNew<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller.
    final newController = widget.controller ??
        CalendarControllerProvider.of<T>(context).controller;

    if (newController != _controller) {
      _controller?.removeListener(_reloadCallback);
      _controller = newController;
      _controller?.addListener(_reloadCallback);
    }

    // Update date range.
    if (widget.minDay != oldWidget.minDay ||
        widget.maxDay != oldWidget.maxDay) {
      _setDateRange();
      _regulateCurrentDate();

      _pageController.jumpToPage(_currentIndex);
    }

    _timeIntervalArranger =
        widget.timeIntervalArranger ?? SideTimeIntervalArranger<T>();
    //_timeIntervalArranger = widget.timeIntervalArranger ?? MergeTimeIntervalArranger<T>();

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
    return SafeAreaWrapper(
      option: widget.safeAreaOption,
      child: LayoutBuilder(builder: (context, constraint) {
        _width = widget.width ?? constraint.maxWidth;
        _updateViewDimensions();
        return SizedBox(
          width: _width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(title: _dayTitleBuilder(_currentDate), actions: [
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
              ]),
              Expanded(
                child: DecoratedBox(
                  //decoration: BoxDecoration(color: widget.backgroundColor),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background),
                  child: SizedBox(
                    height: _height,
                    child: PageView.builder(
                      physics: widget.pageViewPhysics,
                      itemCount: _totalDays,
                      controller: _pageController,
                      onPageChanged: _onPageChange,
                      itemBuilder: (_, index) {
                        final date = DateTime(_minDate.year, _minDate.month,
                            _minDate.day + index);
                        return ValueListenableBuilder(
                          valueListenable: _scrollConfiguration,
                          builder: (_, __, ___) => InternalDayViewPage<T>(
                            key: ValueKey(
                                _hourHeight.toString() + date.toString()),
                            width: _width,
                            liveTimeIndicatorSettings:
                                _liveTimeIndicatorSettings,
                            leftSideHourIndicatorBuilder:
                                _leftSideHourIndicatorBuilder,
                            dayDetectorBuilder: _dayDetectorBuilder,
                            timeIntervalTileBuilder: _timeIntervalTileBuilder,
                            heightPerMinute: widget.heightPerMinute,
                            hourIndicatorSettings: _hourIndicatorSettings,
                            hourLinePainter: _hourLinePainter,
                            date: date,
                            onTileTap: widget.onEventTap,
                            onDateLongPress: widget.onDateLongPress,
                            onDateTap: widget.onDateTap,
                            showLiveLine: widget.showLiveTimeLineInAllDays ||
                                date.compareWithoutTime(DateTime.now()),
                            leftSideHourIndicatorOffset:
                                widget.leftSideHourIndicatorOffset,
                            leftSideHourIndicatorWidth:
                                _leftSideHourIndicatorWidth,
                            verticalLineOffset: widget.verticalLineOffset,
                            showVerticalLine: widget.showVerticalLine,
                            height: _height,
                            controller: controller,
                            hourHeight: _hourHeight,
                            timeIntervalArranger: _timeIntervalArranger,
                            minuteSlotSize: widget.minuteSlotSize,
                            scrollNotifier: _scrollConfiguration,
                            fullDayEventBuilder: _fullDayEventBuilder,
                            scrollController: _scrollController,
                            showHalfHours: widget.showHalfHours,
                            showQuarterHours: widget.showQuarterHours,
                            halfHourIndicatorSettings:
                                _halfHourIndicatorSettings,
                            quarterHourIndicatorSettings:
                                _quarterHourIndicatorSettings,
                            emulateVerticalOffsetBy:
                                widget.emulateVerticalOffsetBy,
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
  ///
  TimeIntervalController<T> get controller {
    if (_controller == null) {
      throw "EventController is not initialized yet.";
    }

    return _controller!;
  }

  /// Reloads page.
  ///
  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Updates data related to size of this view.
  void _updateViewDimensions() {
    _leftSideHourIndicatorWidth =
        widget.leftSideHourIndicatorWidth ?? _width * 0.13;

    _liveTimeIndicatorSettings = widget.liveTimeIndicatorSettings ??
        HourIndicatorSettings(
          color: Constants.defaultLiveTimeIndicatorColor,
          height: widget.heightPerMinute,
          offset: 5 + widget.verticalLineOffset,
        );

    assert(_liveTimeIndicatorSettings.height < _hourHeight,
        "liveTimeIndicator height must be less than minuteHeight * 60");

    _hourIndicatorSettings = widget.hourIndicatorSettings ??
        HourIndicatorSettings(
          height: widget.heightPerMinute,
          color: Constants.defaultBorderColor,
          offset: 5,
        );

    assert(_hourIndicatorSettings.height < _hourHeight,
        "hourIndicator height must be less than minuteHeight * 60");

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
          height: widget.heightPerMinute,
          color: Constants.defaultBorderColor,
          offset: 5,
        );

    assert(_quarterHourIndicatorSettings.height < _hourHeight,
        "quarterHourIndicator height must be less than minuteHeight * 60");
  }

  void _calculateHeights() {
    _hourHeight = widget.heightPerMinute * 60;
    _height = _hourHeight * Constants.hoursADay;
  }

  void _assignBuilders() {
    //_timeLineBuilder = widget.timeLineBuilder ?? _defaultTimeLineBuilder;
    _leftSideHourIndicatorBuilder = widget.leftSideHourIndicatorBuilder ??
        _defaultLeftSideHourIndicatorBuilder;
    _timeIntervalTileBuilder =
        widget.eventTileBuilder ?? _defaultTimeIntervalTileBuilder;
    _dayTitleBuilder = widget.dayTitleBuilder ?? _defaultDayBuilder;
    _fullDayEventBuilder =
        widget.fullDayEventBuilder ?? _defaultFullDayTimeIntervalBuilder;
    _dayDetectorBuilder =
        widget.dayDetectorBuilder ?? _defaultPressDetectorBuilder;
    _hourLinePainter = widget.hourLinePainter ?? _defaultHourLinePainter;
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
    if (_currentDate.isBefore(_minDate)) {
      _currentDate = _minDate;
    } else if (_currentDate.isAfter(_maxDate)) {
      _currentDate = _maxDate;
    }

    _currentIndex = _currentDate.getDayDifference(_minDate);
  }

  /// Sets the minimum and maximum dates for current view.
  void _setDateRange() {
    _minDate = (widget.minDay ?? CalendarConstants.epochDate).withoutTime;
    _maxDate = (widget.maxDay ?? CalendarConstants.maxDate).withoutTime;

    assert(
      !_maxDate.isBefore(_minDate),
      "Minimum date should be less than maximum date.\n"
      "Provided minimum date: $_minDate, maximum date: $_maxDate",
    );

    _totalDays = _maxDate.getDayDifference(_minDate) + 1;
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

  /// Default timeline builder this builder will be used if
  /// [widget.timeIntervalTileBuilder] is null
  ///
  Widget _defaultLeftSideHourIndicatorBuilder(date) =>
      DefaultLeftSideHourIndicatorMark(
          date: date,
          leftSideHourIndicatorTimeStringBuilder:
              widget.displayTimeStringOfLeftSideHourIndicatorBuilder);

  /// Default timeline builder. This builder will be used if
  /// [widget.timeIntervalTileBuilder] is null
  ///
  Widget _defaultTimeIntervalTileBuilder(
    DateTime date,
    List<CalendarTimeIntervalData<T>> timeIntervals,
    Rect boundary,
    DateTime startDuration,
    DateTime endDuration,
  ) {
    if (timeIntervals.isNotEmpty) {
      return RoundedTimeIntervalTile(
        borderRadius: BorderRadius.circular(10.0),
        title: timeIntervals[0].title,
        totalEvents: timeIntervals.length - 1,
        description: timeIntervals[0].description,
        padding: EdgeInsets.all(10.0),
        backgroundColor: timeIntervals[0].color,
        margin: EdgeInsets.all(2.0),
        titleStyle: timeIntervals[0].titleStyle,
        descriptionStyle: timeIntervals[0].descriptionStyle,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Default view header builder. This builder will be used if
  /// [widget.dayTitleBuilder] is null.
  ///
  Widget _defaultDayBuilder(DateTime date) {
    final today = DateTime.now().withoutTime;
    final todayIndex = today.getDayDifference(_minDate);

    return DayPageHeaderNew(
      date: _currentDate,
      dateStringBuilder: widget.dateStringBuilder,
      onNextDay: nextPage,
      onPreviousDay: previousPage,
      jumpToToday: () => jumpToPage(todayIndex),
      onTitleTapped: () async {
        if (widget.onHeaderTitleTap != null) {
          widget.onHeaderTitleTap!(date);
        } else {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: _minDate,
            lastDate: _maxDate,
          );

          if (selectedDate == null) return;
          jumpToDate(selectedDate);
        }
      },
      headerStyle: widget.headerStyle,
      //locale: Localizations.localeOf(context),
    );
  }

  Widget _defaultFullDayTimeIntervalBuilder(
          List<CalendarTimeIntervalData<T>> timeIntervals, DateTime date) =>
      FullDayTimeIntervalView(timeIntervals: timeIntervals, date: date);

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
  ///
  void _onPageChange(int index) {
    if (mounted) {
      setState(() {
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month,
          _currentDate.day + (index - _currentIndex),
        );
        _currentIndex = index;
      });
    }
    animateToDuration(widget.startDuration);
    widget.onPageChange?.call(_currentDate, _currentIndex);
  }

  /// Animate to next page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayViewNew.pageTransitionDuration] and [DayViewNew.pageTransitionCurve]
  /// respectively.
  ///
  ///
  void nextPage({Duration? duration, Curve? curve}) => _pageController.nextPage(
        duration: duration ?? widget.pageTransitionDuration,
        curve: curve ?? widget.pageTransitionCurve,
      );

  /// Animate to previous page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayViewNew.pageTransitionDuration] and [DayViewNew.pageTransitionCurve]
  /// respectively.
  ///
  ///
  void previousPage({Duration? duration, Curve? curve}) =>
      _pageController.previousPage(
        duration: duration ?? widget.pageTransitionDuration,
        curve: curve ?? widget.pageTransitionCurve,
      );

  /// Jumps to page number [page]
  ///
  ///
  void jumpToPage(int page) => _pageController.jumpToPage(page);

  /// Animate to page number [page].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayViewNew.pageTransitionDuration] and [DayViewNew.pageTransitionCurve]
  /// respectively.
  ///
  ///
  Future<void> animateToPage(int page, {Duration? duration, Curve? curve}) =>
      _pageController.animateToPage(page,
          duration: duration ?? widget.pageTransitionDuration,
          curve: curve ?? widget.pageTransitionCurve);

  /// Returns current page number.
  ///
  ///
  int get currentPage => _currentIndex;

  /// Jumps to page which gives day calendar for [date]
  ///
  ///
  void jumpToDate(DateTime date) {
    if (date.isBefore(_minDate) || date.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    _pageController.jumpToPage(_minDate.getDayDifference(date));
  }

  /// Animate to page which gives day calendar for [date].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [DayViewNew.pageTransitionDuration] and [DayViewNew.pageTransitionCurve]
  /// respectively.
  ///
  ///
  Future<void> animateToDate(DateTime date,
      {Duration? duration, Curve? curve}) async {
    if (date.isBefore(_minDate) || date.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    await _pageController.animateToPage(
      _minDate.getDayDifference(date),
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Jumps to page which contains given events and make event
  /// tile visible to user.
  ///
  Future<void> jumpToEvent(CalendarTimeIntervalData<T> event) async {
    jumpToDate(event.date);

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
  /// as [DayViewNew.pageTransitionDuration] and [DayViewNew.pageTransitionCurve]
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
    await animateToDate(event.date, duration: duration, curve: curve);
    await _scrollConfiguration.setScrollTimeInterval(
      timeInterval: event,
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Animate to specific offset in a day view using the start duration
  Future<void> animateToDuration(
    Duration startDuration, {
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.linear,
  }) async {
    final offSetForSingleMinute = _height / 24 / 60;
    final startDurationInMinutes = startDuration.inMinutes;

    // Added ternary condition below to take care if user passing duration
    // above 24 hrs then we take it max as 24 hours only
    final offset = offSetForSingleMinute *
        (startDurationInMinutes > 3600 ? 3600 : startDurationInMinutes);
    animateTo(
      offset.toDouble(),
      duration: duration,
      curve: curve,
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

  /// Returns the current visible date in day view.
  DateTime get currentDate =>
      DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
}

/// A header widget to display on day view.
class DayPageHeaderNew extends CalendarPageHeader {
  /// A header widget to display on day view.
  const DayPageHeaderNew({
    Key? key,
    VoidCallback? onNextDay,
    VoidCallback? onPreviousDay,
    VoidCallback? jumpToToday,
    AsyncCallback? onTitleTapped,
    DateTimeStringProvider? dateStringBuilder,
    required DateTime date,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: date,
          onNext: onNextDay,
          onPrevious: onPreviousDay,
          jumpToCurrently: jumpToToday,
          onTitleTapped: onTitleTapped,
          dateStringBuilder:
              dateStringBuilder ?? DayPageHeaderNew._dayStringBuilder,
          headerStyle: headerStyle,
        );

  // static String _dayStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} - ${date.month} - ${date.year}";

  static String _dayStringBuilder(DateTime date, Locale locale,
      {DateTime? secondaryDate}) {
    final format = DateFormat('EEE, d MMMM yyyy', locale.languageCode);
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(Theme.of(context).colorScheme.background);
    final locale = Localizations.localeOf(context);
    final today = DateTime.now().withoutTime;
    final todayString =
        DateFormat('EEE, d MMMM yyyy', locale.languageCode).format(today);

    return Container(
      margin: headerStyle.headerMargin,
      padding: headerStyle.headerPadding,
      decoration: headerStyle.decoration ??
          BoxDecoration(
              //color:  contrastColor(Theme.of(context).colorScheme.background),
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
          if (todayString !=
              dateStringBuilder(date, locale, secondaryDate: secondaryDate))
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
