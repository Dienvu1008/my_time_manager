// Nội dung thông báo nhắc (Phase R, plan D13). Tiếng Việt, chưa bản địa hóa
// (giữ nguyên chuỗi legacy).

class ReminderText {
  ReminderText._();

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Tiêu đề: tên mục hoặc 'Sắp đến giờ' khi rỗng.
  static String titleOr(String title) =>
      title.isNotEmpty ? title : 'Sắp đến giờ';

  /// Nội dung mốc nhắc lệch [minutes] phút trước thời điểm bắt đầu
  /// [hour]:[minute] (giống hệt `_reminderBody` legacy).
  static String offsetBody(int minutes, int hour, int minute) {
    String lead;
    if (minutes == 0) {
      lead = 'Bắt đầu bây giờ';
    } else if (minutes % 1440 == 0) {
      lead = 'Còn ${minutes ~/ 1440} ngày';
    } else if (minutes % 60 == 0) {
      lead = 'Còn ${minutes ~/ 60} giờ';
    } else {
      lead = 'Còn $minutes phút';
    }
    return '$lead (bắt đầu lúc ${_two(hour)}:${_two(minute)})';
  }

  /// Nội dung mốc nhắc tuyệt đối.
  static String absoluteBody(int hour, int minute) =>
      'Nhắc lúc ${_two(hour)}:${_two(minute)}';
}
