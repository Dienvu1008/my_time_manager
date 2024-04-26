import 'package:flutter/material.dart';

class ShowHideCalendarMenuItemButton extends StatelessWidget {
  const ShowHideCalendarMenuItemButton({
    required this.handleCalendarVisibilityChange,
    required this.showCalendar,
  });

  final void Function() handleCalendarVisibilityChange;
  final bool showCalendar;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          showCalendar
              ? const SizedBox(
                  width: 100,
                  child: Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('Show calendar')))
              : const SizedBox(
                  width: 100,
                  child: Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text('Hide calendar'),
                  ),
                ),
          const SizedBox(
            width: 20,
          ),
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Switch(
                  value: showCalendar,
                  onChanged: (_) {
                    handleCalendarVisibilityChange();
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
