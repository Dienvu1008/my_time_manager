import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/time_manager.dart';
import 'package:time_manager/time_manager_platform_interface.dart';
import 'package:time_manager/time_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTimeManagerPlatform
    with MockPlatformInterfaceMixin
    implements TimeManagerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TimeManagerPlatform initialPlatform = TimeManagerPlatform.instance;

  test('$MethodChannelTimeManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTimeManager>());
  });

  test('getPlatformVersion', () async {
    TimeManagerPlugin timeManagerPlugin = TimeManagerPlugin();
    MockTimeManagerPlatform fakePlatform = MockTimeManagerPlatform();
    TimeManagerPlatform.instance = fakePlatform;

    //expect(await timeManagerPlugin.getPlatformVersion(), '42');
  });
}
