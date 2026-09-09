import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_repository.dart';
import 'google_calendar_sync_service.dart';

/// ---------------------------------------------------------------------------
/// QUẢN LÝ ĐỒNG BỘ LỊCH (điều phối cấp cao)
/// ---------------------------------------------------------------------------
/// Nối [AuthRepository.calendarAccessToken] (access token thật) với
/// [GoogleCalendarSyncService], đồng thời lưu/đọc cấu hình đồng bộ qua
/// SharedPreferences:
///   - bật/tắt đồng bộ,
///   - calendarId đang chọn (mặc định 'primary'),
///   - syncToken (cho đồng bộ tăng dần),
///   - taskListId để gắn event kéo về.
///
/// Tầng UI chỉ cần gọi [syncNow]; việc lấy token và lưu trạng thái do lớp này
/// lo. An toàn: mọi lỗi được nuốt và trả về [CalendarSyncOutcome] mô tả kết quả.
/// ---------------------------------------------------------------------------
class CalendarSyncManager {
  CalendarSyncManager({
    required this.authRepository,
    GoogleCalendarSyncService? googleService,
  }) {
    _google = googleService ??
        GoogleCalendarSyncService(
          accessTokenProvider: authRepository.calendarAccessToken,
        );
  }

  final AuthRepository authRepository;
  late final GoogleCalendarSyncService _google;

  static const _enabledKey = 'calendarSyncEnabled';
  static const _calendarIdKey = 'calendarSyncCalendarId';
  static const _taskListIdKey = 'calendarSyncTaskListId';
  static String _syncTokenKey(String calendarId) =>
      'calendarSyncToken_$calendarId';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isEnabled() async =>
      (await _prefs).getBool(_enabledKey) ?? false;

  Future<void> setEnabled(bool value) async =>
      (await _prefs).setBool(_enabledKey, value);

  /// calendarId đang chọn (mặc định 'primary' = lịch chính của tài khoản).
  Future<String> calendarId() async =>
      (await _prefs).getString(_calendarIdKey) ?? 'primary';

  Future<void> setCalendarId(String id) async =>
      (await _prefs).setString(_calendarIdKey, id);

  /// Danh sách nội bộ để gắn các event mới kéo về (null = không gắn).
  Future<String?> taskListId() async =>
      (await _prefs).getString(_taskListIdKey);

  Future<void> setTaskListId(String? id) async {
    final prefs = await _prefs;
    if (id == null) {
      await prefs.remove(_taskListIdKey);
    } else {
      await prefs.setString(_taskListIdKey, id);
    }
  }

  /// Đồng bộ hai chiều một lần với calendar đang chọn. Trả về kết quả.
  Future<CalendarSyncOutcome> syncNow() async {
    final prefs = await _prefs;
    final calId = prefs.getString(_calendarIdKey) ?? 'primary';
    final listId = prefs.getString(_taskListIdKey);
    final tokenKey = _syncTokenKey(calId);
    final savedToken = prefs.getString(tokenKey);

    try {
      final result = await _google.syncTwoWay(
        calId,
        syncToken: savedToken,
        // Nếu chưa có syncToken (lần đầu), giới hạn cửa sổ ±1 năm cho nhẹ.
        timeMin: savedToken == null
            ? DateTime.now().subtract(const Duration(days: 365))
            : null,
        timeMax: savedToken == null
            ? DateTime.now().add(const Duration(days: 365))
            : null,
        taskListId: listId,
      );
      if (result.nextSyncToken != null) {
        await prefs.setString(tokenKey, result.nextSyncToken!);
      }
      return CalendarSyncOutcome(
        success: true,
        upserted: result.upserted,
        deleted: result.deleted,
      );
    } on GoogleCalendarSyncException catch (e) {
      // syncToken hết hạn (HTTP 410) -> xóa token để lần sau đồng bộ đầy đủ.
      if (e.message.contains('410')) {
        await prefs.remove(tokenKey);
      }
      debugPrint('CalendarSyncManager.syncNow lỗi: ${e.message}');
      return CalendarSyncOutcome(success: false, error: e.message);
    } catch (e) {
      debugPrint('CalendarSyncManager.syncNow lỗi: $e');
      return CalendarSyncOutcome(success: false, error: e.toString());
    }
  }

  void dispose() => _google.dispose();
}

/// Kết quả của một lần đồng bộ (để UI hiển thị thông báo).
class CalendarSyncOutcome {
  const CalendarSyncOutcome({
    required this.success,
    this.upserted = 0,
    this.deleted = 0,
    this.error,
  });

  final bool success;
  final int upserted;
  final int deleted;
  final String? error;
}
