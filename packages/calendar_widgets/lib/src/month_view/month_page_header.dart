 import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../style/header_style.dart';
import '../typedefs.dart';
import '../components/calendar_page_header.dart';
import '../utils.dart';

class MonthPageHeader extends CalendarPageHeader {
  /// A header widget to display on month view.
  const MonthPageHeader({
    Key? key,
    VoidCallback? onNextMonth,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousMonth,
    VoidCallback? jumpToThisMonth,
    DateTimeStringProvider? dateStringBuilder,
    required DateTime date,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: date,
          onNext: onNextMonth,
          onPrevious: onPreviousMonth,
          jumpToCurrently: jumpToThisMonth,
          onTitleTapped: onTitleTapped,
          dateStringBuilder:
              dateStringBuilder ?? MonthPageHeader._monthStringBuilder,
          headerStyle: headerStyle,
        );

  static String _monthStringBuilder(DateTime date, Locale locale, {DateTime? secondaryDate}) {
    final format = DateFormat('MMMM yyyy', locale.languageCode);
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = contrastColor(Theme.of(context).colorScheme.background);
    final locale = Localizations.localeOf(context);
    final thisMonth = DateTime.now();
    final thisMonthString = DateFormat('MMMM yyyy', locale.languageCode).format(thisMonth);

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
          if (thisMonthString != dateStringBuilder(date, locale, secondaryDate: secondaryDate))
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
