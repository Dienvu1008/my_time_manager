import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Quản lý định danh thiết bị/cài đặt (deviceId) dùng cho tính năng
/// export/import: mỗi bản ghi ghi nhận nó được tạo/sửa từ thiết bị nào, để khi
/// nhập dữ liệu từ file có thể hiển thị nguồn và xử lý xung đột.
///
/// deviceId là một UUID sinh MỘT LẦN ở lần chạy đầu và lưu bền trong
/// SharedPreferences (ổn định qua các lần mở app, không cần quyền hệ thống).
/// Kèm theo là một tên thiết bị dễ đọc (từ device_info_plus) chỉ dùng để hiển
/// thị cho người dùng.
class DeviceIdProvider {
  DeviceIdProvider._();

  static const String _deviceIdKey = 'deviceInstallId';
  static const String _deviceNameKey = 'deviceDisplayName';

  static String? _deviceId;
  static String? _deviceName;

  /// deviceId hiện tại (chỉ có giá trị sau khi [init] chạy xong).
  static String? get deviceId => _deviceId;

  /// Tên thiết bị dễ đọc (ví dụ "Windows PC", "Pixel 7"). Có thể null.
  static String? get deviceName => _deviceName;

  /// Khởi tạo: đọc deviceId đã lưu, hoặc sinh mới nếu chưa có. Cũng cố gắng
  /// lấy tên thiết bị dễ đọc. An toàn: mọi lỗi được nuốt để không chặn khởi
  /// động app (deviceId khi đó có thể null và được coi là "không rõ").
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      var id = prefs.getString(_deviceIdKey);
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString(_deviceIdKey, id);
      }
      _deviceId = id;

      // Tên thiết bị: đọc từ cache trước, nếu chưa có thì lấy từ device_info.
      var name = prefs.getString(_deviceNameKey);
      if (name == null || name.isEmpty) {
        name = await _readDeviceName();
        if (name != null && name.isNotEmpty) {
          await prefs.setString(_deviceNameKey, name);
        }
      }
      _deviceName = name;
    } catch (e) {
      debugPrint('DeviceIdProvider.init lỗi: $e');
    }
  }

  /// Lấy tên thiết bị dễ đọc theo nền tảng. Trả về null nếu không xác định được.
  static Future<String?> _readDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return web.browserName.name;
      }
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return '${a.manufacturer} ${a.model}';
      }
      if (Platform.isIOS) {
        final i = await info.iosInfo;
        return i.name;
      }
      if (Platform.isWindows) {
        final w = await info.windowsInfo;
        return w.computerName;
      }
      if (Platform.isMacOS) {
        final m = await info.macOsInfo;
        return m.computerName;
      }
      if (Platform.isLinux) {
        final l = await info.linuxInfo;
        return l.prettyName;
      }
    } catch (e) {
      debugPrint('Đọc tên thiết bị lỗi: $e');
    }
    return null;
  }
}
