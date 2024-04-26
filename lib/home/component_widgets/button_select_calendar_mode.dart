import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/material.dart';

class CalendarModeSubmenuButton extends StatelessWidget {
  const CalendarModeSubmenuButton(
      {required this.handleSelectionModeChange,
      required this.rangeSelectionMode});

  final void Function(String) handleSelectionModeChange;
  final RangeSelectionMode rangeSelectionMode;

  @override
  Widget build(BuildContext context) {
    //final localizations = AppLocalizations.of(context);
    return SubmenuButton(
      menuChildren: [
        // MenuItemButton(
        //   onPressed: () => handleSelectionModeChange('all'),
        //   child: Text('Show all tasks of a month'),
        // ),
        MenuItemButton(
          onPressed: () => handleSelectionModeChange('multi'),
          child: Text(
            'Multi days selection',
            style: TextStyle(
              color: rangeSelectionMode == RangeSelectionMode.toggledOff
                  ? Colors.blue
                  : null,
            ),
          ),
        ),
        MenuItemButton(
          onPressed: () => handleSelectionModeChange('range'),
          child: Text(
            'Days range selection',
            style: TextStyle(
              color: rangeSelectionMode == RangeSelectionMode.toggledOn
                  ? Colors.blue
                  : null,
            ),
          ),
        ),
      ],
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          SizedBox(
            width: 170,
            child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: rangeSelectionMode == RangeSelectionMode.toggledOff
                  ? Text('Multi days selection')
                  : Text('Days range selection'),
            ),
          ),
        ],
      ),
    );
  }
}
