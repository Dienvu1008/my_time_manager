import 'package:flutter/material.dart';

class ImportanceListTile extends StatefulWidget {
  final bool isImportant;
  final ValueChanged<bool> onImportanceChanged;

  ImportanceListTile(
      {required this.isImportant, required this.onImportanceChanged});

  @override
  _ImportanceListTileState createState() => _ImportanceListTileState();
}

class _ImportanceListTileState extends State<ImportanceListTile> {
  bool _isImportant = false;

  @override
  void initState() {
    super.initState();
    _isImportant = widget.isImportant;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(
              _isImportant ? Icons.star : Icons.star_border,
            ),
          ),
          title: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              isDense: true,
              value: _isImportant,
              onChanged: (bool? newValue) {
                setState(() {
                  _isImportant = newValue!;
                });
                widget.onImportanceChanged(_isImportant);
              },
              items:
                  <bool>[true, false].map<DropdownMenuItem<bool>>((bool value) {
                return DropdownMenuItem<bool>(
                  value: value,
                  child: Text(value ? 'Important' : 'Not Important'),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
