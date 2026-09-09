// ⚠️  FILE PLACEHOLDER — PHẢI THAY BẰNG FILE THẬT ⚠️
//
// File này được tạo tạm để dự án BIÊN DỊCH được trước khi bạn cấu hình Firebase.
// Các giá trị bên dưới là GIẢ (rỗng) và sẽ KHÔNG kết nối được tới Firebase.
//
// Để có file thật, chạy lệnh sau ở thư mục gốc dự án (xem hướng dẫn cuối):
//     flutterfire configure
//
// Lệnh đó sẽ TỰ ĐỘNG GHI ĐÈ file này bằng khóa cấu hình thật cho từng nền tảng
// (Android, Windows, ...). Sau khi chạy xong, xóa cảnh báo này nếu muốn.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase mặc định theo nền tảng.
///
/// Sau khi chạy `flutterfire configure`, lớp này sẽ chứa khóa thật do FlutterFire
/// CLI sinh ra. Hiện tại nó ném lỗi có hướng dẫn nếu chưa được cấu hình.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Chưa cấu hình Firebase cho Web. Hãy chạy `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _placeholder('android');
      case TargetPlatform.windows:
        return _placeholder('windows');
      case TargetPlatform.iOS:
        return _placeholder('ios');
      case TargetPlatform.macOS:
        return _placeholder('macos');
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase chưa được cấu hình cho Linux trong dự án này.',
        );
      default:
        throw UnsupportedError(
          'Nền tảng không được hỗ trợ. Hãy chạy `flutterfire configure`.',
        );
    }
  }

  // Giá trị giả để code biên dịch. `flutterfire configure` sẽ thay toàn bộ.
  static FirebaseOptions _placeholder(String platform) => FirebaseOptions(
        apiKey: 'REPLACE_ME',
        appId: 'REPLACE_ME',
        messagingSenderId: 'REPLACE_ME',
        projectId: 'REPLACE_ME',
      );
}
