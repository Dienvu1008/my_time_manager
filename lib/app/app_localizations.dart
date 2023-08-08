import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'title': 'Title',
      'english': 'English',
      'vietnamese': 'Vietnamese',
      'german': 'German',
      'settings': 'Settings',
      'about': 'About',
      'how to use': 'How to use?',
      'tasks': 'Tasks',
      // ...
    },
    'vi': {
      'title': 'Tựa đề',
      'english': 'Tiếng Anh',
      'vietnamese': 'Tiếng Việt',
      'german': 'Tiếng Đức',
      'settings': 'Cài đặt',
      'about': 'Thông tin',
      'how to use': 'Hướng dẫn sử dụng',
      'tasks': 'Nhiệm vụ'
      // ...
    },
    'de': {
      'title': 'Titel',
      'english': 'Englisch',
      'vietnamese': 'Vietnamesisch',
      'german': 'Deutsch',
      'settings': 'Einstellungen',
      'about': 'Über uns',
      'how to use' : 'Anleitung',
      'tasks': 'Aufgaben'
      // ...
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get vietnamese => _localizedValues[locale.languageCode]!['vietnamese']!;
  String get german => _localizedValues[locale.languageCode]!['german']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get howToUse => _localizedValues[locale.languageCode]!['how to use']!;
  String get tasks => _localizedValues[locale.languageCode]!['tasks']!;

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'vi', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
