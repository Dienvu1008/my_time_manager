import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_calendar/mapping.dart';
import 'package:calendar_widgets/calendar_widgets.dart';
import '../screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import '../utils/constants.dart';
import 'day_view.dart';

class TasksDayView extends StatefulWidget {
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



  const TasksDayView({
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
  _TasksDayViewState createState() => _TasksDayViewState();
}

class _TasksDayViewState extends State<TasksDayView> {
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
      //await timeInterval.init();
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
        child: DayViewWidget(
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

class DayViewWidget extends StatelessWidget {
  final DatabaseManager _databaseManager = DatabaseManager();
  final GlobalKey<DayViewState>? state;
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


  DayViewWidget({
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
    return DayView(
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
      startDuration: Duration(hours: 8),
      showHalfHours: true,
      heightPerMinute: 3,
      leftSideHourIndicatorBuilder: _leftSideHourIndicatorBuilder,
      hourIndicatorSettings: HourIndicatorSettings(
        color: Theme.of(context).dividerColor,
      ),
      onEventTap: (events, date) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddOrEditTimeIntervalPage(
              timeInterval: events.first.event as TimeInterval,
            ),
            fullscreenDialog: false,
          ),
        );
      },
      // halfHourIndicatorSettings: HourIndicatorSettings(
      //   color: Theme.of(context).dividerColor,
      //   lineStyle: LineStyle.dashed,
      // ),

    );
  }

  Widget _dayTitleBuilder(DateTime date){
    return AppBar(
        title: DayPageHeader(date: date)
    );
  }

  Widget _leftSideHourIndicatorBuilder(DateTime date) {
    //if (date.minute != 0) {
    final timeString = date.toString().substring(11, 16);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: -8,
          right: 8,
          child: Text(
            timeString,
            //"${date.hour}:${date.minute}",
            textAlign: TextAlign.right,
            style: TextStyle(
              //color: Colors.black.withAlpha(50),
              //fontStyle: FontStyle.italic,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  //   final hour = ((date.hour - 1) % 12) + 1;
  //   return Stack(
  //     clipBehavior: Clip.none,
  //     children: [
  //       Positioned.fill(
  //         top: -8,
  //         right: 8,
  //         child: Text(
  //           "$hour ${date.hour ~/ 12 == 0 ? "am" : "pm"}",
  //           textAlign: TextAlign.right,
  //           style: TextStyle(
  //             color: Colors.black.withAlpha(50),
  //             fontStyle: FontStyle.italic,
  //             fontSize: 8,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
