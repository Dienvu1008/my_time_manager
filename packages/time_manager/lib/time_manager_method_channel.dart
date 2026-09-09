import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'time_manager_platform_interface.dart';

/// An implementation of [TimeManagerPlatform] that uses method channels.
class MethodChannelTimeManager extends TimeManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('time_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
