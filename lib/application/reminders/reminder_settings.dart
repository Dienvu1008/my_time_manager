// Cài đặt nhắc nhở áp dụng lên engine (Phase R, D10 / D11).
import 'quiet_hours.dart';

class ReminderSettings {
  /// Bật nhắc bằng thông báo (khóa `remindersEnabled`).
  final bool enabled;

  /// Cờ tính năng: true = ReminderCoordinator, false = đường legacy.
  final bool coordinatorEnabled;
  final QuietHours quietHours;

  const ReminderSettings({
    this.enabled = true,
    this.coordinatorEnabled = true,
    this.quietHours = QuietHours.off,
  });

  ReminderSettings copyWith({
    bool? enabled,
    bool? coordinatorEnabled,
    QuietHours? quietHours,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        coordinatorEnabled: coordinatorEnabled ?? this.coordinatorEnabled,
        quietHours: quietHours ?? this.quietHours,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.coordinatorEnabled == coordinatorEnabled &&
      other.quietHours == quietHours;

  @override
  int get hashCode => Object.hash(enabled, coordinatorEnabled, quietHours);

  @override
  String toString() => 'ReminderSettings(enabled: $enabled, '
      'coordinator: $coordinatorEnabled, $quietHours)';
}

/// Áp cài đặt nhắc (AppBloc gọi).
abstract class ReminderControl {
  Future<void> apply(ReminderSettings settings);
}

class NoOpReminderControl implements ReminderControl {
  const NoOpReminderControl();
  @override
  Future<void> apply(ReminderSettings settings) async {}
}
