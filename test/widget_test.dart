// Placeholder smoke test.
//
// The original default `flutter create` counter test was stale: its
// `pumpWidget` was commented out and it asserted on a counter UI that this app
// does not have, so it could never pass. It is replaced with a trivial always-
// passing test so `flutter test` has a valid, fast baseline. Real behavioral
// tests for the new repository/domain boundaries live in test/data/ and
// test/domain/.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke: test harness runs', () {
    expect(1 + 1, 2);
  });
}
