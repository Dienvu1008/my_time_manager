import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/header_style.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/page_header_calendar.dart';
import 'package:my_time_manager/screen_calendar/utils/constants.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

/// A header widget to display on day view.
class DayPageHeader extends CalendarPageHeader {
  /// A header widget to display on day view.
  const DayPageHeader({
    Key? key,
    VoidCallback? onNextDay,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousDay,
    Color iconColor = Constants.black,
    Color backgroundColor = Constants.headerBackground,
    StringProvider? dateStringBuilder,
    required DateTime date,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: date,
          // ignore_for_file: deprecated_member_use_from_same_package
          //backgroundColor: backgroundColor,
          //iconColor: iconColor,
          onNextDay: onNextDay,
          onPreviousDay: onPreviousDay,
          onTitleTapped: onTitleTapped,
          dateStringBuilder:
              dateStringBuilder ?? DayPageHeader._dayStringBuilder,
          headerStyle: headerStyle,
        );
  // static String _dayStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} - ${date.month} - ${date.year}";

  static String _dayStringBuilder(DateTime date, {DateTime? secondaryDate}) {
    final format = DateFormat('EEE, d MMMM yyyy');
    return format.format(date);
  }
}
