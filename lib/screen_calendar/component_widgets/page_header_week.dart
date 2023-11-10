import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/header_style.dart';
import 'package:my_time_manager/screen_calendar/component_widgets/page_header_calendar.dart';
import 'package:my_time_manager/screen_calendar/utils/typedefs.dart';

class WeekPageHeader extends CalendarPageHeader {
  /// A header widget to display on week view.
  const WeekPageHeader({
    Key? key,
    VoidCallback? onNextDay,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousDay,
    required DateTime startDate,
    required DateTime endDate,
    //Color iconColor = Constants.black,
    //Color backgroundColor = Constants.headerBackground,
    StringProvider? headerStringBuilder,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: startDate,
          secondaryDate: endDate,
          onNextDay: onNextDay,
          onPreviousDay: onPreviousDay,
          onTitleTapped: onTitleTapped,
          // ignore_for_file: deprecated_member_use_from_same_package
          //iconColor: iconColor,
          //backgroundColor: backgroundColor,
          dateStringBuilder:
              headerStringBuilder ?? WeekPageHeader._weekStringBuilder,
          headerStyle: headerStyle,
        );
  // static String _weekStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} / ${date.month} / ${date.year} to "
  //     "${secondaryDate != null ? "${secondaryDate.day} / "
  //         "${secondaryDate.month} / ${secondaryDate.year}" : ""}";
  static String _weekStringBuilder(DateTime date, {DateTime? secondaryDate}) {
    final format = DateFormat('MMMM yyyy');
    return format.format(date);
  }
}
