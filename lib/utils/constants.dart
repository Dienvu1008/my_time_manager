import 'package:flutter/material.dart';

// NavigationRail shows if the screen width is greater or equal to
// narrowScreenWidthThreshold; otherwise, NavigationBar is used for navigation.
const double narrowScreenWidthThreshold = 450;

const double mediumWidthBreakpoint = 1000;
const double largeWidthBreakpoint = 1500;

const double transitionLength = 500;

// Whether the user has chosen a theme color via a direct [ColorSeed] selection,
// or an image [ColorImageProvider].
enum ColorSelectionMethod {
  colorSeed,
  image,
}

enum ColorImageProvider {
  leaves('Leaves',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_1.png'),
  peonies('Peonies',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_2.png'),
  bubbles('Bubbles',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_3.png'),
  seaweed('Seaweed',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_4.png'),
  seagrapes('Sea Grapes',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_5.png'),
  petals('Petals',
      'https://flutter.github.io/assets-for-api-docs/assets/material/content_based_color_scheme_6.png');

  const ColorImageProvider(this.label, this.url);
  final String label;
  final String url;
}

enum ColorSeed {
  baseColor('M3 Baseline', Color(0xff6750a4)),
  purple("Purple", Colors.purple),
  deeppurple("Deep Purple", Colors.deepPurple),
  indigo('Indigo', Colors.indigo),
  lightblue("Lightblue", Colors.lightBlue),
  blue('Blue', Colors.blue),
  cyan("Cyan", Colors.cyan),
  teal('Teal', Colors.teal),
  lightgreen("Lightgreen", Colors.lightGreen),
  green('Green', Colors.green),
  lime("Lime", Colors.lime),
  amber("Amber", Colors.amber),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink),
  red("Red", Colors.red),
  grey("Grey", Colors.grey),
  brown("Brown", Colors.brown),
  black("Black", Colors.black),
  white("White", Colors.white);
  // baseColor('M3 Baseline', Color(0xff6750a4)),
  // indigo('Indigo', Colors.indigo),
  // blue('Blue', Colors.blue),
  // teal('Teal', Colors.teal),
  // green('Green', Colors.green),
  // yellow('Yellow', Colors.yellow),
  // orange('Orange', Colors.orange),
  // deepOrange('Deep Orange', Colors.deepOrange),
  // pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

enum ScreenSelected {
  tasksScreen(0),
  settingsScreen(1),
  aboutUsScreen(2),
  materialDesignScreen(3),
  calendarScreen(4),
  focusTimerScreen(5),
  contactsScreen(6),
  statsScreen(7);

  const ScreenSelected(this.value);
  final int value;
}

enum PageOfTasksScreenSelected {
  tasksOverviewPage(0),
  tasksTimelinePage(1),
  tasksTimetablePage(2),
  ;

  const PageOfTasksScreenSelected(this.value);
  final int value;
}

enum PageOfMaterialDesignScreenSelected {
  component(0),
  color(1),
  typography(2),
  elevation(3),
  ;

  const PageOfMaterialDesignScreenSelected(this.value);
  final int value;
}

enum PageOfCalendarScreenSelected {
  dayPage(0),
  weekPage(1),
  monthPage(2),
  yearPage(3),
  ;

  const PageOfCalendarScreenSelected(this.value);
  final int value;
}

enum AppLanguage {
  english('english', 'EN'),
  vietnamese('vietnamese', 'VI'),
  german('german', 'DE'),
  // french('french', 'FR'),
  // japanese('japanese', 'JA'),
  // russian('russian', 'RU'),
  // chinese('chinese', 'ZH'),
  // korean('korean', 'KO'),
  // italian('italian', 'IT'),
  ;

  const AppLanguage(this.language, this.short_language);
  final String language;
  final String short_language;
}

const double FONT_VERY_SMALL = 4.0;
const double FONT_SMALL = 8.0;
const double FONT_MEDIUM = 16.0;
const double FONT_LARGE = 24.0;
const double FONT_VERY_LARGE = 32.0;

//For Task Row
const double FONT_SIZE_TITLE = 16.0;
const double FONT_SIZE_LABEL = 14.0;
const double FONT_SIZE_DATE = 12.0;

//About_Us
class AboutUsKeys {
  static const TITLE_ABOUT = "titleAbout";
  static const TITLE_REPORT = 'titleReport';
  static const SUBTITLE_REPORT = 'subtitleReport';
  static const AUTHOR_NAME = 'authorName';
  static const AUTHOR_USERNAME = 'authorUsername';
  static const AUTHOR_EMAIL = 'authorEmail';
  static const VERSION_NUMBER = 'versionNumber';
}

const String GITHUB_URL = "https://github.com/Dienvu1008";
const String AUTHOR_FACEBOOK_URL =
    "https://www.facebook.com/profile.php?id=100074416023246";
const String PAGE_FACEBOOK_URL =
    "https://www.facebook.com/profile.php?id=100083919462769";
const String EMAIL_URL =
    "mailto:<dienvu1008@gmail.com>?subject=MyTimeManager%20Query&body=Hi";
const String README_URL =
    "https://github.com/Dienvu1008/My-Time-Manager-Infor/blob/master/README.md";
const String PRIVACY_URL =
    "https://github.com/Dienvu1008/My-Time-Manager-Infor/blob/master/PRIVACY.md";
const String ISSUE_URL =
    "https://github.com/Dienvu1008/My-Time-Manager-Infor/issues";
