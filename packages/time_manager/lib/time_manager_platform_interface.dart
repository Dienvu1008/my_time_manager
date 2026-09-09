import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'time_manager_method_channel.dart';

abstract class TimeManagerPlatform extends PlatformInterface {
  /// Constructs a TimeManagerPlatform.
  TimeManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static TimeManagerPlatform _instance = MethodChannelTimeManager();

  /// The default instance of [TimeManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelTimeManager].
  static TimeManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TimeManagerPlatform] when
  /// they register themselves.
  static set instance(TimeManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
