import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/models.dart';

// void main() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Interval',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TimeIntervalPage(),
    );
  }
}

class TimeIntervalPage extends StatefulWidget {
  const TimeIntervalPage({super.key});

  @override
  _TimeIntervalPageState createState() => _TimeIntervalPageState();
}

class _TimeIntervalPageState extends State<TimeIntervalPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  bool _isStartDateUndefined = false;
  bool _isEndDateUndefined = false;
  bool _isStartTimeUndefined = false;
  bool _isEndTimeUndefined = false;
  List<TimeInterval> _timeIntervals = [];
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Interval'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 10),
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      onTap: () async {
                        if (!_isStartDateUndefined) {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            _startDateController.text =
                                DateFormat('yyyy-MM-dd').format(date);
                          }
                        }
                      },
                      validator: (value) {
                        if (!_isStartDateUndefined && value!.isEmpty) {
                          return 'Please enter a start date';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Start date',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      enabled: !_isStartDateUndefined,
                    ),
                  ),
                  Checkbox(
                    value: _isStartDateUndefined,
                    onChanged: (value) {
                      setState(() {
                        _isStartDateUndefined = value!;
                        if (_isStartDateUndefined) {
                          _startDateController.text = 'Undefined';
                          _isStartTimeUndefined = true;
                          _startTimeController.text = 'Undefined';
                        } else {
                          _startDateController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      onTap: () async {
                        if (!_isStartTimeUndefined) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: TimeOfDay.now().hour, minute: 0),
                          );
                          if (time != null) {
                            _startTimeController.text =
                                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        }
                      },
                      validator: (value) {
                        if (!_isStartTimeUndefined && value!.isEmpty) {
                          return 'Please enter a start time';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Start time',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      enabled: !_isStartTimeUndefined,
                    ),
                  ),
                  Checkbox(
                    value: _isStartTimeUndefined,
                    onChanged: _isStartDateUndefined
                        ? null
                        : (value) {
                            setState(() {
                              _isStartTimeUndefined = value!;
                              if (_isStartTimeUndefined) {
                                _startTimeController.text = 'Undefined';
                              } else {
                                _startTimeController.clear();
                              }
                            });
                          },
                  ),
                ],
              ),
            ),

            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      enabled: !_isEndDateUndefined,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          _endDateController.text =
                              DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an end date';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'End date',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _isEndDateUndefined,
                    onChanged: (value) {
                      setState(() {
                        _isEndDateUndefined = value!;
                        if (_isEndDateUndefined) {
                          _endDateController.text = 'Undefined';
                          _isEndTimeUndefined = true;
                          _endTimeController.text = 'Undefined';
                        } else {
                          _endDateController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      enabled: !_isEndTimeUndefined,
                      onTap: (() async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: TimeOfDay.now().hour, minute: 0),
                        );
                        if (time != null) {
                          _endTimeController.text =
                              '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
                        }
                      }),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an end time';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'End time',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  Checkbox(
                    value: _isEndTimeUndefined,
                    onChanged: _isEndDateUndefined
                        ? null
                        : (value) {
                            setState(() {
                              _isEndTimeUndefined = value!;
                              if (_isEndTimeUndefined) {
                                _endTimeController.text = 'Undefined';
                              } else {
                                _endTimeController.clear();
                              }
                            });
                          },
                  ),
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_isStartDateUndefined &&
                      _isEndDateUndefined &&
                      _isStartTimeUndefined &&
                      _isEndTimeUndefined) {
                    showDialog(
                      context: context,
                      builder: (context) => const AlertDialog(
                        content: Text('Please enter at least one date'),
                      ),
                    );
                  } else {
                    final startDate = !_isStartDateUndefined
                        ? DateFormat('yyyy-MM-dd')
                            .parse(_startDateController.text)
                        : null;
                    final endDate = !_isEndDateUndefined
                        ? DateFormat('yyyy-MM-dd')
                            .parse(_endDateController.text)
                        : null;
                    final startTime = !_isStartTimeUndefined
                        ? TimeOfDay.fromDateTime(DateFormat('HH:mm')
                            .parse(_startTimeController.text))
                        : null;
                    final endTime = !_isEndTimeUndefined
                        ? TimeOfDay.fromDateTime(
                            DateFormat('HH:mm').parse(_endTimeController.text))
                        : null;
                    final timeInterval = TimeInterval(
                      startDate: startDate,
                      endDate: endDate,
                      startTime: startTime,
                      endTime: endTime,
                      isStartDateUndefined:
                          startDate == null || _isStartDateUndefined,
                      isEndDateUndefined:
                          endDate == null || _isEndDateUndefined,
                      isStartTimeUndefined:
                          startTime == null || _isStartTimeUndefined,
                      isEndTimeUndefined:
                          endTime == null || _isEndTimeUndefined,
                    );
                    setState(() {
                      _timeIntervals.add(timeInterval);
                      _startDateController.clear();
                      _startTimeController.clear();
                      _endDateController.clear();
                      _endTimeController.clear();
                    });
                  }
                }
              },
              child: Text('Submit'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _timeIntervals.sort((a, b) =>
                      (_isAscending ? 1 : -1) *
                      ((a.startTimestamp ?? a.endTimestamp)! -
                                  (b.startTimestamp ?? b.endTimestamp)! <
                              0
                          ? -1
                          : 1));
                  _isAscending = !_isAscending;
                });
              },
              child: Text(_isAscending ? 'Sort Descending' : 'Sort Ascending'),
            ),

            // ..._timeIntervals.map(
            //   (timeInterval) => ListTile(
            //     title: Text(
            //         '${timeInterval.startDate != null
            //         ? DateFormat('yyyy-MM-dd').format(timeInterval.startDate!)
            //         : 'N/A'} ${timeInterval.startTime != null
            //         ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}'
            //         : 'N/A'} - ${timeInterval.endDate != null
            //         ? DateFormat('yyyy-MM-dd').format(timeInterval.endDate!)
            //         : 'N/A'} ${timeInterval.endTime != null ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}'
            //         : 'N/A'}'),
            //   ),
            // ),
            // ConstrainedBox(
            //   constraints: BoxConstraints(maxHeight: 300),
            //   child: IntrinsicHeight(
            //     child: SingleChildScrollView(
            //       child: Column(
            //         children: _timeIntervals
            //             .map(
            //               (timeInterval) => ListTile(
            //                 title: Text(
            //                   '${timeInterval.startDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.startDate!) : 'N/A'} ${timeInterval.startTime != null ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}' : 'N/A'} - ${timeInterval.endDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.endDate!) : 'N/A'} ${timeInterval.endTime != null ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}' : 'N/A'}',
            //                 ),
            //               ),
            //             )
            //             .toList(),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(
              height: 20,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: IntrinsicHeight(
                    child: SingleChildScrollView(
                      child: Column(
                        children:
                            // _timeIntervals
                            //     .map(
                            //       (timeInterval) => ListTile(
                            //         title: Text(
                            //           '${timeInterval.startDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.startDate!) : 'N/A'} ${timeInterval.startTime != null ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}' : 'N/A'} - ${timeInterval.endDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.endDate!) : 'N/A'} ${timeInterval.endTime != null ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}' : 'N/A'}',
                            //         ),
                            //       ),
                            //     )
                            //     .toList(),

                            // _timeIntervals
                            //     .map(
                            //       (timeInterval) => ListTile(
                            //         title: Text(
                            //           timeInterval.startDate != null &&
                            //                   timeInterval.endDate != null &&
                            //                   timeInterval.startDate!.year ==
                            //                       timeInterval.endDate!.year &&
                            //                   timeInterval.startDate!.month ==
                            //                       timeInterval.endDate!.month &&
                            //                   timeInterval.startDate!.day ==
                            //                       timeInterval.endDate!.day
                            //               ? '${DateFormat('yyyy-MM-dd').format(timeInterval.startDate!)} ${timeInterval.startTime != null ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}' : ''}-${timeInterval.endTime != null ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}' : ''}'
                            //               : '${timeInterval.startDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.startDate!) : 'N/A'} ${timeInterval.startTime != null ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}' : ''} - ${timeInterval.endDate != null ? DateFormat('yyyy-MM-dd').format(timeInterval.endDate!) : 'N/A'} ${timeInterval.endTime != null ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}' : ''}',
                            //         ),
                            //       ),
                            //     )
                            //     .toList(),

                            // _timeIntervals
                            //     .map(
                            //       (timeInterval) => ListTile(
                            //         title: Column(
                            //           children: [
                            //             Row(
                            //               children: [
                            //                 Expanded(
                            //                   child: TextFormField(
                            //                     initialValue: timeInterval
                            //                                 .startDate !=
                            //                             null
                            //                         ? DateFormat('yyyy-MM-dd')
                            //                             .format(timeInterval
                            //                                 .startDate!)
                            //                         : 'N/A',
                            //                     decoration:
                            //                         const InputDecoration(
                            //                       border: OutlineInputBorder(),
                            //                       labelText: 'Start date',
                            //                       floatingLabelBehavior:
                            //                           FloatingLabelBehavior
                            //                               .always,
                            //                     ),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: 8),
                            //                 Expanded(
                            //                   child: TextFormField(
                            //                     initialValue: timeInterval
                            //                                 .startTime !=
                            //                             null
                            //                         ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}'
                            //                         : 'N/A',
                            //                     decoration:
                            //                         const InputDecoration(
                            //                       border: OutlineInputBorder(),
                            //                       labelText: 'Start time',
                            //                       floatingLabelBehavior:
                            //                           FloatingLabelBehavior
                            //                               .always,
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //             const SizedBox(height: 8),
                            //             Row(
                            //               children: [
                            //                 Expanded(
                            //                   child: TextFormField(
                            //                     initialValue: timeInterval
                            //                                 .endDate !=
                            //                             null
                            //                         ? DateFormat('yyyy-MM-dd')
                            //                             .format(timeInterval
                            //                                 .endDate!)
                            //                         : 'N/A',
                            //                     decoration:
                            //                         const InputDecoration(
                            //                       border: OutlineInputBorder(),
                            //                       labelText: 'End date',
                            //                       floatingLabelBehavior:
                            //                           FloatingLabelBehavior
                            //                               .always,
                            //                     ),
                            //                   ),
                            //                 ),
                            //                 const SizedBox(width: 8),
                            //                 Expanded(
                            //                   child: TextFormField(
                            //                     initialValue: timeInterval
                            //                                 .endTime !=
                            //                             null
                            //                         ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}'
                            //                         : 'N/A',
                            //                     decoration:
                            //                         const InputDecoration(
                            //                       border: OutlineInputBorder(),
                            //                       labelText: 'End time',
                            //                       floatingLabelBehavior:
                            //                           FloatingLabelBehavior
                            //                               .always,
                            //                     ),
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     )
                            //     .toList(),

                            _timeIntervals
                                .map(
                                  (timeInterval) => ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: timeInterval
                                                        .startDate !=
                                                    null
                                                ? DateFormat('yyyy-MM-dd')
                                                    .format(
                                                        timeInterval.startDate!)
                                                : 'N/A',
                                            enabled: false,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: 'Start date',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: timeInterval
                                                        .startTime !=
                                                    null
                                                ? '${timeInterval.startTime!.hour.toString().padLeft(2, '0')}:${timeInterval.startTime!.minute.toString().padLeft(2, '0')}'
                                                : 'N/A',
                                            enabled: false,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: 'Start time',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: timeInterval.startDate !=
                                                        null &&
                                                    timeInterval.endDate !=
                                                        null &&
                                                    DateFormat('yyyy-MM-dd')
                                                            .format(timeInterval
                                                                .startDate!) ==
                                                        DateFormat('yyyy-MM-dd')
                                                            .format(timeInterval
                                                                .endDate!)
                                                ? ''
                                                : timeInterval.endDate != null
                                                    ? DateFormat('yyyy-MM-dd')
                                                        .format(timeInterval
                                                            .endDate!)
                                                    : 'N/A',
                                            enabled: false,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: timeInterval
                                                              .startDate !=
                                                          null &&
                                                      timeInterval.endDate !=
                                                          null &&
                                                      DateFormat('yyyy-MM-dd')
                                                              .format(timeInterval
                                                                  .startDate!) ==
                                                          DateFormat(
                                                                  'yyyy-MM-dd')
                                                              .format(
                                                                  timeInterval
                                                                      .endDate!)
                                                  ? ''
                                                  : 'End date',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: timeInterval
                                                        .endTime !=
                                                    null
                                                ? '${timeInterval.endTime!.hour.toString().padLeft(2, '0')}:${timeInterval.endTime!.minute.toString().padLeft(2, '0')}'
                                                : 'N/A',
                                            enabled: false,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: 'End time',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.always,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            // Handle selected option
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'Mark completed',
                                              child: Text('Mark completed'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'Mark incompleted',
                                              child: Text('Mark incompleted'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'Edit time interval',
                                              child: Text('Edit time interval'),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'Delete time interval',
                                              child:
                                                  Text('Delete time interval'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
