import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// void main() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Interval',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TimeIntervalForm(),
    );
  }
}

class TimeInterval {
  final String id;
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isStartDateUndefined;
  bool isEndDateUndefined;
  bool isStartTimeUndefined;
  bool isEndTimeUndefined;
  int? startTimestamp;
  int? endTimestamp;

  TimeInterval({
    String? id,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isStartDateUndefined = false,
    this.isEndDateUndefined = false,
    this.isStartTimeUndefined = false,
    this.isEndTimeUndefined = false,
  })  : assert(
          id == null || id.isNotEmpty,
          'id can not be null and should be empty',
        ),
        id = id ?? const Uuid().v4() {
    if (isStartDateUndefined) {
      isStartTimeUndefined = true;
      startTimestamp = null;
    } else if (isStartTimeUndefined) {
      startTimestamp =
          DateTime(startDate!.year, startDate!.month, startDate!.day)
              .millisecondsSinceEpoch;
    } else {
      startTimestamp = DateTime(startDate!.year, startDate!.month,
              startDate!.day, startTime!.hour, startTime!.minute)
          .millisecondsSinceEpoch;
    }

    if (isEndDateUndefined) {
      isEndTimeUndefined = true;
      endTimestamp = null;
    } else if (isEndTimeUndefined) {
      endTimestamp =
          DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59)
              .millisecondsSinceEpoch;
    } else {
      endTimestamp = DateTime(endDate!.year, endDate!.month, endDate!.day,
              endTime!.hour, endTime!.minute)
          .millisecondsSinceEpoch;
    }

    if (startTimestamp != null &&
        endTimestamp != null &&
        startTimestamp! > endTimestamp!) {
      throw ArgumentError('End timestamp must be after start timestamp');
    }
  }
}

class TimeIntervalForm extends StatefulWidget {
  @override
  _TimeIntervalFormState createState() => _TimeIntervalFormState();
}

class _TimeIntervalFormState extends State<TimeIntervalForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Time Interval'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            CheckboxListTile(
              title: Text('Start Date Undefined'),
              value: _isStartDateUndefined,
              onChanged: (value) {
                setState(() {
                  _isStartDateUndefined = value ?? false;
                });
              },
            ),
            if (!_isStartDateUndefined)
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(_startDate != null
                    ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day}'
                    : 'Select Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
            CheckboxListTile(
              title: Text('Start Time Undefined'),
              value: _isStartTimeUndefined,
              onChanged: (value) {
                setState(() {
                  _isStartTimeUndefined = value ?? false;
                });
              },
            ),
            if (!_isStartTimeUndefined)
              ListTile(
                title: Text('Start Time'),
                subtitle: Text(_startTime != null
                    ? '${_startTime!.hour}:${_startTime!.minute}'
                    : 'Select Time'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = time;
                    });
                  }
                },
              ),
            CheckboxListTile(
              title: Text('End Date Undefined'),
              value: _isEndDateUndefined,
              onChanged: (value) {
                setState(() {
                  _isEndDateUndefined = value ?? false;
                });
              },
            ),
            if (!_isEndDateUndefined)
              ListTile(
                title: Text('End Date'),
                subtitle: Text(_endDate != null
                    ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                    : 'Select Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
              ),
            CheckboxListTile(
              title: Text('End Time Undefined'),
              value: _isEndTimeUndefined,
              onChanged: (value) {
                setState(() {
                  _isEndTimeUndefined = value ?? false;
                });
              },
            ),
            if (!_isEndTimeUndefined)
              ListTile(
                title: Text('End Time'),
                subtitle: Text(_endTime != null
                    ? '${_endTime!.hour}:${_endTime!.minute}'
                    : 'Select Time'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _endTime = time;
                    });
                  }
                },
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final timeInterval = TimeInterval(
                    startDate: _startDate,
                    endDate: _endDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    isStartDateUndefined:
                        _isStartDateUndefined,
                    isEndDateUndefined:
                        _isEndDateUndefined,
                    isStartTimeUndefined:
                        _isStartTimeUndefined,
                    isEndTimeUndefined:
                        _isEndTimeUndefined,
                  );
                  // TODO: Save time interval to database or send to server
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder:
                              (context) =>
                                  TimelineScreen(timeInterval:
                                      timeInterval)));
                }
              },
              child:
                  Text('Save Time Interval', style:
                  TextStyle(color:
                  Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineScreen extends StatelessWidget {
  final TimeInterval timeInterval;

  const TimelineScreen({Key? key, required this.timeInterval})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title:
          Text('Timeline')),
      body:
          CustomScrollView(slivers:
          [
        SliverToBoxAdapter(child:
        SizedBox(height:
        16)),
        SliverList(
          delegate:
              SliverChildBuilderDelegate((context, index) {
            final hour = index;
            return Column(children:
            [
              Row(children:
              [
                SizedBox(width:
                8),
                Container(width:
                32, child:
                Text('$hour')),
                Expanded(child:
                Divider()),
              ]),
              if (hour == timeInterval.startTime?.hour)
                Row(children:
                [
                  SizedBox(width:
                  8),
                  Container(width:
                  32),
                  Expanded(child:
                  Container(height:
                  48, color:
                  Colors.blue)),
                ]),
            ]);
          }, childCount:
          24),
        ),
      ]),
    );
  }
}
