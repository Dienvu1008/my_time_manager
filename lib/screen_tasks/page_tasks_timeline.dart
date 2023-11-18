import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/data/models/model_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/page_add_edit_time_interval.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/card_time_interval.dart';

import '../app/app_localizations.dart';
import '../data/database/database_manager.dart';

class TasksTimelinePage extends StatefulWidget {
  const TasksTimelinePage({
    Key? key,
  }) : super(key: key);

  @override
  _TasksTimelinePageState createState() => _TasksTimelinePageState();
}

class _TasksTimelinePageState extends State<TasksTimelinePage> {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final timeIntervals = await _databaseManager.timeIntervals();

    
  timeIntervals.sort((a, b) {
    final aTimestamp = a.startTimestamp ?? a.endTimestamp;
    final bTimestamp = b.startTimestamp ?? b.endTimestamp;

    if (aTimestamp != null && bTimestamp != null) {
      return aTimestamp.compareTo(bTimestamp);
    } else if (aTimestamp != null) {
      return -1;
    } else if (bTimestamp != null) {
      return 1;
    } else {
      return 0;
    }
  }); 
  
    setState(() => _timeIntervals = timeIntervals);
  }

  Future<void> _deleteTimeInterval(TimeInterval timeInterval) async {
    await _databaseManager.deleteTimeInterval(timeInterval.id);
    setState(() => _timeIntervals.remove(timeInterval));
  }

  Future<void> _onTimeIntervalToggleCompleted(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(isCompleted: !timeInterval.isCompleted);
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
    await _databaseManager.timeInterval(timeInterval.id);
    final index =
    _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
    setState(() {
      _timeIntervals[index] = updatedTimeInterval;
    });
    }
  }

  Future<void> _onSubtasksChanged(TimeInterval timeInterval) async {
    TimeInterval _timeInterval = timeInterval.copyWith(subtasks: timeInterval.subtasks,);
    await _databaseManager.updateTimeInterval(_timeInterval);
    final updatedTimeInterval =
    await _databaseManager.timeInterval(timeInterval.id);
    final index =
    _timeIntervals.indexWhere((item) => item.id == updatedTimeInterval.id);
    if (index != -1) {
    setState(() {
      _timeIntervals[index] = updatedTimeInterval;
    });
    }
  }

  Future<void> _onHasBeenDoneUpdate(TimeInterval timeInterval) async {
    final TextEditingController _hasBeenDoneController = TextEditingController(
      text: timeInterval.howMuchHasBeenDone.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.hasBeenDone),
        content: TextFormField(
          controller: _hasBeenDoneController,
          //decoration: InputDecoration(labelText: 'has been done'),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              TimeInterval _timeInterval = timeInterval.copyWith(howMuchHasBeenDone: double.parse(_hasBeenDoneController.text));
              await _databaseManager.updateTimeInterval(_timeInterval);
              final updatedTimeInterval =
                  await _databaseManager.timeInterval(timeInterval.id);
              final index = _timeIntervals
                  .indexWhere((item) => item.id == updatedTimeInterval.id);
              if (index != -1) {
                setState(() {
                  _timeIntervals[index] = updatedTimeInterval;
                });
              }
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
          child: TimeIntervalList(
        timeIntervals: _timeIntervals,
        onTimeIntervalDelete: _deleteTimeInterval,
        onSubtasksChanged: _onSubtasksChanged,
        onTimeIntervalEdit: (TimeInterval timeInterval) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOrEditTimeIntervalPage(
                timeInterval: timeInterval,
              ),
              fullscreenDialog: false,
            ),
          );
          final updatedTimeInterval = await _databaseManager
              .timeInterval(timeInterval.id);
          final index = _timeIntervals.indexWhere(
              (item) => item.id == updatedTimeInterval.id);
          if (index != -1) {
          setState(() {
            _timeIntervals[index] = updatedTimeInterval;
          });
          }
        },
        onTimeIntervalToggleComplete: (TimeInterval timeInterval) {_onTimeIntervalToggleCompleted(timeInterval);}, 
        onHasBeenDoneUpdate: _onHasBeenDoneUpdate,
      )),
    );
  }
}

class TimeIntervalList extends StatelessWidget {
  final List<TimeInterval> timeIntervals;
  final void Function(TimeInterval) onTimeIntervalDelete;
  final void Function(TimeInterval) onTimeIntervalEdit;
  final void Function(TimeInterval) onTimeIntervalToggleComplete;
  final void Function(TimeInterval) onSubtasksChanged;
  final void Function(TimeInterval) onHasBeenDoneUpdate;

  const TimeIntervalList(
      {Key? key,
      required this.timeIntervals,
      required this.onTimeIntervalDelete,
      required this.onTimeIntervalEdit,
      required this.onTimeIntervalToggleComplete,
      required this.onSubtasksChanged, 
      required this.onHasBeenDoneUpdate})
      : super(key: key);

  // static Color contrastColor(Color color) {
  //   final brightness = ThemeData.estimateBrightnessForColor(color);
  //   switch (brightness) {
  //     case Brightness.dark:
  //       return Colors.white;
  //     case Brightness.light:
  //       return Colors.black;
  //   }
  // }
  Color contrastColor(Color backgroundColor) {
    final double relativeLuminance = backgroundColor.computeLuminance();
    return (relativeLuminance > 0.179) ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ListView.builder(
      //physics: const NeverScrollableScrollPhysics(),
      itemCount: timeIntervals.length,
      itemBuilder: (context, index) {
        final timeInterval = timeIntervals[index];
        final timeIntervalColor = timeIntervals[index].color;
        final myColorScheme = Theme.of(context).brightness == Brightness.dark
            ? ColorScheme.dark(primary: timeIntervalColor)
            : ColorScheme.light(primary: timeIntervalColor);
        final backgroundColor = myColorScheme.primaryContainer;
        final labelColor = contrastColor(backgroundColor);
        final textTheme =
            Theme.of(context).textTheme.apply(bodyColor: labelColor);
        final String formattedStartDate = timeInterval.startDate != null
            ? DateFormat.yMMMd().format(timeInterval.startDate!)
            : '--/--/----';

        return TimeIntervalCard(
          onSubtasksChanged: onSubtasksChanged,
          onTimeIntervalDelete: onTimeIntervalDelete,
          onTimeIntervalEdit: onTimeIntervalEdit,
          onTimeIntervalToggleComplete: onTimeIntervalToggleComplete,
          timeInterval: timeInterval, 
          onHasBeenDoneUpdate: onHasBeenDoneUpdate,
        );
      },
    );
  }
}

