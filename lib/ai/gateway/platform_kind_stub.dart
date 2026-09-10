import 'platform_kind.dart';

/// Web fallback: dart:io is unavailable. This is only reached when kIsWeb is
/// false yet dart:io is missing, which does not happen in practice; return
/// unknown to be safe.
PlatformKind ioPlatform() => PlatformKind.unknown;
