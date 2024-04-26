import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';

import '../screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import '../utils/constants.dart';
import 'month_view.dart';

class TasksMonthView extends StatefulWidget {
  //final GlobalKey<WeekViewState>? state;
  //final double? width;

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

  const TasksMonthView({
    Key? key,
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
    //this.state
  }) : super(key: key);

  @override
  _TasksMonthViewState createState() => _TasksMonthViewState();
}

class _TasksMonthViewState extends State<TasksMonthView> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final timeIntervals = await _databaseManager.timeIntervals();
    for (final timeInterval in timeIntervals) {
      if (timeInterval.taskId != null) {
        final task = await _databaseManager.task(timeInterval.taskId!);
        timeInterval.color = task.color;
        timeInterval.title = task.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      } else if (timeInterval.measurableTaskId != null) {
        final measurableTask = await _databaseManager
            .measurableTask(timeInterval.measurableTaskId!);
        timeInterval.color = measurableTask.color;
        timeInterval.title = measurableTask.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      } else if (timeInterval.taskWithSubtasksId != null) {
        final taskWithSubtasks = await _databaseManager
            .taskWithSubtasks(timeInterval.taskWithSubtasksId!);
        timeInterval.color = taskWithSubtasks.color;
        timeInterval.title = taskWithSubtasks.title;
        await _databaseManager.updateTimeInterval(timeInterval);
      }
    }
    setState(() => _timeIntervals = timeIntervals);
  }

  @override
  Widget build(BuildContext context) {
    List<CalendarTimeIntervalData> _calendarTimeIntervals =
        _timeIntervals.toCalendarData();
    ;
    final width = MediaQuery.of(context).size.width;
    return CalendarControllerProvider(
      controller: TimeIntervalController()..addAll(_calendarTimeIntervals),
      child: Expanded(
        child: MonthViewWidget(
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
          //key: widget.state,
          width: width,
        ),
      ),
    );
  }
}

class MonthViewWidget extends StatelessWidget {
  final GlobalKey<MonthViewState>? state;
  final double? width;

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

  const MonthViewWidget({
    super.key,
    this.state,
    this.width,

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
  });

  @override
  Widget build(BuildContext context) {
    return MonthView(
      // handleBrightnessChange: handleBrightnessChange,
      // handleMaterialVersionChange: handleMaterialVersionChange,
      // handleUsingBottomBarChange: handleUsingBottomBarChange,
      // useBottomBar: useBottomBar,
      // handleColorSelect: handleColorSelect,
      // colorSelected: colorSelected,
      // colorSelectionMethod: colorSelectionMethod,
      // handleImageSelect: handleImageSelect,
      // imageSelected: imageSelected,
      // handleLanguageSelect: handleLanguageSelect,
      // languageSelected: languageSelected,
      // showBrightnessButtonInAppBar:
      // showBrightnessButtonInAppBar,
      // showColorImageButtonInAppBar:
      // showColorImageButtonInAppBar,
      // showColorSeedButtonInAppBar: showColorSeedButtonInAppBar,
      // showLanguagesButtonInAppBar: showLanguagesButtonInAppBar,
      // showMaterialDesignButtonInAppBar:
      // showMaterialDesignButtonInAppBar,
      key: state,
      width: width,
      onEventTap: (event, date) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddOrEditTimeIntervalPage(
              timeInterval: event.event as TimeInterval,
            ),
            fullscreenDialog: false,
          ),
        );
      },
    );
  }
}
