import 'package:flutter/material.dart';
import 'package:my_time_manager/data/database/database_manager.dart';

import '../data/models/model_time_interval.dart';
import 'data_controller.dart';

class DataControllerProvider extends InheritedWidget {
  final NewDataController controller;

  const DataControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  static DataControllerProvider of<T extends Object?>(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<DataControllerProvider>();
    return result!;
  }

  @override
  bool updateShouldNotify(DataControllerProvider oldWidget) =>
      oldWidget.controller != controller;
}

class NewDataController extends ChangeNotifier {
  final DatabaseManager _databaseManager = DatabaseManager();
  List<TimeInterval> _timeIntervals = [];

  NewDataController() {
    getAllTimeIntervals();

  }

  List<TimeInterval> get timeIntervals => _timeIntervals;

  Future<List<TimeInterval>> getAllTimeIntervals() async {
    final List<TimeInterval> timeIntervals =
        await _databaseManager.timeIntervals();
    _timeIntervals = timeIntervals;
    notifyListeners();
    return _timeIntervals;

  }

  void _deleteTimeInterval(TimeInterval timeInterval) {
    _databaseManager.deleteTimeInterval(timeInterval.id);
    _timeIntervals.remove(timeInterval);
    notifyListeners();
  }
}

class MyInheritedWidget extends InheritedWidget {
  final NewDataController dataController = NewDataController();

  MyInheritedWidget({required Widget child}) : super(child: child);

  static MyInheritedWidget of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>()!;
  }

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) {
    return dataController != oldWidget.dataController;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyInheritedWidget(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Bạn đã nhấn nút này nhiều lần:'),
                //Counter(),
              ],
            ),
          ),
          //floatingActionButton: IncrementButton(),
        ),
      ),
    );
  }
}

// class Counter extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final myInheritedWidget = MyInheritedWidget.of(context);
//     return Text(
//       '${myInheritedWidget.dataController.value}',
//       style: Theme.of(context).textTheme.headline4,
//     );
//   }
// }
//
// class IncrementButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final myInheritedWidget = MyInheritedWidget.of(context);
//     return FloatingActionButton(
//       onPressed: myInheritedWidget.dataController.increment,
//       tooltip: 'Increment',
//       child: Icon(Icons.add),
//     );
//   }
// }
