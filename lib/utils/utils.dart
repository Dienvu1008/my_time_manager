

import 'package:flutter/material.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

launchURL(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    throw 'Could not launch $url';
  }
}

void showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.comingSoon),
        content: Text(AppLocalizations.of(context)!.featureAvailableSoon),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showWillBeAvaiableOnProVersionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.availableOnProVersion),
        content: Text(AppLocalizations.of(context)!.featureUnderDevelopment),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Color contrastColor(Color color) {
  final brightness = ThemeData.estimateBrightnessForColor(color);
  switch (brightness) {
    case Brightness.dark:
      return Colors.white;
    case Brightness.light:
      return Colors.black;
  }
}

extension BuildContextTextTheme on BuildContext {
  TextTheme get textTheme =>
      Theme.of(this).textTheme
          //.apply(displayColor: Theme.of(this).colorScheme.onSurface)
  ;
}

extension BuildContextTextStyles on BuildContext {
  TextStyle getTextStyle(String name) {
    final styles = {
      'Display Large': textTheme.displayLarge!,
      'Display Medium': textTheme.displayMedium!,
      'Display Small': textTheme.displaySmall!,
      'Headline Large': textTheme.headlineLarge!,
      'Headline Medium': textTheme.headlineMedium!,
      'Headline Small': textTheme.headlineSmall!,
      'Title Large': textTheme.titleLarge!,
      'Title Medium': textTheme.titleMedium!,
      'Title Small': textTheme.titleSmall!,
      'Label Large': textTheme.labelLarge!,
      'Label Medium': textTheme.labelMedium!,
      'Label Small': textTheme.labelSmall!,
      'Body Large': textTheme.bodyLarge!,
      'Body Medium': textTheme.bodyMedium!,
      'Body Small': textTheme.bodySmall!,
    };
    return styles[name] ?? TextStyle();
  }
}



int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
        (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(1900, 1, 1);
final kLastDay = DateTime(2100, 1, 1);
