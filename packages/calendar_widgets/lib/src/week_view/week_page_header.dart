import 'dart:ui';

import 'package:calendar_widgets/calendar_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../style/header_style.dart';
import '../typedefs.dart';
import '../components/calendar_page_header.dart';
import '../utils.dart';

class WeekPageHeader extends CalendarPageHeader {
  /// A header widget to display on week view.
  const WeekPageHeader({
    Key? key,
    VoidCallback? onNextWeek,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousWeek,
    VoidCallback? jumpToCurrentWeek,
    required DateTime startDate,
    required DateTime endDate,
    DateTimeStringProvider? headerStringBuilder,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: startDate,
          secondaryDate: endDate,
          onNext: onNextWeek,
          onPrevious: onPreviousWeek,
          jumpToCurrently: jumpToCurrentWeek,
          onTitleTapped: onTitleTapped,
          dateStringBuilder:
              headerStringBuilder ?? WeekPageHeader._weekStringBuilder,
          headerStyle: headerStyle,
        );

  // static String _weekStringBuilder(DateTime date, {DateTime? secondaryDate}) =>
  //     "${date.day} / ${date.month} / ${date.year} to "
  //     "${secondaryDate != null ? "${secondaryDate.day} / "
  //         "${secondaryDate.month} / ${secondaryDate.year}" : ""}";

  static String _weekStringBuilder(DateTime date, Locale locale,  {DateTime? secondaryDate}) {
    final format = DateFormat('MMMM yyyy', locale.languageCode);
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(Theme.of(context).colorScheme.background);
    final locale = Localizations.localeOf(context);
    final thisWeek= DateTime.now().withoutTime;
    final thisWeekString = DateFormat('MMMM yyyy', locale.languageCode).format(thisWeek);

    return Container(
      margin: headerStyle.headerMargin,
      padding: headerStyle.headerPadding,
      decoration:
      headerStyle.decoration ?? BoxDecoration(color: Theme.of(context).colorScheme.background),
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
          if (thisWeekString != dateStringBuilder(date, locale, secondaryDate: secondaryDate))
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
