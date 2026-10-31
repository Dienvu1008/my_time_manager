/// Gắn deviceId hiện tại vào [map] nếu map chưa có (không ghi đè).
/// Dùng cho mọi insert để đánh dấu nguồn của bản ghi.
///
/// Trước đây là `_withDeviceId` trong `DatabaseManager`; được trích ra thành
/// helper riêng trong C4 để các DAO dùng chung mà không phụ thuộc DatabaseManager.
String? _currentDeviceId;

/// Đặt deviceId hiện tại (gọi một lần khi app khởi động).
void setCurrentDeviceId(String id) => _currentDeviceId = id;

/// Lấy deviceId hiện tại (dùng cho export/import).
String? getCurrentDeviceId() => _currentDeviceId;

/// Gắn deviceId vào [map] nếu chưa có.
Map<String, dynamic> withDeviceId(Map<String, dynamic> map) {
  if (!map.containsKey('deviceId') || map['deviceId'] == null) {
    if (_currentDeviceId != null) {
      return {...map, 'deviceId': _currentDeviceId};
    }
  }
  return map;
}
