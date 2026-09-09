import 'package:flutter/material.dart';

import '../database/database_manager.dart';
import '../device_calendar/device_calendar_service.dart';
import '../models/model_calendar_event.dart';

/// ---------------------------------------------------------------------------
/// ĐỒNG BỘ VỚI LỊCH THIẾT BỊ (Android/iOS)
/// ---------------------------------------------------------------------------
/// Bắc cầu giữa model [CalendarEvent] của app và [DeviceCalendarService] (bọc
/// plugin `device_calendar`). Khác với Google (REST + JSON), lịch thiết bị
/// không dùng toGoogleJson — ta ánh xạ trực tiếp các trường cơ bản mà plugin hỗ
/// trợ (tiêu đề, mô tả, địa điểm, giờ bắt đầu/kết thúc, cả ngày).
///
/// Trên desktop/web, [DeviceCalendarService] tự trả rỗng/false nên các hàm ở
/// đây cũng trở thành no-op an toàn.
///
/// Quy ước: dùng chung trường [CalendarEvent.googleEventId] để lưu id của event
/// trên lịch thiết bị (đây là "remote id" của bản ghi), và [calendarId] để biết
/// event thuộc lịch thiết bị nào.
/// ---------------------------------------------------------------------------
class DeviceCalendarSyncService {
  DeviceCalendarSyncService({
    DatabaseManager? databaseManager,
    DeviceCalendarService? deviceCalendarService,
  })  : _db = databaseManager ?? DatabaseManager(),
        _device = deviceCalendarService ?? DeviceCalendarService.instance;

  final DatabaseManager _db;
  final DeviceCalendarService _device;

  bool get isSupported => _device.isSupported;

  // -------------------------------------------------------------------------
  // PUSH: đẩy thay đổi cục bộ lên lịch thiết bị
  // -------------------------------------------------------------------------

  /// Đẩy các event đang chờ đồng bộ lên [calendarId] của thiết bị. Trả về số
  /// event xử lý thành công. No-op (trả 0) nếu nền tảng không hỗ trợ hoặc chưa
  /// có quyền.
  Future<int> pushPending(String calendarId) async {
    if (!isSupported) return 0;
    if (!await _device.ensurePermissions()) return 0;

    final pending = await _db.calendarEventsPendingSync();
    var success = 0;
    for (final event in pending) {
      try {
        switch (event.syncStatus) {
          case EventSyncStatus.localOnly:
          case EventSyncStatus.pendingUpdate:
            await _pushUpsert(calendarId, event);
            break;
          case EventSyncStatus.pendingDelete:
            await _pushDelete(calendarId, event);
            break;
          case EventSyncStatus.synced:
            continue;
        }
        success++;
      } catch (e) {
        debugPrint('DeviceCalendarSync pushPending lỗi (${event.id}): $e');
      }
    }
    return success;
  }

  Future<void> _pushUpsert(String calendarId, CalendarEvent event) async {
    final eventId = await _device.createOrUpdateEvent(
      calendarId: calendarId,
      eventId: event.googleEventId,
      title: event.title,
      start: event.start.effective,
      end: event.end.effective,
      description: event.description.isEmpty ? null : event.description,
      location: event.location.isEmpty ? null : event.location,
      allDay: event.isAllDay,
    );
    if (eventId != null) {
      await _db.markCalendarEventSynced(
        event.id,
        googleEventId: eventId,
        calendarId: calendarId,
      );
    }
  }

  Future<void> _pushDelete(String calendarId, CalendarEvent event) async {
    if (event.googleEventId != null) {
      await _device.deleteEvent(calendarId, event.googleEventId!);
    }
    await _db.deleteCalendarEvent(event.id);
  }

  // -------------------------------------------------------------------------
  // PULL: kéo event từ lịch thiết bị về DB cục bộ
  // -------------------------------------------------------------------------

  /// Đọc event thiết bị trong [start, end) và upsert vào DB cục bộ (khớp theo
  /// id thiết bị lưu ở googleEventId). [taskListId] để gắn event mới vào một
  /// danh sách của app. Trả về số event đã upsert.
  Future<int> pull(
    DateTime start,
    DateTime end, {
    String? taskListId,
  }) async {
    if (!isSupported) return 0;
    if (!await _device.ensurePermissions()) return 0;

    final deviceEvents = await _device.retrieveEvents(start, end);
    var upserted = 0;
    for (final de in deviceEvents) {
      final remoteId = de.eventId;
      if (remoteId == null) continue;

      final existing = await _db.calendarEventByGoogleId(remoteId);
      final event = _fromDeviceEvent(
        de,
        localId: existing?.id,
        taskListId: existing?.taskListId ?? taskListId,
      );
      if (existing == null) {
        await _db.insertCalendarEvent(event);
      } else {
        await _db.updateCalendarEvent(event);
      }
      upserted++;
    }
    return upserted;
  }

  /// Chuyển một [DeviceEvent] thành [CalendarEvent] cục bộ (đã đồng bộ).
  CalendarEvent _fromDeviceEvent(
    DeviceEvent de, {
    String? localId,
    String? taskListId,
  }) {
    final EventDateTime start;
    final EventDateTime end;
    if (de.allDay) {
      start = EventDateTime(date: DateTime(de.start.year, de.start.month, de.start.day));
      end = EventDateTime(date: DateTime(de.end.year, de.end.month, de.end.day));
    } else {
      start = EventDateTime(dateTime: de.start);
      end = EventDateTime(dateTime: de.end);
    }
    return CalendarEvent(
      id: localId,
      taskListId: taskListId,
      title: de.title,
      description: de.description,
      location: de.location,
      color: de.calendarColor != null ? Color(de.calendarColor!) : null,
      start: start,
      end: end,
      googleEventId: de.eventId,
      calendarId: de.calendarId,
      syncStatus: EventSyncStatus.synced,
    );
  }

  /// Đồng bộ hai chiều một lần: đẩy thay đổi cục bộ rồi kéo về.
  Future<int> syncTwoWay(
    String calendarId,
    DateTime start,
    DateTime end, {
    String? taskListId,
  }) async {
    await pushPending(calendarId);
    return pull(start, end, taskListId: taskListId);
  }
}
