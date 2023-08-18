import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Interval',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TimetableScreen(),
    );
  }
}
class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<List<bool>> _checked =
      List.generate(7, (_) => List.generate(24, (_) => false));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable'),
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(width: 40),
                for (var i = 0; i < 7; i++)
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        for (var i = 0; i < 24; i++)
                          SizedBox(
                            height: 60,
                            child: Center(child: Text(i.toString())),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        children: [
                          for (var i = 0; i < 24; i++)
                            Row(
                              children: [
                                for (var j = 0; j < 7; j++)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _checked[j][i] = !_checked[j][i];
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration:
                                          BoxDecoration(border:
                                          Border.all(color:
                                          Colors.grey)),
                                      child:
                                          _checked[j][i]
                                              ? Icon(Icons.check)
                                              : null,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
