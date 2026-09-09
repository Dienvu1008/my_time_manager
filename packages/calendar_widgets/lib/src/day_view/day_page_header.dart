import 'dart:ui';

import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../style/header_style.dart';
import '../typedefs.dart';
import '../components/calendar_page_header.dart';
import '../utils.dart';

/// A header widget to display on day view.
class DayPageHeader extends CalendarPageHeader {
  /// A header widget to display on day view.
  const DayPageHeader({
    Key? key,
    VoidCallback? onNextDay,
    VoidCallback? onPreviousDay,
    VoidCallback? jumpToToday,
    AsyncCallback? onTitleTapped,
    DateTimeStringProvider? dateStringBuilder,
    required DateTime date,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: date,
          onNext: onNextDay,
          onPrevious: onPreviousDay,
          jumpToCurrently: jumpToToday,
          onTitleTapped: onTitleTapped,
          dateStringBuilder:
              dateStringBuilder ?? DayPageHeader._dayStringBuilder,
          headerStyle: headerStyle,
        );

  // static String _dayStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} - ${date.month} - ${date.year}";

  static String _dayStringBuilder(DateTime date, Locale locale,
      {DateTime? secondaryDate}) {
    final format = DateFormat('EEE, d MMMM yyyy', locale.languageCode);
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(Theme.of(context).colorScheme.background);
    final locale = Localizations.localeOf(context);
    final today = DateTime.now().withoutTime;
    final todayString = DateFormat('EEE, d MMMM yyyy', locale.languageCode).format(today);


    return Container(
      margin: headerStyle.headerMargin,
      padding: headerStyle.headerPadding,
      decoration: headerStyle.decoration ??
          BoxDecoration(color: Theme.of(context).colorScheme.background),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (headerStyle.leftIconVisible)
            IconButton(
              onPressed: onPrevious,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: headerStyle.leftIconPadding,
              icon: headerStyle.leftIcon ??
                  Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: labelColor,
                  ),
            ),
          Expanded(
            child: InkWell(
              onTap: onTitleTapped,
              child: Text(
                dateStringBuilder(date, locale, secondaryDate: secondaryDate),
                textAlign: headerStyle.titleAlign,
                style: headerStyle.headerTextStyle,
              ),
            ),
          ),
          if (todayString != dateStringBuilder(date, locale, secondaryDate: secondaryDate))
          IconButton(
            onPressed: jumpToCurrently,
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            padding: headerStyle.rightIconPadding,
            icon: Icon(
              Icons.today_outlined,
              size: 30,
              color: labelColor,
            ),
          ),
          if (headerStyle.rightIconVisible)
            IconButton(
              onPressed: onNext,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: headerStyle.rightIconPadding,
              icon: headerStyle.rightIcon ??
                  Icon(
                    Icons.chevron_right,
                    size: 30,
                    color: labelColor,
                  ),
            ),
        ],
      ),
    );
  }
}
