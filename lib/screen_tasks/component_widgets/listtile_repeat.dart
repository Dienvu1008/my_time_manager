import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RepeatListTile extends StatefulWidget {
  @override
  _RepeatListTileState createState() => _RepeatListTileState();
}

class _RepeatListTileState extends State<RepeatListTile> {
  bool _showRepeatOptions = false;
  bool _showCustomOptions = false;
  String _selectedOption = 'Does not repeat';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.repeat_outlined),
          title: Text('Repeat?'),
          onTap: () {
            setState(() {
              _showRepeatOptions = !_showRepeatOptions;
            });
          },
        ),
        if (_showRepeatOptions)
          Column(
            children: [
              RadioListTile(
                title: const Text('Does not repeat'),
                value: 'Does not repeat',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every day'),
                value: 'Every day',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every week'),
                value: 'Every week',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every month'),
                value: 'Every month',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Every year'),
                value: 'Every year',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = false;
                  });
                },
              ),
              RadioListTile(
                title: const Text('Custom'),
                value: 'Custom',
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value as String;
                    _showCustomOptions = true;
                  });
                },
              ),
            ],
          ),
        if (_showCustomOptions) RepeatEveryListTile(),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}

class RepeatEveryListTile extends StatefulWidget {
  @override
  _RepeatEveryListTileState createState() => _RepeatEveryListTileState();
}

class _RepeatEveryListTileState extends State<RepeatEveryListTile> {
  int _repeatValue = 1;
  String _repeatType = 'day';
  String _selectedEndOption = 'Never';
  bool _showWeekDaysOptions = false;
  Map<String, bool> _selectedDays = {
    'Mon': false,
    'Tue': false,
    'Wen': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };
  bool _showMonthOptions = false;
  String _selectedMonthOption = 'Monthly on the same day';
  DateTime _selectedDate = DateTime.now();
  int _occurrence = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              Text('Repeats every'),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  initialValue: '$_repeatValue',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    setState(() {
                      _repeatValue = int.parse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _repeatType,
                  items: ['day', 'week', 'month', 'year'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(_repeatValue > 1 ? value + 's' : value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _repeatType = newValue!;
                      _showWeekDaysOptions = (_repeatType == 'week');
                      _showMonthOptions = (_repeatType == 'month');
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showWeekDaysOptions)
          Wrap(
            spacing: 8.0, // gap between adjacent chips
            runSpacing: 4.0, // gap between lines
            children: _selectedDays.keys.map((day) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDays[day] = !_selectedDays[day]!;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        _selectedDays[day]! ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(50.0),
                    border: Border.all(
                        color: Colors.blue, width: _selectedDays[day]! ? 0 : 1),
                  ),
                  child: Text(day),
                ),
              );
            }).toList(),
          ),
        if (_showMonthOptions)
          ListTile(
            title: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              value: _selectedMonthOption,
              items: [
                'Monthly on the same day',
                'Monthly on the same day of week'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMonthOption = newValue!;
                });
              },
            ),
          ),
        ListTile(
          title: Text('Ends'),
          subtitle: Column(
            children: [
              RadioListTile(
                title: const Text('Never'),
                value: 'Never',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
              RadioListTile(
                title: Row(
                  children: [
                    const Text('On day '),
                    Expanded(
                      child: TextFormField(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        initialValue:
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ],
                ),
                value: 'On day',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
              RadioListTile(
                title: Row(
                  children: [
                    const Text('After '),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$_occurrence',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          setState(() {
                            _occurrence = int.parse(value);
                          });
                        },
                      ),
                    ),
                    const Text(' occurrence'),
                  ],
                ),
                value: 'After x occurrence',
                groupValue: _selectedEndOption,
                onChanged: (value) {
                  setState(() {
                    _selectedEndOption = value as String;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
