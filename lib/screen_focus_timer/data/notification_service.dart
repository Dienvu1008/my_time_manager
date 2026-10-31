import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../application/reminders/notification_scheduler.dart'
    show ReminderPermission;
import '../../application/reminders/reminder_ids.dart';
import '../../application/reminders/reminder_text.dart';
import '../../domain/models/model_time_interval.dart';

export '../../application/reminders/reminder_ids.dart'
    show kCommonReminderMinutes;

/// Dịch vụ thông báo khi hết giờ, xử lý khác nhau theo nền tảng:
///
/// - Mobile (Android/iOS): dùng flutter_local_notifications để hiện thông báo
///   hệ thống thật, hoạt động cả khi app ở nền.
/// - Desktop (Windows...): local notification hỗ trợ hạn chế, nên ta phát âm
///   thanh và để UI hiển thị dialog trong app (đáng tin cậy hơn).
///
/// Toàn bộ được bọc trong try/catch để lỗi thông báo không bao giờ làm hỏng
/// luồng chính của timer.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;

  /// Cờ bật/tắt nhắc toàn cục (đồng bộ từ cài đặt). Khi false, không lên lịch.
  bool _remindersEnabled = true;

  /// Cập nhật cờ bật/tắt nhắc toàn cục. Tắt -> hủy toàn bộ thông báo đã đặt.
  void setEnabled(bool enabled) {
    _remindersEnabled = enabled;
    if (!enabled) {
      cancelAll();
    }
  }

  /// Hủy toàn bộ thông báo đã lên lịch.
  Future<void> cancelAll() async {
    if (!_isMobile) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll lỗi: $e');
    }
  }

  /// True nếu nền tảng hiện tại là mobile (dùng notification hệ thống).
  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// True nếu là desktop (dùng âm thanh + dialog in-app).
  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Khởi tạo plugin. Gọi một lần khi app khởi động (trong main).
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Nạp cơ sở dữ liệu múi giờ và đặt múi giờ địa phương theo thiết bị, để
      // notification được lên lịch đúng giờ (zonedSchedule cần tz.local đúng).
      await _initTimezone();

      if (_isMobile) {
        const androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings();
        const settings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );
        await _plugin.initialize(settings);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init lỗi: $e');
    }
  }

  /// Nạp timezone database và đặt tz.local theo múi giờ thiết bị.
  Future<void> _initTimezone() async {
    try {
      tzdata.initializeTimeZones();
      // flutter_timezone >= 4 trả về TimezoneInfo; dùng .identifier (tên IANA).
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('Init timezone lỗi (dùng UTC): $e');
    }
  }

  /// Thông báo khi một khoảng (focus/break) kết thúc.
  ///
  /// [title] và [body] là nội dung tiếng Việt do bên gọi truyền vào.
  Future<void> notifyPhaseComplete({
    required String title,
    required String body,
  }) async {
    try {
      if (_isMobile) {
        await _showMobileNotification(title, body);
      } else if (isDesktop) {
        await _playSound();
      }
      // Trên desktop, UI sẽ tự hiện dialog (dựa vào state của bloc).
    } catch (e) {
      debugPrint('NotificationService.notifyPhaseComplete lỗi: $e');
    }
  }

  Future<void> _showMobileNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'focus_timer_channel',
      'Focus Timer',
      channelDescription: 'Thông báo khi phiên tập trung kết thúc',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(0, title, body, details);
  }

  /// Phát âm thanh báo (dùng cho desktop). File âm thanh nằm trong assets.
  /// Nếu chưa có file, lỗi được nuốt và bỏ qua (không ảnh hưởng timer).
  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      debugPrint('Không phát được âm thanh báo: $e');
    }
  }

  /// Xin quyền HIỂN THỊ THÔNG BÁO (Android 13+ / iOS). Đây là hộp thoại nhẹ,
  /// KHÔNG đưa người dùng rời khỏi app — an toàn để gọi lúc khởi động (sau khi
  /// UI đã render). KHÔNG bao gồm quyền báo thức chính xác (xem
  /// [requestExactAlarmPermission]).
  Future<void> requestNotificationPermission() async {
    if (!_isMobile) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('requestNotificationPermission lỗi: $e');
    }
  }

  /// Xin quyền ĐẶT BÁO THỨC CHÍNH XÁC (Android 12+). CẢNH BÁO: trên Android
  /// 12+, hàm này KHÔNG mở hộp thoại mà CHUYỂN sang màn Cài đặt hệ thống
  /// (Alarms & reminders), đưa app ra nền. Vì vậy chỉ nên gọi ĐÚNG LÚC người
  /// dùng chủ động bật/đặt nhắc, KHÔNG gọi lúc khởi động. No-op trên nền tảng
  /// khác Android hoặc khi đã có quyền.
  ///
  /// Trả về true nếu (sau lời gọi) quyền đã được cấp hoặc không cần xin.
  Future<bool> requestExactAlarmPermission() async {
    if (!_isMobile) return true;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      // Nếu đã có quyền thì không mở màn Cài đặt.
      final already = await android.canScheduleExactNotifications();
      if (already == true) return true;
      final granted = await android.requestExactAlarmsPermission();
      return granted ?? false;
    } catch (e) {
      debugPrint('requestExactAlarmPermission lỗi: $e');
      return false;
    }
  }

  // ------------------------------------------------------------------
  // NHẮC CÓ LỊCH (scheduled notifications) cho time interval
  // ------------------------------------------------------------------

  /// Chi tiết thông báo cho các mốc nhắc time interval.
  NotificationDetails _reminderDetails() {
    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Nhắc lịch',
      channelDescription: 'Thông báo nhắc trước khi công việc/sự kiện bắt đầu',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Lên lịch một thông báo tại thời điểm [when] (giờ địa phương). Nếu thời
  /// điểm đã ở quá khứ thì bỏ qua. An toàn trên desktop (không làm gì).
  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_isMobile) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('zonedSchedule lỗi: $e');
    }
  }

  /// Hủy một thông báo theo id.
  Future<void> _cancel(int id) async {
    if (!_isMobile) return;
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('cancel notification lỗi: $e');
    }
  }

  // ------------------------------------------------------------------
  // PRIMITIVES cho ReminderCoordinator (Phase R) — dùng qua
  // LocalNotificationScheduler. Không kiểm tra _remindersEnabled (bridge
  // quản lý bật/tắt) và KHÔNG mở màn Cài đặt báo thức chính xác. Khác các
  // hàm legacy, schedule/cancel ở đây KHÔNG nuốt lỗi: coordinator tự bắt,
  // đếm lỗi và giữ snapshot để thử lại (D8).
  // ------------------------------------------------------------------

  /// Lên lịch một nhắc với [id] cố định tại thời điểm tuyệt đối [fireAtUtc].
  /// Bỏ qua nếu đã ở quá khứ hoặc không phải mobile. Dùng báo thức chính xác
  /// khi Android cho phép, ngược lại dùng chế độ không chính xác.
  Future<void> scheduleReminderAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAtUtc,
  }) async {
    if (!_isMobile) return;
    final when = tz.TZDateTime.from(fireAtUtc, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    // Android: chỉ dùng exact khi chắc chắn được phép (lỗi -> inexact).
    final exact = !Platform.isAndroid || await _probeExactAlarms() == true;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _reminderDetails(),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Hủy một nhắc theo id (ném lỗi nếu plugin lỗi).
  Future<void> cancelReminder(int id) async {
    if (!_isMobile) return;
    await _plugin.cancel(id);
  }

  /// Hủy toàn bộ thông báo đã đặt (ném lỗi nếu plugin lỗi).
  Future<void> cancelAllReminders() async {
    if (!_isMobile) return;
    await _plugin.cancelAll();
  }

  /// true nếu được đặt báo thức chính xác (Android 12+ cần quyền
  /// SCHEDULE_EXACT_ALARM). Nền tảng khác hoặc lỗi -> true (không áp dụng).
  Future<bool> canScheduleExactReminders() async {
    if (!_isMobile || !Platform.isAndroid) return true;
    return await _probeExactAlarms() ?? true;
  }

  /// Android `canScheduleExactNotifications()`; null nếu không xác định / lỗi.
  Future<bool?> _probeExactAlarms() async {
    try {
      return await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
    } catch (e) {
      debugPrint('canScheduleExactNotifications lỗi: $e');
      return null;
    }
  }

  /// Trạng thái quyền hiển thị thông báo. Desktop/web hoặc lỗi ->
  /// [ReminderPermission.notApplicable].
  Future<ReminderPermission> reminderPermissionStatus() async {
    if (!_isMobile) return ReminderPermission.notApplicable;
    try {
      bool? enabled;
      if (Platform.isAndroid) {
        enabled = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
      } else if (Platform.isIOS) {
        final options = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.checkPermissions();
        enabled = options?.isEnabled;
      }
      if (enabled == null) return ReminderPermission.notApplicable;
      return enabled ? ReminderPermission.granted : ReminderPermission.denied;
    } catch (e) {
      debugPrint('reminderPermissionStatus lỗi: $e');
      return ReminderPermission.notApplicable;
    }
  }

  /// Sinh notificationId ổn định (deterministic) từ id của interval và số phút
  /// nhắc. Cùng interval + cùng mốc luôn ra cùng id -> ghi đè/hủy chính xác.
  int _notificationId(String intervalId, int minutesBefore) {
    // 31-bit dương để nằm trong phạm vi int của Android.
    return legacyIntervalReminderId(intervalId, minutesBefore);
  }

  /// Lên lịch tất cả các mốc nhắc cho một [timeInterval].
  ///
  /// Mốc nhắc = thời điểm bắt đầu - (số phút trước). Bỏ qua nếu interval chưa
  /// có thời điểm bắt đầu xác định, hoặc mốc đã ở quá khứ.
  Future<void> scheduleForTimeInterval(TimeInterval timeInterval) async {
    if (!_isMobile) return;
    if (!_remindersEnabled) return;
    if (timeInterval.reminderMinutesBefore.isEmpty) return;

    final startMillis = timeInterval.startTimestamp;
    if (startMillis == null) return;
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);

    // Hủy các mốc cũ trước khi đặt lại (tránh trùng khi cập nhật).
    await cancelForTimeInterval(timeInterval);

    final title = timeInterval.title.isNotEmpty
        ? timeInterval.title
        : 'Sắp đến giờ';

    // Đảm bảo có quyền báo thức chính xác trước khi zonedSchedule (Android 12+).
    // Gọi ở đây — đúng lúc người dùng thực sự đặt nhắc — nên nếu có mở màn Cài
    // đặt hệ thống thì cũng là hành động họ chủ động, không phải lúc khởi động.
    // Đã có quyền -> no-op (không mở Cài đặt). Không chặn: nếu người dùng từ
    // chối, plugin vẫn cố lên lịch (có thể kém chính xác) thay vì bỏ hẳn.
    await requestExactAlarmPermission();

    for (final minutes in timeInterval.reminderMinutesBefore.toSet()) {
      final when = start.subtract(Duration(minutes: minutes));
      final body = _reminderBody(minutes, start);
      await _scheduleAt(
        id: _notificationId(timeInterval.id, minutes),
        title: title,
        body: body,
        when: when,
      );
    }
  }

  String _reminderBody(int minutes, DateTime start) =>
      ReminderText.offsetBody(minutes, start.hour, start.minute);

  /// Hủy tất cả các mốc nhắc của một [timeInterval] (dùng khi sửa/xóa).
  Future<void> cancelForTimeInterval(TimeInterval timeInterval) async {
    if (!_isMobile) return;
    // Hủy theo mọi mốc phổ biến + các mốc hiện có, để dọn cả cấu hình cũ.
    final candidates = {
      ...timeInterval.reminderMinutesBefore,
      ...kCommonReminderMinutes,
    };
    for (final minutes in candidates) {
      await _cancel(_notificationId(timeInterval.id, minutes));
    }
  }

  /// Hủy nhắc theo id interval khi CHỈ biết id (ví dụ lúc xóa). Hủy tất cả các
  /// mốc phổ biến để dọn sạch.
  Future<void> cancelForTimeIntervalId(String intervalId) async {
    if (!_isMobile) return;
    for (final minutes in kCommonReminderMinutes) {
      await _cancel(_notificationId(intervalId, minutes));
    }
  }
}
