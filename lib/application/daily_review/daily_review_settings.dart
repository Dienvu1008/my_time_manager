// Feature flag for Daily Review (Phase DR1). The UI toggle is DR2.

/// SharedPreferences key of the Daily Review feature flag (default ON).
/// Disabling it hides the review (rollback, roadmap §6 DR).
const String dailyReviewEnabledKey = 'dailyReviewEnabled';

/// Default value of [dailyReviewEnabledKey] when unset.
const bool dailyReviewEnabledDefault = true;

/// Reads the flag through any key/value reader (e.g.
/// `prefs.get`) without depending on a settings plugin. Unset / non-bool →
/// [dailyReviewEnabledDefault].
bool isDailyReviewEnabled(Object? Function(String key) read) {
  final raw = read(dailyReviewEnabledKey);
  return raw is bool ? raw : dailyReviewEnabledDefault;
}
