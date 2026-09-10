import 'package:flutter/foundation.dart' show kIsWeb;

import 'platform_kind_stub.dart'
    if (dart.library.io) 'platform_kind_io.dart' as impl;

/// The platform the app is running on, for provider routing. Kept separate from
/// dart:io so it can be injected in tests.
enum PlatformKind {
  windows,
  macos,
  linux,
  android,
  ios,
  web,
  unknown;

  bool get isDesktop =>
      this == windows || this == macos || this == linux;
  bool get isMobile => this == android || this == ios;

  String get wireName => name;

  static PlatformKind fromWireName(String value) =>
      PlatformKind.values.firstWhere(
        (p) => p.wireName == value,
        orElse: () => PlatformKind.unknown,
      );
}

/// Resolves the current [PlatformKind]. Injectable so tests don't depend on the
/// host OS. The default uses kIsWeb + dart:io's Platform via a lazy import.
typedef PlatformResolver = PlatformKind Function();

/// Default resolver. Uses [kIsWeb] first (dart:io Platform throws on web), then
/// dart:io. Imported lazily through [_ioPlatform] to keep this file web-safe.
PlatformKind defaultPlatformResolver() {
  if (kIsWeb) return PlatformKind.web;
  return impl.ioPlatform();
}
