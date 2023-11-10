import 'package:flutter/material.dart';

class CompletionListTile extends StatefulWidget {
  final bool isCompleted;
  final ValueChanged<bool> onCompletionChanged;
  final bool? isUsedForTimeInterval;

  CompletionListTile(
      {required this.isCompleted,
      required this.onCompletionChanged,
      this.isUsedForTimeInterval});

  @override
  _CompletionListTileState createState() => _CompletionListTileState();
}

class _CompletionListTileState extends State<CompletionListTile> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Padding(
            padding: EdgeInsets.only(left: 0.0, right: 4.0),
            child: Icon(
              _isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
            ),
          ),
          title: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              //isDense: true,
              isExpanded: true,
              value: _isCompleted,
              onChanged: (bool? newValue) {
                setState(() {
                  _isCompleted = newValue!;
                });
                widget.onCompletionChanged(_isCompleted);
              },
              items:
                  <bool>[true, false].map<DropdownMenuItem<bool>>((bool value) {
                // return DropdownMenuItem<bool>(
                //   value: value,
                //   child: widget.isUsedForTimeInterval!
                //   ? Expanded(child: Text(value? 'Completed in this time interval' : 'Incompleted in this time interval'))
                //   : Expanded(child: Text(value ? 'Completed' : 'Incompleted'),)
                // );
                return DropdownMenuItem<bool>(
                  value: value,
                  child: (widget.isUsedForTimeInterval ?? false)
                      ? Text(value
                              ? 'Completed in this time interval'
                              : 'Incompleted in this time interval')
                      : Text(value ? 'Completed' : 'Incompleted'),
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
