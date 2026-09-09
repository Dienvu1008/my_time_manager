import 'dart:io';

import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

/// Một event lịch thiết bị đã được chuẩn hoá để dùng trong app (không phụ thuộc
/// trực tiếp vào kiểu của plugin ở tầng UI).
class DeviceEvent {
  DeviceEvent({
    required this.eventId,
    required this.calendarId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.location,
    this.allDay = false,
    this.calendarColor,
  });

  final String? eventId;
  final String? calendarId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String? location;
  final bool allDay;

  /// Màu của lịch chứa event (để hiển thị). Có thể null.
  final int? calendarColor;
}

/// Một lịch trên thiết bị.
class DeviceCalendarInfo {
  DeviceCalendarInfo({
    required this.id,
    required this.name,
    required this.isReadOnly,
    this.color,
    this.accountName,
  });

  final String id;
  final String name;
  final bool isReadOnly;
  final int? color;
  final String? accountName;
}

/// Dịch vụ bọc plugin `device_calendar` để đọc/ghi lịch hệ thống của thiết bị.
///
/// Chỉ hoạt động trên Android/iOS. Trên desktop (Windows/macOS/Linux) và web,
/// mọi thao tác trả về giá trị "rỗng"/false một cách an toàn để app không crash
/// (tính năng lấy lịch từ Google account trên Windows sẽ làm sau).
class DeviceCalendarService {
  DeviceCalendarService._();
  static final DeviceCalendarService instance = DeviceCalendarService._();

  final dc.DeviceCalendarPlugin _plugin = dc.DeviceCalendarPlugin();

  /// Nền tảng có hỗ trợ đọc lịch thiết bị không.
  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Kiểm tra đã có quyền lịch chưa.
  Future<bool> hasPermissions() async {
    if (!isSupported) return false;
    try {
      final res = await _plugin.hasPermissions();
      return res.data ?? false;
    } catch (e) {
      debugPrint('DeviceCalendar hasPermissions lỗi: $e');
      return false;
    }
  }

  /// Xin quyền lịch (mở hộp thoại hệ thống nếu cần). Trả về true nếu được cấp.
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    try {
      final res = await _plugin.requestPermissions();
      return res.data ?? false;
    } catch (e) {
      debugPrint('DeviceCalendar requestPermissions lỗi: $e');
      return false;
    }
  }

  /// Đảm bảo có quyền: nếu chưa có thì xin. Trả về true nếu cuối cùng có quyền.
  Future<bool> ensurePermissions() async {
    if (!isSupported) return false;
    if (await hasPermissions()) return true;
    return requestPermissions();
  }

  /// Lấy danh sách lịch trên thiết bị.
  Future<List<DeviceCalendarInfo>> retrieveCalendars() async {
    if (!isSupported) return const [];
    try {
      final res = await _plugin.retrieveCalendars();
      final data = res.data;
      if (data == null) return const [];
      return data
          .map((c) => DeviceCalendarInfo(
                id: c.id ?? '',
                name: c.name ?? '(không tên)',
                isReadOnly: c.isReadOnly ?? false,
                color: c.color,
                accountName: c.accountName,
              ))
          .where((c) => c.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('DeviceCalendar retrieveCalendars lỗi: $e');
      return const [];
    }
  }

  /// Đọc tất cả event trong khoảng [start, end) từ MỌI lịch của thiết bị.
  ///
  /// Không đọc được (không quyền / desktop) -> trả về danh sách rỗng.
  Future<List<DeviceEvent>> retrieveEvents(DateTime start, DateTime end) async {
    if (!isSupported) return const [];
    try {
      final calendars = await _plugin.retrieveCalendars();
      final cals = calendars.data;
      if (cals == null) return const [];

      final result = <DeviceEvent>[];
      for (final cal in cals) {
        if (cal.id == null) continue;
        final eventsRes = await _plugin.retrieveEvents(
          cal.id,
          dc.RetrieveEventsParams(startDate: start, endDate: end),
        );
        final events = eventsRes.data;
        if (events == null) continue;
        for (final e in events) {
          if (e.start == null || e.end == null) continue;
          result.add(DeviceEvent(
            eventId: e.eventId,
            calendarId: cal.id,
            title: e.title ?? '(không tiêu đề)',
            start: e.start!,
            end: e.end!,
            description: e.description,
            location: e.location,
            allDay: e.allDay ?? false,
            calendarColor: cal.color,
          ));
        }
      }
      return result;
    } catch (e) {
      debugPrint('DeviceCalendar retrieveEvents lỗi: $e');
      return const [];
    }
  }

  /// Tạo mới hoặc cập nhật một event. Nếu [eventId] null -> tạo mới.
  /// Trả về eventId nếu thành công, null nếu thất bại.
  Future<String?> createOrUpdateEvent({
    required String calendarId,
    String? eventId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
    bool allDay = false,
  }) async {
    if (!isSupported) return null;
    try {
      final event = dc.Event(
        calendarId,
        eventId: eventId,
        title: title,
        start: _toTz(start),
        end: _toTz(end),
        description: description,
        location: location,
        allDay: allDay,
      );
      final res = await _plugin.createOrUpdateEvent(event);
      if (res != null && res.isSuccess) {
        return res.data;
      }
      debugPrint('DeviceCalendar createOrUpdateEvent thất bại: '
          '${res?.errors.map((e) => e.errorMessage).join(', ')}');
      return null;
    } catch (e) {
      debugPrint('DeviceCalendar createOrUpdateEvent lỗi: $e');
      return null;
    }
  }

  /// Xóa một event khỏi lịch. Trả về true nếu thành công.
  Future<bool> deleteEvent(String calendarId, String eventId) async {
    if (!isSupported) return false;
    try {
      final res = await _plugin.deleteEvent(calendarId, eventId);
      return res.data ?? false;
    } catch (e) {
      debugPrint('DeviceCalendar deleteEvent lỗi: $e');
      return false;
    }
  }

  /// Chuyển [dt] sang TZDateTime ở múi giờ địa phương (plugin yêu cầu TZDateTime).
  tz.TZDateTime _toTz(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }
}
