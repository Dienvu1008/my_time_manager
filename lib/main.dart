import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// AdMob tạm tắt (xem khối bị comment ở cuối main). Bật lại import khi dùng lại.
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'data/database/database_manager.dart';
import 'data/repositories/sqlite_trash_repository.dart';
import 'data/device_id_provider.dart';
import 'firebase_options.dart';
import 'screen_focus_timer/data/notification_service.dart';

Future<void> main() async {
  // Bắt buộc gọi trước khi dùng plugin (Firebase, sqflite...) trong main async.
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo dịch vụ thông báo (bao gồm nạp timezone) cho Focus Timer và tính
  // năng nhắc lịch. An toàn, tự bỏ qua nếu lỗi.
  await NotificationService.instance.init();
  // LƯU Ý: KHÔNG xin quyền báo thức chính xác (exact alarm) ở đây. Trên
  // Android 12+, requestExactAlarmsPermission() KHÔNG mở hộp thoại mà CHUYỂN
  // sang màn Cài đặt hệ thống — nếu gọi (và await) trước runApp thì app bị đưa
  // ra nền ngay khi khởi động, quay lại thấy màn trắng/loading. Quyền thông báo
  // (dialog nhẹ, không rời app) được xin SAU khi UI đã hiện (xem bên dưới),
  // còn quyền exact-alarm để xin đúng lúc người dùng bật/đặt nhắc.

  // Định danh thiết bị (deviceId) cho tính năng export/import: mọi bản ghi ghi
  // từ máy này sẽ mang deviceId này. An toàn nếu lỗi (deviceId = null).
  await DeviceIdProvider.init();
  if (DeviceIdProvider.deviceId != null) {
    DatabaseManager.setCurrentDeviceId(DeviceIdProvider.deviceId!);
  }

  // Cấu hình SQLite FFI cho desktop (giữ nguyên như trước).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Dọn thùng rác: xóa vĩnh viễn các mục đã quá số ngày giữ. Đọc số ngày từ
  // SharedPreferences (cùng key với AppBloc), mặc định 30. Bọc try/catch để lỗi
  // dọn rác không bao giờ chặn app khởi động.
  try {
    final prefs = await SharedPreferences.getInstance();
    final retentionDays = prefs.getInt('trashRetentionDays') ?? 30;
    // Route through the domain repository (startup has no widget context, so we
    // construct the SQLite implementation directly — same pattern as other
    // startup services).
    await SqliteTrashRepository().purgeExpiredTrash(retentionDays);
  } catch (e) {
    debugPrint('Dọn thùng rác khi khởi động lỗi: $e');
  }

  // Khởi tạo Firebase. Bọc try/catch để nếu bạn CHƯA chạy `flutterfire
  // configure` (file firebase_options.dart còn là placeholder), app vẫn mở được
  // và ta biết rõ auth chưa dùng được, thay vì crash với thông báo khó hiểu.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    // Ghi log để dễ chẩn đoán trong lúc phát triển.
    debugPrint('Firebase chưa khởi tạo được: $e');
  }

  const bool isProVersion = false;

  runApp(App(isProVersion: isProVersion, firebaseReady: firebaseReady));

  // Sau khi UI đã render (không chặn khởi động), xin quyền THÔNG BÁO — đây là
  // hộp thoại nhẹ (Android 13+/iOS), không đưa người dùng rời khỏi app. Quyền
  // báo thức chính xác KHÔNG xin ở đây (nó mở màn Cài đặt hệ thống, gây gián
  // đoạn) — sẽ xin đúng lúc người dùng bật/đặt nhắc.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Không await: chạy nền, lỗi được nuốt bên trong service.
    NotificationService.instance.requestNotificationPermission();
  });

  // --- AdMob TẠM THỜI BỊ TẮT ---
  // Tài khoản AdMob đang bị deactivate nên khởi tạo Google Mobile Ads sẽ gây
  // crash lúc mở app (MobileAdsInitProvider cần App ID hợp lệ). Bật lại khối
  // dưới đây (và meta-data APPLICATION_ID trong AndroidManifest.xml, cùng import
  // google_mobile_ads ở đầu file) sau khi có tài khoản/App ID thật.
  //
  // if (Platform.isAndroid || Platform.isIOS) {
  //   MobileAds.instance.initialize().then((InitializationStatus status) {
  //     AppOpenAd.load(
  //       adUnitId: 'ca-app-pub-9963949507176831/9067116788',
  //       request: AdRequest(),
  //       adLoadCallback: AppOpenAdLoadCallback(
  //         onAdLoaded: (AppOpenAd ad) {
  //           ad.show();
  //         },
  //         onAdFailedToLoad: (LoadAdError error) {
  //           debugPrint('AppOpenAd failed to load: $error');
  //         },
  //       ),
  //     );
  //   });
  // }
}
