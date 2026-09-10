import 'dart:io';

import 'platform_kind.dart';

/// dart:io-based platform detection (non-web platforms).
PlatformKind ioPlatform() {
  if (Platform.isWindows) return PlatformKind.windows;
  if (Platform.isMacOS) return PlatformKind.macos;
  if (Platform.isLinux) return PlatformKind.linux;
  if (Platform.isAndroid) return PlatformKind.android;
  if (Platform.isIOS) return PlatformKind.ios;
  return PlatformKind.unknown;
}
