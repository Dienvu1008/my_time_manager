import 'package:flutter/material.dart';

class AlarmListTile extends StatefulWidget {
  @override
  _AlarmListTileState createState() => _AlarmListTileState();
}

class _AlarmListTileState extends State<AlarmListTile> {
  List<String> alarms = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.alarm_outlined),
          title: Text('Alarm'),
          onTap: () {
            if (alarms.length < 5) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Choose an alarm'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                          title: const Text('5 minutes before'),
                          value: '5 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('10 minutes before'),
                          value: '10 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('15 minutes before'),
                          value: '15 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('30 minutes before'),
                          value: '30 minutes before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('1 hour before'),
                          value: '1 hour before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('1 day before'),
                          value: '1 day before',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        RadioListTile(
                          title: const Text('Custom...'),
                          value: 'custom',
                          groupValue: null,
                          onChanged: (value) {
                            setState(() {
                              alarms.add(value as String);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
        const Divider(
          height: 4,
        ),
        for (var alarm in alarms)
          ListTile(
            title: Text(alarm),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  alarms.remove(alarm);
                });
              },
            ),
          ),
      ],
    );
  }
}
