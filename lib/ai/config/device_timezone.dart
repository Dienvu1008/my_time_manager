import 'package:flutter_timezone/flutter_timezone.dart';

/// Resolves the device's IANA timezone name (e.g. 'Asia/Ho_Chi_Minh').
/// Injectable so higher layers/tests don't depend on the platform channel.
typedef DeviceTimezoneResolver = Future<String> Function();

/// Default resolver using `flutter_timezone`. Falls back to 'UTC' if the
/// platform lookup fails (never throws).
Future<String> deviceTimezone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  } catch (_) {
    return 'UTC';
  }
}

/// The effective timezone: the user's configured [configuredTimezone] if set,
/// otherwise the device timezone from [resolver]. Pure aside from the resolver.
Future<String> effectiveTimezone(
  String? configuredTimezone, {
  DeviceTimezoneResolver resolver = deviceTimezone,
}) async {
  if (configuredTimezone != null && configuredTimezone.trim().isNotEmpty) {
    return configuredTimezone;
  }
  return resolver();
}
