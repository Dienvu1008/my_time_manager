import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../database/database_manager.dart';
import '../device_id_provider.dart';

/// Định dạng file khi export.
enum ExportFormat { json, csv, text }

extension ExportFormatX on ExportFormat {
  String get extension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.text:
        return 'txt';
    }
  }

  String get label {
    switch (this) {
      case ExportFormat.json:
        return 'JSON (đầy đủ, nhập lại được)';
      case ExportFormat.csv:
        return 'CSV (bảng, để xem/sửa ngoài)';
      case ExportFormat.text:
        return 'Text (tóm tắt, chỉ để đọc)';
    }
  }
}

/// Kết quả của một lần export.
class ExportResult {
  ExportResult({required this.filePath, required this.totalRows});

  final String filePath;
  final int totalRows;
}

/// Dịch vụ sao lưu (export) toàn bộ dữ liệu app ra file.
///
/// - JSON: định dạng đầy đủ, có metadata (deviceId nguồn) và giữ nguyên mọi cột
///   (kể cả deviceId per-record). ĐÂY là định dạng dùng để import lại.
/// - CSV: mỗi bảng một khối, thuận tiện mở bằng Excel/xem tay. Không dùng để
///   import lại (dữ liệu lồng như subtasks đã được mã hoá JSON trong ô).
/// - Text: bản tóm tắt số lượng cho người đọc nhanh.
class BackupService {
  BackupService({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  /// Phiên bản định dạng backup (tăng khi cấu trúc file JSON đổi).
  static const int backupFormatVersion = 1;

  /// Gom toàn bộ dữ liệu 7 bảng dưới dạng map thô (kể cả mục trong thùng rác).
  Future<Map<String, List<Map<String, dynamic>>>> _collectAll() async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final table in DatabaseManager.allDataTables) {
      result[table] = await _db.rawRows(table);
    }
    return result;
  }

  /// Sinh nội dung file theo [format]. Trả về (chuỗi nội dung, tổng số bản ghi).
  Future<(String, int)> buildContent(ExportFormat format) async {
    final data = await _collectAll();
    final total = data.values.fold<int>(0, (sum, rows) => sum + rows.length);

    switch (format) {
      case ExportFormat.json:
        return (_buildJson(data), total);
      case ExportFormat.csv:
        return (_buildCsv(data), total);
      case ExportFormat.text:
        return (_buildText(data), total);
    }
  }

  String _metadataHeaderComment() =>
      'Nguồn: ${DeviceIdProvider.deviceName ?? 'không rõ'} '
      '(${DeviceIdProvider.deviceId ?? 'no-device-id'})';

  String _buildJson(Map<String, List<Map<String, dynamic>>> data) {
    final payload = {
      'metadata': {
        'app': 'my_time_manager',
        'backupFormatVersion': backupFormatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'deviceId': DeviceIdProvider.deviceId,
        'deviceName': DeviceIdProvider.deviceName,
      },
      // jsonEncode KHÔNG hỗ trợ double không hữu hạn (Infinity/-Infinity/NaN)
      // — vốn được dùng cho target "ít nhất/nhiều nhất" của công việc đo lường.
      // Phải làm sạch dữ liệu TRƯỚC khi encode (toEncodable không được gọi cho
      // các double đặc biệt, nên không cứu được).
      'data': _sanitize(data),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Chuỗi đánh dấu cho các double đặc biệt (chia sẻ với ImportService để
  /// khôi phục khi nhập lại).
  static const String infinitySentinel = '__Infinity__';
  static const String negativeInfinitySentinel = '__-Infinity__';
  static const String nanSentinel = '__NaN__';

  /// Đệ quy thay các double vô hạn/NaN bằng chuỗi sentinel để jsonEncode chạy.
  static Object? _sanitize(Object? value) {
    if (value is double) {
      if (value == double.infinity) return infinitySentinel;
      if (value == double.negativeInfinity) return negativeInfinitySentinel;
      if (value.isNaN) return nanSentinel;
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  String _buildCsv(Map<String, List<Map<String, dynamic>>> data) {
    final buffer = StringBuffer();
    buffer.writeln('# my_time_manager export (CSV)');
    buffer.writeln('# ${_metadataHeaderComment()}');
    buffer.writeln('# Xuất lúc: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // csv 8.x: API mới dùng CsvEncoder (ListToCsvConverter đã bị bỏ). CsvEncoder
    // có constructor const và .convert(List<List<dynamic>>) trả về chuỗi CSV.
    const converter = CsvEncoder();
    for (final table in DatabaseManager.allDataTables) {
      final rows = data[table] ?? [];
      buffer.writeln('### TABLE: $table (${rows.length})');
      if (rows.isEmpty) {
        buffer.writeln();
        continue;
      }
      // Tập cột: hợp của tất cả các key để không mất cột nào.
      final columns = <String>{};
      for (final r in rows) {
        columns.addAll(r.keys);
      }
      final header = columns.toList();
      final table2d = <List<dynamic>>[header];
      for (final r in rows) {
        table2d.add(header.map((c) => r[c]).toList());
      }
      buffer.writeln(converter.convert(table2d));
      buffer.writeln();
    }
    return buffer.toString();
  }

  String _buildText(Map<String, List<Map<String, dynamic>>> data) {
    final buffer = StringBuffer();
    buffer.writeln('BẢN TÓM TẮT DỮ LIỆU my_time_manager');
    buffer.writeln(_metadataHeaderComment());
    buffer.writeln('Xuất lúc: ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 40);

    // Nhãn dễ đọc cho từng bảng.
    const labels = {
      'tasklists': 'Danh sách công việc',
      'tasks': 'Công việc',
      'measurabletasks': 'Công việc đo lường',
      'taskswithsubtasks': 'Công việc có việc con',
      'events': 'Sự kiện',
      'timeintervals': 'Khoảng thời gian đã lên lịch',
      'focus_sessions': 'Phiên tập trung',
      'goals': 'Mục tiêu',
      'milestones': 'Cột mốc',
      'goal_links': 'Liên kết mục tiêu',
      'projects': 'Dự án',
      'project_items': 'Mục trong dự án',
    };

    for (final table in DatabaseManager.allDataTables) {
      final rows = data[table] ?? [];
      buffer.writeln();
      buffer.writeln('${labels[table] ?? table}: ${rows.length} mục');
      // Liệt kê tối đa 50 tiêu đề để bản tóm tắt không quá dài.
      var shown = 0;
      for (final r in rows) {
        if (shown >= 50) {
          buffer.writeln('  ... và ${rows.length - shown} mục khác');
          break;
        }
        final title = (r['title'] ?? r['taskTitle'] ?? '(không tiêu đề)')
            .toString();
        buffer.writeln('  - $title');
        shown++;
      }
    }
    return buffer.toString();
  }

  /// Tên file mặc định gợi ý khi lưu.
  String suggestedFileName(ExportFormat format) {
    final now = DateTime.now();
    final stamp = '${now.year}${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    return 'my_time_manager_backup_$stamp.${format.extension}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Ghi [content] ra một file trong thư mục tài liệu của app và trả về đường
  /// dẫn. Dùng khi không có hộp thoại chọn nơi lưu (hoặc làm nơi lưu tạm để
  /// chia sẻ). Trên Windows/desktop đây là nơi ổn định để mở lại bằng open_file.
  Future<String> writeToAppDir(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);
    final file = File(path);
    await file.writeAsString(content);
    return path;
  }

  /// Ghi [content] ra đúng [fullPath] do người dùng chọn.
  Future<void> writeToPath(String fullPath, String content) async {
    await File(fullPath).writeAsString(content);
  }
}
