import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/config/device_timezone.dart';

void main() {
  Future<String> fakeDevice() async => 'Asia/Ho_Chi_Minh';

  test('configured timezone wins over the device timezone', () async {
    final tz = await effectiveTimezone('Europe/Paris', resolver: fakeDevice);
    expect(tz, 'Europe/Paris');
  });

  test('falls back to the device timezone when none configured', () async {
    expect(await effectiveTimezone(null, resolver: fakeDevice),
        'Asia/Ho_Chi_Minh');
    expect(await effectiveTimezone('  ', resolver: fakeDevice),
        'Asia/Ho_Chi_Minh');
  });
}
