import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//Các yếu tố chính của một TimeInterval là ngày bắt đầu, giờ bắt đầu, ngày kết thúc, giờ kết thúc.
//Một TimeInterval cần có ít nhất một ngày bắt đầu hoặc ngày kết thúc được xác định.
//Nếu TimeInterval có cả hai ngày bắt đầu và ngày kết thúc được xác định thì ngày bắt đầu không được phép xảy ra sau ngày kết thúc.

//Nếu TimeInterval có ngày bắt đầu và ngày kết thúc là cùng một ngày, 
//giờ bắt đầu và giờ kết thúc được xác định thì giờ bắt đầu không được phép xảy ra sau giờ kết thúc.

//Nếu ngày bắt đầu không được xác định rõ thì thời gian bắt đầu cũng sẽ không được xác định.
//Nếu ngày kết thúc không được xác định rõ thì thời gian kết thúc cũng sẽ không được xác định.

class SetTimeIntervalBlockListTile extends StatefulWidget {
  final TextEditingController startDateController;
  bool isStartDateUndefined;
  final TextEditingController endDateController;
  bool isEndDateUndefined;
  final TextEditingController startTimeController;
  bool isStartTimeUndefined;
  final TextEditingController endTimeController;
  bool isEndTimeUndefined;
  final String languageCode;
  final formKey;

  SetTimeIntervalBlockListTile(
      {required this.startDateController,
      required this.isStartDateUndefined,
      required this.endDateController,
      required this.isEndDateUndefined,
      required this.startTimeController,
      required this.endTimeController,
      required this.isStartTimeUndefined,
      required this.isEndTimeUndefined,
      required this.languageCode,
      required this.formKey});

  @override
  _SetTimeIntervalBlockListTileState createState() =>
      _SetTimeIntervalBlockListTileState();
}

class _SetTimeIntervalBlockListTileState
    extends State<SetTimeIntervalBlockListTile> {
  @override
  Widget build(BuildContext context) {

    return Form(
        key: widget.formKey,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.none,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    controller: widget.startDateController,
                    readOnly: widget.isStartDateUndefined,
                    onTap: () async {
                      if (!widget.isStartDateUndefined) {
                        //widget.isStartDateUndefined ==false;
                        final startDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (startDate != null) {
                          widget.startDateController.text = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .format(startDate);
                        }

                        if (!widget.isEndDateUndefined) {
                          try {
                            DateTime endDate = DateFormat(
                                    'EEE, dd MMM, yyyy', widget.languageCode)
                                .parse(widget.endDateController.text);
                            DateTime newStartDate = DateFormat(
                                    'EEE, dd MMM, yyyy', widget.languageCode)
                                .parse(widget.startDateController.text);

                            if (endDate.isBefore(newStartDate)) {
                              widget.endDateController.text =
                                  widget.startDateController.text;
                            }
                          } catch (_) {
                            // Do nothing
                          }
                        }
                      }
                    },
                    validator: (value) {
                      if (!widget.isStartDateUndefined && value!.isEmpty) {
                        return 'Please enter a start date';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: Checkbox(
                        value: widget.isStartDateUndefined,
                        onChanged: (value) {
                          setState(() {
                            widget.isStartDateUndefined = value!;
                            if (widget.isStartDateUndefined) {
                              widget.startDateController.text = 'undefined';
                              widget.isStartTimeUndefined = true;
                              widget.startTimeController.text = 'undefined';
                            } else {
                              widget.startDateController.clear();
                            }
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      labelText: 'Start date',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.none,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    controller: widget.endDateController,
                    readOnly: widget.isEndDateUndefined,
                    onTap: () async {
                      if (!widget.isEndDateUndefined) {
                        final endDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (endDate != null) {
                          widget.endDateController.text = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .format(endDate);
                        }

                        if (!widget.isStartDateUndefined) {
                          try {
                            DateTime startDate = DateFormat(
                                    'EEE, dd MMM, yyyy', widget.languageCode)
                                .parse(widget.startDateController.text);
                            DateTime newEndDate = DateFormat(
                                    'EEE, dd MMM, yyyy', widget.languageCode)
                                .parse(widget.endDateController.text);

                            if (startDate.isAfter(newEndDate)) {
                              widget.startDateController.text =
                                  widget.endDateController.text;
                            }
                          } catch (_) {
                            // Do nothing
                          }
                        }
                      }
                    },
                    validator: (value) {
                      if (!widget.isEndDateUndefined && value!.isEmpty) {
                        return 'Please enter an end date';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: Checkbox(
                        value: widget.isEndDateUndefined,
                        onChanged: (value) {
                          setState(() {
                            widget.isEndDateUndefined = value!;
                            if (widget.isEndDateUndefined) {
                              widget.endDateController.text = 'undefined';
                              widget.isEndTimeUndefined = true;
                              widget.endTimeController.text = 'undefined';
                            } else {
                              widget.endDateController.clear();
                            }
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      labelText: 'End date',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    keyboardType: TextInputType.none,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                    controller: widget.startTimeController,
                    //readOnly: widget.isStartTimeUndefined,
                    // enabled: !widget.isStartDateUndefined &&
                    //     widget.startDateController.text.isNotEmpty,
                    maxLines: 1,
                    onTap: () async {
                      if (!widget.isStartDateUndefined &&
                          !widget.isStartTimeUndefined) {
                        final startTime = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: TimeOfDay.now().hour, minute: 0),
                        );
                        if (startTime != null) {
                          widget.startTimeController.text =
                              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                        }

                        try {
                          DateTime startDate = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .parse(widget.startDateController.text);
                          DateTime endDate = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .parse(widget.endDateController.text);
                          TimeOfDay endTime = TimeOfDay(
                              hour: int.parse(
                                  widget.endTimeController.text.split(':')[0]),
                              minute: int.parse(
                                  widget.endTimeController.text.split(':')[1]));

                          if (startDate.day == endDate.day &&
                              endTime.hour < startTime!.hour) {
                            widget.endTimeController.text =
                                widget.startTimeController.text;
                          } else if (startDate.day == endDate.day &&
                              endTime.hour == startTime!.hour &&
                              endTime.minute < startTime.minute) {
                            widget.endTimeController.text =
                                widget.startTimeController.text;
                          }
                        } catch (_) {
                          // Do nothing
                        }
                      }
                    },
                    validator: (value) {
                      if (!widget.isStartTimeUndefined && value!.isEmpty) {
                        return 'Please enter a start time';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: Checkbox(
                        value: widget.isStartTimeUndefined,
                        onChanged: widget.isStartDateUndefined
                            ? null
                            //? (value) {widget.isStartTimeUndefined = false;}
                            : (value) {
                                setState(() {
                                  widget.isStartTimeUndefined = value!;
                                  if (widget.isStartTimeUndefined) {
                                    widget.startTimeController.text =
                                        'undefined';
                                  } else {
                                    widget.startTimeController.clear();
                                  }
                                });
                              },
                      ),
                      border: const OutlineInputBorder(),
                      labelText: 'Start time',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    keyboardType: TextInputType.none,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    controller: widget.endTimeController,
                    //readOnly: widget.isEndTimeUndefined,
                    // enabled: !widget.isEndDateUndefined &&
                    //     widget.endDateController.text.isNotEmpty,
                    onTap: (() async {
                      if (!widget.isEndDateUndefined &&
                          !widget.isEndTimeUndefined) {
                        final endTime = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: TimeOfDay.now().hour, minute: 0),
                        );
                        if (endTime != null) {
                          widget.endTimeController.text =
                              '${endTime.hour.toString().padLeft(2, "0")}:${endTime.minute.toString().padLeft(2, "0")}';
                        }

                        try {
                          DateTime startDate = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .parse(widget.startDateController.text);
                          DateTime endDate = DateFormat(
                                  'EEE, dd MMM, yyyy', widget.languageCode)
                              .parse(widget.endDateController.text);
                          TimeOfDay startTime = TimeOfDay(
                              hour: int.parse(widget.startTimeController.text
                                  .split(':')[0]),
                              minute: int.parse(widget.startTimeController.text
                                  .split(':')[1]));

                          if (startDate.day == endDate.day &&
                              startTime.hour > endTime!.hour) {
                            widget.startTimeController.text =
                                widget.endTimeController.text;
                          } else if (startDate.day == endDate.day &&
                              startTime.hour == endTime!.hour &&
                              startTime.minute > endTime.minute) {
                            widget.startTimeController.text =
                                widget.endTimeController.text;
                          }
                        } catch (_) {
                          // Do nothing
                        }
                      }
                    }),
                    validator: (value) {
                      //if (widget.endDateController.text.isEmpty) { return 'Please select an end date before setting the end time';}
                      if (!widget.isEndTimeUndefined && value!.isEmpty) {
                        return 'Please enter an end time';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      suffixIcon: Checkbox(
                        value: widget.isEndTimeUndefined,
                        onChanged: widget.isEndDateUndefined
                            ? null
                            //? (value) {widget.isEndTimeUndefined = false;}
                            : (value) {
                                setState(() {
                                  widget.isEndTimeUndefined = value!;
                                  if (widget.isEndTimeUndefined) {
                                    widget.endTimeController.text = 'undefined';
                                  } else {
                                    widget.endTimeController.clear();
                                  }
                                });
                              },
                      ),
                      border: const OutlineInputBorder(),
                      labelText: 'End time',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 08,
            ),
            const Divider(
              height: 4,
            ),
          ],
        ));
    //),
    //);
  }
}
