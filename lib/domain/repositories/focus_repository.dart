import '../../screen_focus_timer/data/model_focus_session.dart';

/// Domain boundary for **focus sessions** (Pomodoro focus runs used for
/// statistics and, in the future, by AI focus/analytics tools).
///
/// Callers (UI, blocs, and — later — AI tools) depend on this interface, never
/// on [DatabaseManager] / SQLite directly. The Sqlite implementation is
/// local-first: every session is written to SQLite first, then best-effort
/// synced to the cloud.
abstract class FocusRepository {
  /// Save a focus session (local first, then best-effort sync).
  Future<void> saveSession(FocusSession session);

  /// Retry syncing any sessions still pending upload. Safe to call anytime.
  Future<void> syncPending();

  /// All sessions, most recent first.
  Future<List<FocusSession>> allSessions();

  /// Sessions in the half-open range [start, end).
  Future<List<FocusSession>> sessionsBetween(DateTime start, DateTime end);
}
