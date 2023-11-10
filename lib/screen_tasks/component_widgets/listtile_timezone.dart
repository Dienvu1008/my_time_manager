import 'package:flutter/material.dart';

class TimezoneListTile extends StatefulWidget {
  @override
  _TimezoneListTileState createState() => _TimezoneListTileState();
}

class _TimezoneListTileState extends State<TimezoneListTile> {
  String _selectedTimezone = 'Timezone của thiết bị';

  // Danh sách tất cả các timezone theo IANA
  List<String> _timezones = [
    'Timezone 1',
    'Timezone 2',
    // Thêm tất cả các timezone khác vào đây
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.public_outlined),
      title: Text(_selectedTimezone),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Chọn timezone'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _timezones.map((timezone) {
                    return RadioListTile(
                      title: Text(timezone),
                      value: timezone,
                      groupValue: _selectedTimezone,
                      onChanged: (value) {
                        setState(() {
                          _selectedTimezone = value as String;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
