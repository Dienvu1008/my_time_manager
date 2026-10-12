import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/model_calendar_event.dart';
import '../repositories/sqlite_calendar_repository.dart';
import '../../domain/repositories/calendar_repository.dart';

/// ---------------------------------------------------------------------------
/// ĐỒNG BỘ VỚI GOOGLE CALENDAR (REST API v3)
/// ---------------------------------------------------------------------------
/// Dùng trực tiếp HTTP (package `http`) với access token OAuth Bearer — app đã
/// có sẵn flow lấy access token (xem lib/auth), nên không cần thêm gói
/// `googleapis`. Toàn bộ chuyển đổi dữ liệu dựa vào
/// [CalendarEvent.toGoogleJson] / [CalendarEvent.fromGoogleJson].
///
/// Chiến lược đồng bộ (đơn giản, hai chiều, dựa trên [EventSyncStatus] + etag):
///   - push:   đẩy các event cục bộ có syncStatus localOnly/pendingUpdate lên
///             (POST tạo mới hoặc PATCH cập nhật; dùng If-Match: etag để tránh
///             ghi đè thay đổi phía server), và xóa các event pendingDelete.
///   - pull:   kéo event từ một calendar về, upsert vào DB cục bộ (khớp theo
///             googleEventId). Hỗ trợ đồng bộ tăng dần bằng syncToken.
///
/// LƯU Ý: Lớp này chỉ lo phần mạng + ghi DB. Việc lấy/renew access token, chọn
/// calendarId, và lên lịch chạy đồng bộ do tầng trên quyết định.
/// ---------------------------------------------------------------------------

/// Hàm cung cấp access token hợp lệ (có thể refresh). Trả về null nếu chưa đăng
/// nhập / không lấy được token.
typedef AccessTokenProvider = Future<String?> Function();

/// Kết quả của một lần pull (để tầng trên lưu lại syncToken cho lần sau).
class CalendarPullResult {
  const CalendarPullResult({
    required this.upserted,
    required this.deleted,
    this.nextSyncToken,
  });

  /// Số event được tạo mới hoặc cập nhật cục bộ.
  final int upserted;

  /// Số event bị xóa cục bộ (server báo status = cancelled).
  final int deleted;

  /// Token cho lần đồng bộ tăng dần kế tiếp (Google trả ở trang cuối). Lưu lại
  /// để lần sau chỉ kéo phần thay đổi.
  final String? nextSyncToken;
}

class GoogleCalendarSyncService {
  GoogleCalendarSyncService({
    required this.accessTokenProvider,
    CalendarRepository? calendarRepository,
    http.Client? client,
  })  : _calendars = calendarRepository ?? SqliteCalendarRepository(),
        _client = client ?? http.Client();

  final AccessTokenProvider accessTokenProvider;
  final CalendarRepository _calendars;
  final http.Client _client;

  static const String _base = 'https://www.googleapis.com/calendar/v3';

  Future<Map<String, String>> _authHeaders() async {
    final token = await accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const GoogleCalendarSyncException('Chưa có access token Google.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _eventsUri(String calendarId, {String? eventId, Map<String, String>? q}) {
    final encodedCal = Uri.encodeComponent(calendarId);
    final path = eventId == null
        ? '$_base/calendars/$encodedCal/events'
        : '$_base/calendars/$encodedCal/events/${Uri.encodeComponent(eventId)}';
    return Uri.parse(path).replace(queryParameters: q);
  }

  // -------------------------------------------------------------------------
  // PUSH: đẩy thay đổi cục bộ lên Google
  // -------------------------------------------------------------------------

  /// Đẩy tất cả event đang chờ đồng bộ (localOnly/pendingUpdate/pendingDelete)
  /// lên [calendarId]. Trả về số event đã xử lý thành công.
  Future<int> pushPending(String calendarId) async {
    final pending = await _calendars.getEventsPendingSync();
    var success = 0;
    for (final event in pending) {
      try {
        switch (event.syncStatus) {
          case EventSyncStatus.localOnly:
            await _createRemote(calendarId, event);
            break;
          case EventSyncStatus.pendingUpdate:
            if (event.googleEventId == null) {
              await _createRemote(calendarId, event);
            } else {
              await _updateRemote(calendarId, event);
            }
            break;
          case EventSyncStatus.pendingDelete:
            await _deleteRemote(calendarId, event);
            break;
          case EventSyncStatus.synced:
            continue;
        }
        success++;
      } catch (e) {
        debugPrint('pushPending lỗi cho event ${event.id}: $e');
        // Bỏ qua event lỗi, tiếp tục các event khác.
      }
    }
    return success;
  }

  Future<void> _createRemote(String calendarId, CalendarEvent event) async {
    final headers = await _authHeaders();
    final res = await _client.post(
      _eventsUri(calendarId),
      headers: headers,
      body: jsonEncode(event.toGoogleJson()),
    );
    _ensureOk(res, 'tạo event');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await _calendars.markSynced(
      event.id,
      googleEventId: body['id'] as String?,
      etag: body['etag'] as String?,
      calendarId: calendarId,
      iCalUID: body['iCalUID'] as String?,
    );
  }

  Future<void> _updateRemote(String calendarId, CalendarEvent event) async {
    final headers = await _authHeaders();
    // If-Match với etag để khóa lạc quan (server từ chối nếu đã đổi phía nó).
    if (event.etag != null) headers['If-Match'] = event.etag!;
    final res = await _client.patch(
      _eventsUri(calendarId, eventId: event.googleEventId),
      headers: headers,
      body: jsonEncode(event.toGoogleJson()),
    );
    _ensureOk(res, 'cập nhật event');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await _calendars.markSynced(
      event.id,
      googleEventId: body['id'] as String?,
      etag: body['etag'] as String?,
      calendarId: calendarId,
    );
  }

  Future<void> _deleteRemote(String calendarId, CalendarEvent event) async {
    if (event.googleEventId == null) {
      // Chưa từng lên server -> chỉ cần xóa cục bộ.
      await _calendars.deleteCalendarEvent(event.id);
      return;
    }
    final headers = await _authHeaders();
    final res = await _client.delete(
      _eventsUri(calendarId, eventId: event.googleEventId),
      headers: headers,
    );
    // 410 Gone = đã bị xóa từ trước -> coi như thành công.
    if (res.statusCode == 410 || (res.statusCode >= 200 && res.statusCode < 300)) {
      await _calendars.deleteCalendarEvent(event.id);
      return;
    }
    _ensureOk(res, 'xóa event');
  }

  // -------------------------------------------------------------------------
  // PULL: kéo event từ Google về DB cục bộ
  // -------------------------------------------------------------------------

  /// Kéo event từ [calendarId] về và upsert vào DB. [syncToken] cho đồng bộ
  /// tăng dần (null = đồng bộ đầy đủ trong cửa sổ [timeMin, timeMax]).
  /// [taskListId] để gắn các event mới kéo về vào một danh sách của app.
  Future<CalendarPullResult> pull(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
    String? taskListId,
  }) async {
    var upserted = 0;
    var deleted = 0;
    String? pageToken;
    String? nextSyncToken;

    do {
      final q = <String, String>{
        'singleEvents': 'true',
        'showDeleted': 'true',
        'maxResults': '250',
        if (pageToken != null) 'pageToken': pageToken,
        if (syncToken != null)
          'syncToken': syncToken
        else ...{
          if (timeMin != null) 'timeMin': timeMin.toUtc().toIso8601String(),
          if (timeMax != null) 'timeMax': timeMax.toUtc().toIso8601String(),
        },
      };

      final headers = await _authHeaders();
      final res = await _client.get(_eventsUri(calendarId, q: q), headers: headers);
      _ensureOk(res, 'đọc danh sách event');
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      final items = (body['items'] as List?) ?? const [];
      for (final raw in items) {
        final json = Map<String, dynamic>.from(raw as Map);
        final googleId = json['id'] as String?;
        if (googleId == null) continue;

        final existing = await _calendars.getEventByGoogleId(googleId);

        if (json['status'] == 'cancelled') {
          // Event đã bị xóa phía server -> xóa cục bộ nếu có.
          if (existing != null) {
            await _calendars.deleteCalendarEvent(existing.id);
            deleted++;
          }
          continue;
        }

        final merged = CalendarEvent.fromGoogleJson(
          json,
          localId: existing?.id,
          taskListId: existing?.taskListId ?? taskListId,
          calendarId: calendarId,
          color: existing?.color,
          syncStatus: EventSyncStatus.synced,
        );
        if (existing == null) {
          await _calendars.createCalendarEvent(merged);
        } else {
          await _calendars.updateCalendarEvent(merged);
        }
        upserted++;
      }

      pageToken = body['nextPageToken'] as String?;
      nextSyncToken = body['nextSyncToken'] as String? ?? nextSyncToken;
    } while (pageToken != null);

    return CalendarPullResult(
      upserted: upserted,
      deleted: deleted,
      nextSyncToken: nextSyncToken,
    );
  }

  /// Đồng bộ hai chiều một lần: đẩy thay đổi cục bộ trước rồi kéo về.
  Future<CalendarPullResult> syncTwoWay(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
    String? taskListId,
  }) async {
    await pushPending(calendarId);
    return pull(
      calendarId,
      syncToken: syncToken,
      timeMin: timeMin,
      timeMax: timeMax,
      taskListId: taskListId,
    );
  }

  void _ensureOk(http.Response res, String action) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw GoogleCalendarSyncException(
        'Lỗi khi $action: HTTP ${res.statusCode} — ${res.body}',
      );
    }
  }

  void dispose() => _client.close();
}

class GoogleCalendarSyncException implements Exception {
  const GoogleCalendarSyncException(this.message);
  final String message;

  @override
  String toString() => 'GoogleCalendarSyncException: $message';
}
