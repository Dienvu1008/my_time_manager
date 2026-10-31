import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/app/app_localizations.dart';

const _locales = [
  'en', 'vi', 'de', 'cs', 'es', 'fr', 'it', 'ja', 'ko', 'no', 'ru', 'sv',
  'zh', //
];

Map<String, String Function(AppLocalizations)> _getters = {
  'aiActivityLog': (l) => l.aiActivityLog,
  'aiActivityLogEmpty': (l) => l.aiActivityLogEmpty,
  'aiActivityLogInfo': (l) => l.aiActivityLogInfo,
  'aiActivityLogClear': (l) => l.aiActivityLogClear,
  'aiActivityLogClearConfirm': (l) => l.aiActivityLogClearConfirm,
  'aiOutcomeAll': (l) => l.aiOutcomeAll,
  'aiOutcomeExecuted': (l) => l.aiOutcomeExecuted,
  'aiOutcomeDeclined': (l) => l.aiOutcomeDeclined,
  'aiOutcomeFailed': (l) => l.aiOutcomeFailed,
  'aiOutcomeDeniedByPolicy': (l) => l.aiOutcomeDeniedByPolicy,
  'aiActionArguments': (l) => l.aiActionArguments,
  'aiActionResult': (l) => l.aiActionResult,
  'aiActionError': (l) => l.aiActionError,
  'aiActionRiskLevel': (l) => l.aiActionRiskLevel,
  'aiActionPolicyMode': (l) => l.aiActionPolicyMode,
  'aiActionConversation': (l) => l.aiActionConversation,
};

void main() {
  for (final code in _locales) {
    test('every C8b getter resolves for "$code"', () {
      final l = AppLocalizations(Locale(code));
      for (final entry in _getters.entries) {
        expect(entry.value(l).trim(), isNotEmpty,
            reason: '${entry.key} is empty for $code');
      }
      expect(l.aiActivityLogInfo, contains('{n}'));
      expect(l.aiActivityLogInfo, contains('{days}'));
    });
  }
}
