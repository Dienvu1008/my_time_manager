import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/header_style.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/page_header_calendar.dart';
import 'package:my_time_manager/screen_calendar/utils/constants.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

class MonthPageHeader extends CalendarPageHeader {
  /// A header widget to display on month view.
  const MonthPageHeader({
    Key? key,
    VoidCallback? onNextMonth,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousMonth,
    Color iconColor = Constants.black,
    Color backgroundColor = Constants.headerBackground,
    StringProvider? dateStringBuilder,
    required DateTime date,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: date,
          onNextDay: onNextMonth,
          onPreviousDay: onPreviousMonth,
          onTitleTapped: onTitleTapped,
          // ignore_for_file: deprecated_member_use_from_same_package
          //backgroundColor: backgroundColor,
          //iconColor: iconColor,
          dateStringBuilder:
              dateStringBuilder ?? MonthPageHeader._monthStringBuilder,
          headerStyle: headerStyle,
        );
  // static String _monthStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.month} - ${date.year}";

  static String _monthStringBuilder(DateTime date, {DateTime? secondaryDate}) {
    final format = DateFormat('MMMM yyyy');
    return format.format(date);
  }
}
