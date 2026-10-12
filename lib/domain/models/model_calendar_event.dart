import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// ---------------------------------------------------------------------------
/// MODEL SỰ KIỆN LỊCH (CalendarEvent)
/// ---------------------------------------------------------------------------
/// Được thiết kế theo cấu trúc "Events resource" của Google Calendar API v3 và
/// tương thích với chuẩn iCalendar (RFC 5545), để có thể đồng bộ hai chiều với
/// Google Calendar, lịch thiết bị (device_calendar) hoặc bất kỳ lịch nào nói
/// chuẩn iCal.
///
/// Tham chiếu trường:
///   https://developers.google.com/calendar/api/v3/reference/events
///
/// Nguyên tắc thiết kế:
///   - Mỗi trường Google Calendar quan trọng đều có trường tương ứng ở đây.
///   - Thời gian dùng [EventDateTime] để phân biệt sự kiện có giờ (dateTime)
///     với sự kiện cả ngày (date), kèm múi giờ (timeZone) — đúng cách Google
///     biểu diễn start/end.
///   - Lặp lại (recurrence) giữ nguyên danh sách chuỗi RRULE/RDATE/EXDATE để
///     không mất thông tin khi round-trip.
///   - Các trường phục vụ đồng bộ (googleEventId, iCalUID, etag, sequence,
///     recurringEventId, syncStatus) tách khỏi nội dung hiển thị.
/// ---------------------------------------------------------------------------

/// Trạng thái của sự kiện (Google: `status`).
enum EventStatus {
  confirmed,
  tentative,
  cancelled;

  String get apiValue => name;

  static EventStatus fromApi(String? value) {
    switch (value) {
      case 'tentative':
        return EventStatus.tentative;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'confirmed':
      default:
        return EventStatus.confirmed;
    }
  }
}

/// Mức hiển thị của sự kiện với người khác (Google: `visibility`).
enum EventVisibility {
  defaultVisibility,
  public,
  private,
  confidential;

  /// Google dùng chuỗi 'default' cho giá trị mặc định.
  String get apiValue =>
      this == EventVisibility.defaultVisibility ? 'default' : name;

  static EventVisibility fromApi(String? value) {
    switch (value) {
      case 'public':
        return EventVisibility.public;
      case 'private':
        return EventVisibility.private;
      case 'confidential':
        return EventVisibility.confidential;
      case 'default':
      default:
        return EventVisibility.defaultVisibility;
    }
  }
}

/// Sự kiện có chiếm chỗ (bận) trên lịch hay không (Google: `transparency`).
///  - opaque  = bận (mặc định).
///  - transparent = rảnh (không chiếm chỗ).
enum EventTransparency {
  opaque,
  transparent;

  String get apiValue => name;

  static EventTransparency fromApi(String? value) {
    return value == 'transparent'
        ? EventTransparency.transparent
        : EventTransparency.opaque;
  }
}

/// Trạng thái phản hồi của người tham dự (Google: attendee `responseStatus`).
enum AttendeeResponseStatus {
  needsAction,
  declined,
  tentative,
  accepted;

  String get apiValue {
    switch (this) {
      case AttendeeResponseStatus.needsAction:
        return 'needsAction';
      case AttendeeResponseStatus.declined:
        return 'declined';
      case AttendeeResponseStatus.tentative:
        return 'tentative';
      case AttendeeResponseStatus.accepted:
        return 'accepted';
    }
  }

  static AttendeeResponseStatus fromApi(String? value) {
    switch (value) {
      case 'declined':
        return AttendeeResponseStatus.declined;
      case 'tentative':
        return AttendeeResponseStatus.tentative;
      case 'accepted':
        return AttendeeResponseStatus.accepted;
      case 'needsAction':
      default:
        return AttendeeResponseStatus.needsAction;
    }
  }
}

/// Phương thức nhắc (Google: reminder override `method`).
enum ReminderMethod {
  popup,
  email;

  String get apiValue => name;

  static ReminderMethod fromApi(String? value) {
    return value == 'email' ? ReminderMethod.email : ReminderMethod.popup;
  }
}

/// Trạng thái đồng bộ cục bộ (KHÔNG thuộc Google API) — giúp lớp sync biết bản
/// ghi nào cần đẩy lên/xóa.
enum EventSyncStatus {
  /// Chỉ tồn tại cục bộ, chưa đẩy lên máy chủ.
  localOnly,

  /// Đã đồng bộ, khớp với máy chủ.
  synced,

  /// Đã sửa cục bộ, cần đẩy thay đổi lên.
  pendingUpdate,

  /// Đã đánh dấu xóa cục bộ, cần xóa trên máy chủ.
  pendingDelete;

  String get apiValue => name;

  static EventSyncStatus fromName(String? value) {
    return EventSyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventSyncStatus.localOnly,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Thời điểm bắt đầu/kết thúc của sự kiện (Google: `start` / `end`).
///
/// Google biểu diễn theo MỘT trong hai cách:
///   - Sự kiện có giờ:  { "dateTime": "2026-08-29T09:00:00+07:00",
///                        "timeZone": "Asia/Ho_Chi_Minh" }
///   - Sự kiện cả ngày: { "date": "2026-08-29" }
/// [isAllDay] true khi chỉ có [date]. Với sự kiện cả ngày, theo chuẩn iCal,
/// [date] của `end` là ngày SAU ngày cuối (exclusive).
/// ---------------------------------------------------------------------------
class EventDateTime extends Equatable {
  /// Thời điểm chính xác (dùng cho sự kiện có giờ). Null nếu là cả ngày.
  final DateTime? dateTime;

  /// Ngày (chỉ ngày, không giờ) cho sự kiện cả ngày. Null nếu có giờ.
  final DateTime? date;

  /// Tên múi giờ IANA, ví dụ 'Asia/Ho_Chi_Minh'. Có thể null.
  final String? timeZone;

  const EventDateTime({this.dateTime, this.date, this.timeZone})
      : assert(dateTime != null || date != null,
            'EventDateTime cần dateTime hoặc date');

  bool get isAllDay => dateTime == null && date != null;

  /// Trả về một DateTime dùng để so sánh/hiển thị (ưu tiên dateTime).
  DateTime get effective => dateTime ?? date!;

  EventDateTime copyWith({
    DateTime? dateTime,
    DateTime? date,
    String? timeZone,
    bool clearDateTime = false,
    bool clearDate = false,
  }) {
    return EventDateTime(
      dateTime: clearDateTime ? null : (dateTime ?? this.dateTime),
      date: clearDate ? null : (date ?? this.date),
      timeZone: timeZone ?? this.timeZone,
    );
  }

  /// Chỉ ngày dạng 'YYYY-MM-DD' (dùng cho trường `date` của Google).
  static String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Map<String, dynamic> toGoogleJson() {
    final map = <String, dynamic>{};
    if (isAllDay) {
      map['date'] = _formatDate(date!);
    } else {
      map['dateTime'] = dateTime!.toIso8601String();
    }
    if (timeZone != null) map['timeZone'] = timeZone;
    return map;
  }

  factory EventDateTime.fromGoogleJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final dateTimeStr = json['dateTime'] as String?;
    return EventDateTime(
      dateTime: dateTimeStr != null ? DateTime.parse(dateTimeStr) : null,
      date: dateStr != null ? DateTime.parse(dateStr) : null,
      timeZone: json['timeZone'] as String?,
    );
  }

  /// Dạng map "phẳng" để lưu vào một cột SQLite (được jsonEncode ở tầng trên).
  Map<String, dynamic> toMap() => {
        'dateTime': dateTime?.toIso8601String(),
        'date': date != null ? _formatDate(date!) : null,
        'timeZone': timeZone,
      };

  factory EventDateTime.fromMap(Map<String, dynamic> map) {
    final dt = map['dateTime'] as String?;
    final d = map['date'] as String?;
    return EventDateTime(
      dateTime: dt != null ? DateTime.parse(dt) : null,
      date: d != null ? DateTime.parse(d) : null,
      timeZone: map['timeZone'] as String?,
    );
  }

  @override
  List<Object?> get props => [dateTime, date, timeZone];
}

/// Một người tham dự (Google: phần tử của `attendees`).
class EventAttendee extends Equatable {
  final String email;
  final String? displayName;

  /// Người tham dự này có phải là người tổ chức không.
  final bool organizer;

  /// Tùy chọn (không bắt buộc tham dự).
  final bool optional;

  /// Là tài nguyên (phòng họp, thiết bị) thay vì người.
  final bool resource;

  final AttendeeResponseStatus responseStatus;

  /// Ghi chú/nhận xét của người tham dự.
  final String? comment;

  const EventAttendee({
    required this.email,
    this.displayName,
    this.organizer = false,
    this.optional = false,
    this.resource = false,
    this.responseStatus = AttendeeResponseStatus.needsAction,
    this.comment,
  });

  EventAttendee copyWith({
    String? email,
    String? displayName,
    bool? organizer,
    bool? optional,
    bool? resource,
    AttendeeResponseStatus? responseStatus,
    String? comment,
  }) {
    return EventAttendee(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      organizer: organizer ?? this.organizer,
      optional: optional ?? this.optional,
      resource: resource ?? this.resource,
      responseStatus: responseStatus ?? this.responseStatus,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toGoogleJson() => {
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (organizer) 'organizer': true,
        if (optional) 'optional': true,
        if (resource) 'resource': true,
        'responseStatus': responseStatus.apiValue,
        if (comment != null) 'comment': comment,
      };

  factory EventAttendee.fromGoogleJson(Map<String, dynamic> json) {
    return EventAttendee(
      email: (json['email'] as String?) ?? '',
      displayName: json['displayName'] as String?,
      organizer: json['organizer'] as bool? ?? false,
      optional: json['optional'] as bool? ?? false,
      resource: json['resource'] as bool? ?? false,
      responseStatus:
          AttendeeResponseStatus.fromApi(json['responseStatus'] as String?),
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() => toGoogleJson();
  factory EventAttendee.fromMap(Map<String, dynamic> map) =>
      EventAttendee.fromGoogleJson(map);

  @override
  List<Object?> get props =>
      [email, displayName, organizer, optional, resource, responseStatus];
}

/// Một mốc nhắc tùy chỉnh (Google: phần tử của `reminders.overrides`).
class EventReminderOverride extends Equatable {
  final ReminderMethod method;

  /// Số phút trước khi sự kiện bắt đầu.
  final int minutes;

  const EventReminderOverride({required this.method, required this.minutes});

  EventReminderOverride copyWith({ReminderMethod? method, int? minutes}) {
    return EventReminderOverride(
      method: method ?? this.method,
      minutes: minutes ?? this.minutes,
    );
  }

  Map<String, dynamic> toGoogleJson() =>
      {'method': method.apiValue, 'minutes': minutes};

  factory EventReminderOverride.fromGoogleJson(Map<String, dynamic> json) {
    return EventReminderOverride(
      method: ReminderMethod.fromApi(json['method'] as String?),
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [method, minutes];
}

/// Cấu hình nhắc của sự kiện (Google: `reminders`).
///  - [useDefault] true: dùng cấu hình nhắc mặc định của lịch (bỏ qua overrides).
///  - [useDefault] false: dùng danh sách [overrides].
class EventReminders extends Equatable {
  final bool useDefault;
  final List<EventReminderOverride> overrides;

  const EventReminders({this.useDefault = true, this.overrides = const []});

  EventReminders copyWith({
    bool? useDefault,
    List<EventReminderOverride>? overrides,
  }) {
    return EventReminders(
      useDefault: useDefault ?? this.useDefault,
      overrides: overrides ?? this.overrides,
    );
  }

  Map<String, dynamic> toGoogleJson() => {
        'useDefault': useDefault,
        if (overrides.isNotEmpty)
          'overrides': overrides.map((o) => o.toGoogleJson()).toList(),
      };

  factory EventReminders.fromGoogleJson(Map<String, dynamic> json) {
    final list = (json['overrides'] as List?)
            ?.map((e) =>
                EventReminderOverride.fromGoogleJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <EventReminderOverride>[];
    return EventReminders(
      useDefault: json['useDefault'] as bool? ?? true,
      overrides: list,
    );
  }

  @override
  List<Object?> get props => [useDefault, overrides];
}

/// ---------------------------------------------------------------------------
/// SỰ KIỆN LỊCH đầy đủ.
/// ---------------------------------------------------------------------------
class CalendarEvent extends Equatable {
  // --- Định danh & liên kết ---

  /// Id cục bộ (khóa chính trong app). Luôn có.
  final String id;

  /// Danh sách/nhóm nội bộ của app mà sự kiện thuộc về (có thể null nếu thuần
  /// là sự kiện đồng bộ từ lịch ngoài).
  final String? taskListId;

  // --- Nội dung (Google) ---

  /// Google: `summary`.
  final String title;

  /// Google: `description` (có thể chứa HTML nhẹ).
  final String description;

  /// Google: `location`.
  final String location;

  /// Màu hiển thị trong app. Google dùng `colorId` (chuỗi id trong bảng màu);
  /// ta lưu song song [color] (để vẽ) và [colorId] (để round-trip với Google).
  final Color color;
  final String? colorId;

  // --- Thời gian ---

  /// Google: `start`.
  final EventDateTime start;

  /// Google: `end`.
  final EventDateTime end;

  bool get isAllDay => start.isAllDay;

  // --- Lặp lại (recurrence) ---

  /// Google: `recurrence` — danh sách chuỗi RRULE/RDATE/EXDATE (RFC 5545),
  /// ví dụ: 'RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR'. Rỗng nếu không lặp.
  final List<String> recurrence;

  /// Google: `recurringEventId` — id của sự kiện lặp gốc, nếu đây là một lần
  /// xuất hiện (instance) đã được tách riêng.
  final String? recurringEventId;

  /// Google: `originalStartTime` — thời điểm bắt đầu gốc của instance lặp.
  final EventDateTime? originalStartTime;

  // --- Người liên quan ---

  /// Google: `attendees`.
  final List<EventAttendee> attendees;

  /// Google: `organizer` (email người tổ chức).
  final String? organizerEmail;
  final String? organizerDisplayName;

  /// Google: `creator` (email người tạo).
  final String? creatorEmail;

  // --- Trạng thái & quyền ---

  /// Google: `status`.
  final EventStatus status;

  /// Google: `visibility`.
  final EventVisibility visibility;

  /// Google: `transparency` (bận/rảnh).
  final EventTransparency transparency;

  /// Google: `guestsCanInviteOthers`.
  final bool guestsCanInviteOthers;

  /// Google: `guestsCanModify`.
  final bool guestsCanModify;

  /// Google: `guestsCanSeeOtherGuests`.
  final bool guestsCanSeeOtherGuests;

  // --- Nhắc ---

  /// Google: `reminders`.
  final EventReminders reminders;

  // --- Hội nghị/liên kết ---

  /// Google: `hangoutLink` hoặc link cuộc họp trong `conferenceData`.
  final String? conferenceUrl;

  // --- Tài liệu đính kèm nội bộ của app ---
  final List<String> dataFiles;

  /// Id các ghi chú đính kèm (dùng chung cơ chế note của app).
  final List<String> noteIds;

  // --- Metadata & đồng bộ ---

  /// Google: `iCalUID` — id toàn cục theo chuẩn iCal (bền vững qua các lịch).
  final String? iCalUID;

  /// Id của sự kiện trên Google Calendar (khác với [id] cục bộ).
  final String? googleEventId;

  /// Id của lịch (calendarId) trên máy chủ mà sự kiện thuộc về.
  final String? calendarId;

  /// Google: `etag` — dùng để phát hiện thay đổi/khóa lạc quan khi ghi.
  final String? etag;

  /// Google: `sequence` — số thứ tự phiên bản (tăng mỗi lần sửa lớn).
  final int sequence;

  /// Google: `created`.
  final DateTime? created;

  /// Google: `updated`. Đồng thời là dấu thời gian cập nhật cục bộ.
  final DateTime updated;

  /// Trạng thái đồng bộ cục bộ.
  final EventSyncStatus syncStatus;

  CalendarEvent({
    String? id,
    this.taskListId,
    required this.title,
    String? description,
    String? location,
    Color? color,
    this.colorId,
    required this.start,
    required this.end,
    List<String>? recurrence,
    this.recurringEventId,
    this.originalStartTime,
    List<EventAttendee>? attendees,
    this.organizerEmail,
    this.organizerDisplayName,
    this.creatorEmail,
    this.status = EventStatus.confirmed,
    this.visibility = EventVisibility.defaultVisibility,
    this.transparency = EventTransparency.opaque,
    this.guestsCanInviteOthers = true,
    this.guestsCanModify = false,
    this.guestsCanSeeOtherGuests = true,
    EventReminders? reminders,
    this.conferenceUrl,
    List<String>? dataFiles,
    List<String>? noteIds,
    this.iCalUID,
    this.googleEventId,
    this.calendarId,
    this.etag,
    this.sequence = 0,
    this.created,
    DateTime? updated,
    this.syncStatus = EventSyncStatus.localOnly,
  })  : assert(id == null || id.isNotEmpty, 'id không được rỗng'),
        id = id ?? const Uuid().v4(),
        description = description ?? '',
        location = location ?? '',
        color = color ?? Colors.blue,
        recurrence = recurrence ?? const [],
        attendees = attendees ?? const [],
        reminders = reminders ?? const EventReminders(),
        dataFiles = dataFiles ?? const [],
        noteIds = noteIds ?? const [],
        updated = updated ?? DateTime.now();

  bool get isRecurring => recurrence.isNotEmpty;

  CalendarEvent copyWith({
    String? id,
    String? taskListId,
    String? title,
    String? description,
    String? location,
    Color? color,
    String? colorId,
    EventDateTime? start,
    EventDateTime? end,
    List<String>? recurrence,
    String? recurringEventId,
    EventDateTime? originalStartTime,
    List<EventAttendee>? attendees,
    String? organizerEmail,
    String? organizerDisplayName,
    String? creatorEmail,
    EventStatus? status,
    EventVisibility? visibility,
    EventTransparency? transparency,
    bool? guestsCanInviteOthers,
    bool? guestsCanModify,
    bool? guestsCanSeeOtherGuests,
    EventReminders? reminders,
    String? conferenceUrl,
    List<String>? dataFiles,
    List<String>? noteIds,
    String? iCalUID,
    String? googleEventId,
    String? calendarId,
    String? etag,
    int? sequence,
    DateTime? created,
    DateTime? updated,
    EventSyncStatus? syncStatus,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      taskListId: taskListId ?? this.taskListId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      color: color ?? this.color,
      colorId: colorId ?? this.colorId,
      start: start ?? this.start,
      end: end ?? this.end,
      recurrence: recurrence ?? this.recurrence,
      recurringEventId: recurringEventId ?? this.recurringEventId,
      originalStartTime: originalStartTime ?? this.originalStartTime,
      attendees: attendees ?? this.attendees,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerDisplayName: organizerDisplayName ?? this.organizerDisplayName,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      transparency: transparency ?? this.transparency,
      guestsCanInviteOthers:
          guestsCanInviteOthers ?? this.guestsCanInviteOthers,
      guestsCanModify: guestsCanModify ?? this.guestsCanModify,
      guestsCanSeeOtherGuests:
          guestsCanSeeOtherGuests ?? this.guestsCanSeeOtherGuests,
      reminders: reminders ?? this.reminders,
      conferenceUrl: conferenceUrl ?? this.conferenceUrl,
      dataFiles: dataFiles ?? this.dataFiles,
      noteIds: noteIds ?? this.noteIds,
      iCalUID: iCalUID ?? this.iCalUID,
      googleEventId: googleEventId ?? this.googleEventId,
      calendarId: calendarId ?? this.calendarId,
      etag: etag ?? this.etag,
      sequence: sequence ?? this.sequence,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // -------------------------------------------------------------------------
  // GOOGLE CALENDAR API (Events resource) JSON
  // -------------------------------------------------------------------------

  /// Chuyển sang JSON đúng định dạng body của Google Calendar API. Chỉ gồm các
  /// trường Google hiểu (bỏ các trường nội bộ như id cục bộ, dataFiles...).
  Map<String, dynamic> toGoogleJson() {
    final map = <String, dynamic>{
      if (googleEventId != null) 'id': googleEventId,
      'summary': title,
      if (description.isNotEmpty) 'description': description,
      if (location.isNotEmpty) 'location': location,
      if (colorId != null) 'colorId': colorId,
      'start': start.toGoogleJson(),
      'end': end.toGoogleJson(),
      if (recurrence.isNotEmpty) 'recurrence': recurrence,
      if (recurringEventId != null) 'recurringEventId': recurringEventId,
      if (originalStartTime != null)
        'originalStartTime': originalStartTime!.toGoogleJson(),
      if (attendees.isNotEmpty)
        'attendees': attendees.map((a) => a.toGoogleJson()).toList(),
      'status': status.apiValue,
      'visibility': visibility.apiValue,
      'transparency': transparency.apiValue,
      'guestsCanInviteOthers': guestsCanInviteOthers,
      'guestsCanModify': guestsCanModify,
      'guestsCanSeeOtherGuests': guestsCanSeeOtherGuests,
      'reminders': reminders.toGoogleJson(),
      if (iCalUID != null) 'iCalUID': iCalUID,
      'sequence': sequence,
    };

    final organizer = <String, dynamic>{
      if (organizerEmail != null) 'email': organizerEmail,
      if (organizerDisplayName != null) 'displayName': organizerDisplayName,
    };
    if (organizer.isNotEmpty) map['organizer'] = organizer;
    if (creatorEmail != null) map['creator'] = {'email': creatorEmail};
    return map;
  }

  /// Dựng từ JSON của Google Calendar API. [localId]/[taskListId] cho phép gắn
  /// vào bản ghi cục bộ khi kéo dữ liệu về.
  factory CalendarEvent.fromGoogleJson(
    Map<String, dynamic> json, {
    String? localId,
    String? taskListId,
    String? calendarId,
    Color? color,
    EventSyncStatus syncStatus = EventSyncStatus.synced,
  }) {
    final organizer = json['organizer'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    return CalendarEvent(
      id: localId,
      taskListId: taskListId,
      title: (json['summary'] as String?) ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      color: color,
      colorId: json['colorId'] as String?,
      start: EventDateTime.fromGoogleJson(
          Map<String, dynamic>.from(json['start'] as Map)),
      end: EventDateTime.fromGoogleJson(
          Map<String, dynamic>.from(json['end'] as Map)),
      recurrence: (json['recurrence'] as List?)?.cast<String>().toList(),
      recurringEventId: json['recurringEventId'] as String?,
      originalStartTime: json['originalStartTime'] != null
          ? EventDateTime.fromGoogleJson(
              Map<String, dynamic>.from(json['originalStartTime'] as Map))
          : null,
      attendees: (json['attendees'] as List?)
          ?.map((e) =>
              EventAttendee.fromGoogleJson(Map<String, dynamic>.from(e)))
          .toList(),
      organizerEmail: organizer?['email'] as String?,
      organizerDisplayName: organizer?['displayName'] as String?,
      creatorEmail: creator?['email'] as String?,
      status: EventStatus.fromApi(json['status'] as String?),
      visibility: EventVisibility.fromApi(json['visibility'] as String?),
      transparency: EventTransparency.fromApi(json['transparency'] as String?),
      guestsCanInviteOthers: json['guestsCanInviteOthers'] as bool? ?? true,
      guestsCanModify: json['guestsCanModify'] as bool? ?? false,
      guestsCanSeeOtherGuests: json['guestsCanSeeOtherGuests'] as bool? ?? true,
      reminders: json['reminders'] != null
          ? EventReminders.fromGoogleJson(
              Map<String, dynamic>.from(json['reminders'] as Map))
          : null,
      conferenceUrl: json['hangoutLink'] as String?,
      iCalUID: json['iCalUID'] as String?,
      googleEventId: json['id'] as String?,
      calendarId: calendarId,
      etag: json['etag'] as String?,
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      created: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.tryParse(json['updated'] as String)
          : null,
      syncStatus: syncStatus,
    );
  }

  // -------------------------------------------------------------------------
  // SQLite (bảng calendar_events) — object lồng được jsonEncode thành chuỗi.
  // -------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'description': description,
      'location': location,
      'color': color.value,
      'colorId': colorId,
      'startDateTime': jsonEncode(start.toMap()),
      'endDateTime': jsonEncode(end.toMap()),
      'isAllDay': isAllDay ? 1 : 0,
      'recurrence': jsonEncode(recurrence),
      'recurringEventId': recurringEventId,
      'originalStartTime':
          originalStartTime != null ? jsonEncode(originalStartTime!.toMap()) : null,
      'attendees': jsonEncode(attendees.map((a) => a.toMap()).toList()),
      'organizerEmail': organizerEmail,
      'organizerDisplayName': organizerDisplayName,
      'creatorEmail': creatorEmail,
      'status': status.apiValue,
      'visibility': visibility.apiValue,
      'transparency': transparency.apiValue,
      'guestsCanInviteOthers': guestsCanInviteOthers ? 1 : 0,
      'guestsCanModify': guestsCanModify ? 1 : 0,
      'guestsCanSeeOtherGuests': guestsCanSeeOtherGuests ? 1 : 0,
      'reminders': jsonEncode(reminders.toGoogleJson()),
      'conferenceUrl': conferenceUrl,
      'dataFiles': jsonEncode(dataFiles),
      'noteIds': jsonEncode(noteIds),
      'iCalUID': iCalUID,
      'googleEventId': googleEventId,
      'calendarId': calendarId,
      'etag': etag,
      'sequence': sequence,
      'created': created?.toIso8601String(),
      'updated': updated.toIso8601String(),
      'syncStatus': syncStatus.apiValue,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    List<String> decodeStringList(dynamic v) {
      if (v == null) return const [];
      final decoded = jsonDecode(v as String);
      return List<String>.from(decoded as List);
    }

    return CalendarEvent(
      id: map['id'] as String?,
      taskListId: map['taskListId'] as String?,
      title: (map['title'] as String?) ?? '',
      description: map['description'] as String?,
      location: map['location'] as String?,
      color: map['color'] != null ? Color(map['color'] as int) : null,
      colorId: map['colorId'] as String?,
      start: EventDateTime.fromMap(
          Map<String, dynamic>.from(jsonDecode(map['startDateTime'] as String))),
      end: EventDateTime.fromMap(
          Map<String, dynamic>.from(jsonDecode(map['endDateTime'] as String))),
      recurrence: decodeStringList(map['recurrence']),
      recurringEventId: map['recurringEventId'] as String?,
      originalStartTime: map['originalStartTime'] != null
          ? EventDateTime.fromMap(Map<String, dynamic>.from(
              jsonDecode(map['originalStartTime'] as String)))
          : null,
      attendees: (jsonDecode((map['attendees'] as String?) ?? '[]') as List)
          .map((e) => EventAttendee.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      organizerEmail: map['organizerEmail'] as String?,
      organizerDisplayName: map['organizerDisplayName'] as String?,
      creatorEmail: map['creatorEmail'] as String?,
      status: EventStatus.fromApi(map['status'] as String?),
      visibility: EventVisibility.fromApi(map['visibility'] as String?),
      transparency: EventTransparency.fromApi(map['transparency'] as String?),
      guestsCanInviteOthers: (map['guestsCanInviteOthers'] as int?) != 0,
      guestsCanModify: (map['guestsCanModify'] as int?) == 1,
      guestsCanSeeOtherGuests: (map['guestsCanSeeOtherGuests'] as int?) != 0,
      reminders: map['reminders'] != null
          ? EventReminders.fromGoogleJson(Map<String, dynamic>.from(
              jsonDecode(map['reminders'] as String)))
          : null,
      conferenceUrl: map['conferenceUrl'] as String?,
      dataFiles: decodeStringList(map['dataFiles']),
      noteIds: decodeStringList(map['noteIds']),
      iCalUID: map['iCalUID'] as String?,
      googleEventId: map['googleEventId'] as String?,
      calendarId: map['calendarId'] as String?,
      etag: map['etag'] as String?,
      sequence: (map['sequence'] as int?) ?? 0,
      created: map['created'] != null
          ? DateTime.tryParse(map['created'] as String)
          : null,
      updated: map['updated'] != null
          ? DateTime.parse(map['updated'] as String)
          : null,
      syncStatus: EventSyncStatus.fromName(map['syncStatus'] as String?),
    );
  }

  String toJson() => json.encode(toMap());
  factory CalendarEvent.fromJson(String source) =>
      CalendarEvent.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, start: ${start.effective}, '
      'recurring: $isRecurring, sync: ${syncStatus.name})';

  @override
  List<Object?> get props => [
        id,
        taskListId,
        title,
        description,
        location,
        color,
        colorId,
        start,
        end,
        recurrence,
        recurringEventId,
        originalStartTime,
        attendees,
        organizerEmail,
        status,
        visibility,
        transparency,
        reminders,
        iCalUID,
        googleEventId,
        calendarId,
        etag,
        sequence,
        updated,
        syncStatus,
      ];
}
