import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/gateway/platform_kind.dart';

void main() {
  test('isDesktop / isMobile classification', () {
    expect(PlatformKind.windows.isDesktop, isTrue);
    expect(PlatformKind.linux.isDesktop, isTrue);
    expect(PlatformKind.android.isMobile, isTrue);
    expect(PlatformKind.ios.isMobile, isTrue);
    expect(PlatformKind.web.isDesktop, isFalse);
    expect(PlatformKind.web.isMobile, isFalse);
  });

  test('wire name round-trip; unknown falls back', () {
    for (final p in PlatformKind.values) {
      expect(PlatformKind.fromWireName(p.wireName), p);
    }
    expect(PlatformKind.fromWireName('nope'), PlatformKind.unknown);
  });
}
