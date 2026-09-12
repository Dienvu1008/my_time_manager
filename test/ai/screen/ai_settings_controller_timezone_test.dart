import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/config/ai_config_service.dart';
import 'package:my_time_manager/screen_ai/ai_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AiSettingsController> makeController() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = AiSettingsController(
      service: AiConfigService(prefs: prefs),
      timezoneResolver: () async => 'Asia/Ho_Chi_Minh',
    );
    // init() also refreshes models (hits the network / fails gracefully); that
    // is fine for timezone assertions — device tz is resolved before that.
    await c.init();
    return c;
  }

  test('defaults to the device timezone (no override stored)', () async {
    final c = await makeController();
    expect(c.deviceTimezone, 'Asia/Ho_Chi_Minh');
    expect(c.usingDeviceTimezone, isTrue);
    expect(c.effectiveTimezoneName, 'Asia/Ho_Chi_Minh');
    expect(c.config.timezone, isNull);
  });

  test('setting an override changes the effective timezone', () async {
    final c = await makeController();
    c.setTimezone('Europe/Paris');
    expect(c.usingDeviceTimezone, isFalse);
    expect(c.config.timezone, 'Europe/Paris');
    expect(c.effectiveTimezoneName, 'Europe/Paris');
  });

  test('selecting the device timezone is treated as "use device" (null)', () async {
    final c = await makeController();
    c.setTimezone('Asia/Ho_Chi_Minh'); // same as device
    expect(c.config.timezone, isNull, reason: 'tracks device, not a fixed zone');
    expect(c.usingDeviceTimezone, isTrue);
  });

  test('clearing the override falls back to device', () async {
    final c = await makeController();
    c.setTimezone('America/New_York');
    expect(c.usingDeviceTimezone, isFalse);
    c.setTimezone(null);
    expect(c.usingDeviceTimezone, isTrue);
    expect(c.effectiveTimezoneName, 'Asia/Ho_Chi_Minh');
  });

  test('availableTimezones always includes the device timezone', () async {
    final c = await makeController();
    expect(c.availableTimezones, contains('Asia/Ho_Chi_Minh'));
    // sorted & deduped
    expect(c.availableTimezones.toSet().length, c.availableTimezones.length);
  });

  test('save persists the override; reload reflects it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final svc = AiConfigService(prefs: prefs);
    final c = AiSettingsController(
      service: svc,
      timezoneResolver: () async => 'Asia/Ho_Chi_Minh',
    );
    await c.init();
    c.setTimezone('Europe/Berlin');
    await c.save();

    final reloaded = await svc.load();
    expect(reloaded.timezone, 'Europe/Berlin');
  });
}
