import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database_manager.dart';
import 'backup_service.dart';

/// Chính sách xử lý khi một bản ghi nhập vào XUNG ĐỘT với bản ghi cùng id đã có
/// trong máy (nội dung khác nhau).
enum ConflictPolicy {
  /// Hỏi người dùng cho từng xung đột.
  askEach,

  /// Giữ bản mới nhất (so theo thời gian cập nhật) — áp hàng loạt.
  keepNewest,

  /// Luôn giữ bản đang có trong máy (bỏ qua bản nhập).
  keepLocal,

  /// Luôn ghi đè bằng bản nhập.
  keepIncoming,
}

/// Quyết định cho một xung đột cụ thể khi [ConflictPolicy.askEach].
enum ConflictDecision { keepLocal, keepIncoming }

/// Thông tin một xung đột để UI hiển thị khi hỏi người dùng.
class ConflictInfo {
  ConflictInfo({
    required this.table,
    required this.id,
    required this.title,
    required this.localDeviceName,
    required this.incomingDeviceName,
    required this.localUpdatedAt,
    required this.incomingUpdatedAt,
  });

  final String table;
  final String id;
  final String title;
  final String? localDeviceName;
  final String? incomingDeviceName;
  final DateTime? localUpdatedAt;
  final DateTime? incomingUpdatedAt;
}

/// Tóm tắt kết quả import.
class ImportSummary {
  int added = 0;
  int skippedDuplicate = 0;
  int overwritten = 0;
  int keptLocal = 0;
  int failed = 0;

  int get totalProcessed =>
      added + skippedDuplicate + overwritten + keptLocal + failed;

  @override
  String toString() =>
      'Thêm mới: $added, Trùng (bỏ qua): $skippedDuplicate, '
      'Ghi đè: $overwritten, Giữ bản máy: $keptLocal, Lỗi: $failed';
}

/// Dịch vụ nhập (import) dữ liệu từ file JSON do [BackupService] xuất ra.
class ImportService {
  ImportService({DatabaseManager? databaseManager})
      : _db = databaseManager ?? DatabaseManager();

  final DatabaseManager _db;

  /// Thứ tự import tôn trọng khóa ngoại: cha trước, con sau. projects →
  /// project_items đặt CUỐI, sau mọi bảng thực thể được import (C6).
  static const List<String> _importOrder = [
    'tasklists',
    'tasks',
    'measurabletasks',
    'taskswithsubtasks',
    'timeintervals',
    'events',
    'focus_sessions',
    'goals',
    'milestones',
    'goal_links',
    'projects',
    'project_items',
  ];

  /// Đọc metadata (deviceId/deviceName nguồn, thời điểm export) từ nội dung
  /// JSON, hoặc null nếu không phải file hợp lệ.
  Map<String, dynamic>? readMetadata(String jsonContent) {
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is Map && decoded['data'] is Map) {
        return (decoded['metadata'] as Map?)?.cast<String, dynamic>() ?? {};
      }
    } catch (_) {}
    return null;
  }

  /// Nhập dữ liệu từ [jsonContent].
  ///
  /// [policy] quyết định cách xử lý xung đột. Nếu là [ConflictPolicy.askEach],
  /// [onConflict] sẽ được gọi cho từng xung đột để lấy quyết định (bắt buộc
  /// cung cấp trong trường hợp này).
  /// [onProgress] báo tiến trình (done, total).
  Future<ImportSummary> import({
    required String jsonContent,
    required ConflictPolicy policy,
    Future<ConflictDecision> Function(ConflictInfo info)? onConflict,
    void Function(int done, int total)? onProgress,
  }) async {
    final summary = ImportSummary();

    final decoded = jsonDecode(jsonContent);
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const FormatException(
          'File không đúng định dạng backup của my_time_manager.');
    }
    final data = (decoded['data'] as Map).cast<String, dynamic>();
    final incomingDeviceName =
        (decoded['metadata'] as Map?)?['deviceName'] as String?;

    // Tổng số bản ghi để báo tiến trình.
    var total = 0;
    for (final table in _importOrder) {
      final rows = data[table];
      if (rows is List) total += rows.length;
    }
    var done = 0;

    for (final table in _importOrder) {
      final rows = data[table];
      if (rows is! List) continue;

      for (final raw in rows) {
        try {
          if (raw is! Map) {
            summary.failed++;
            continue;
          }
          // Khôi phục các double đặc biệt (Infinity/-Infinity/NaN) đã được mã
          // hoá thành chuỗi sentinel khi export, để ghi đúng vào cột REAL.
          final row = _desanitize(raw.cast<String, dynamic>());
          final id = row['id']?.toString();
          if (id == null || id.isEmpty) {
            summary.failed++;
            continue;
          }

          final existing = await _db.rawRowById(table, id);
          if (existing == null) {
            // Chưa có -> thêm mới.
            await _db.importRawRow(table, row);
            summary.added++;
          } else if (_rowsEqual(existing, row)) {
            // Giống hệt -> trùng lặp, bỏ qua.
            summary.skippedDuplicate++;
          } else {
            // Xung đột -> xử lý theo chính sách.
            final keepIncoming = await _resolveConflict(
              table: table,
              id: id,
              existing: existing,
              incoming: row,
              incomingDeviceName: incomingDeviceName,
              policy: policy,
              onConflict: onConflict,
            );
            if (keepIncoming) {
              await _db.importRawRow(table, row);
              summary.overwritten++;
            } else {
              summary.keptLocal++;
            }
          }
        } catch (e) {
          debugPrint('Import lỗi ở bảng $table: $e');
          summary.failed++;
        } finally {
          done++;
          onProgress?.call(done, total);
        }
      }
    }

    return summary;
  }

  /// Trả về true nếu nên GHI ĐÈ bằng bản nhập (incoming), false nếu giữ bản máy.
  Future<bool> _resolveConflict({
    required String table,
    required String id,
    required Map<String, dynamic> existing,
    required Map<String, dynamic> incoming,
    required String? incomingDeviceName,
    required ConflictPolicy policy,
    Future<ConflictDecision> Function(ConflictInfo info)? onConflict,
  }) async {
    switch (policy) {
      case ConflictPolicy.keepLocal:
        return false;
      case ConflictPolicy.keepIncoming:
        return true;
      case ConflictPolicy.keepNewest:
        final localTime = _updatedAt(table, existing);
        final incomingTime = _updatedAt(table, incoming);
        if (localTime == null && incomingTime == null) return false;
        if (localTime == null) return true;
        if (incomingTime == null) return false;
        // Ghi đè nếu bản nhập mới hơn (hoặc bằng -> giữ máy để ổn định).
        return incomingTime.isAfter(localTime);
      case ConflictPolicy.askEach:
        if (onConflict == null) {
          // Không có cách hỏi -> an toàn: giữ bản máy.
          return false;
        }
        final info = ConflictInfo(
          table: table,
          id: id,
          title: (incoming['title'] ??
                  incoming['taskTitle'] ??
                  existing['title'] ??
                  existing['taskTitle'] ??
                  '(không tiêu đề)')
              .toString(),
          localDeviceName: existing['deviceId']?.toString(),
          incomingDeviceName: incomingDeviceName ??
              incoming['deviceId']?.toString(),
          localUpdatedAt: _updatedAt(table, existing),
          incomingUpdatedAt: _updatedAt(table, incoming),
        );
        final decision = await onConflict(info);
        return decision == ConflictDecision.keepIncoming;
    }
  }

  /// Lấy mốc thời gian cập nhật của một bản ghi để so "mới nhất".
  /// - Đa số bảng dùng updateTimeStamp (ISO8601).
  /// - focus_sessions không có updateTimeStamp -> dùng endTime.
  /// - goal_links không có updateTimeStamp -> dùng createdAt.
  /// - project_items không có updateTimeStamp -> dùng createdAt.
  DateTime? _updatedAt(String table, Map<String, dynamic> row) {
    final raw = switch (table) {
      'focus_sessions' => row['endTime'],
      'goal_links' => row['createdAt'],
      'project_items' => row['createdAt'],
      _ => row['updateTimeStamp'],
    };
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// So sánh hai bản ghi có "giống hệt" về nội dung không. Bỏ qua cột deviceId
  /// (chỉ là nguồn ghi) để hai bản cùng nội dung từ hai máy vẫn coi là trùng.
  bool _rowsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    final keys = {...a.keys, ...b.keys}..remove('deviceId');
    for (final k in keys) {
      if ('${a[k]}' != '${b[k]}') return false;
    }
    return true;
  }

  /// Chuyển ngược chuỗi sentinel (được tạo khi export) về double vô hạn/NaN.
  Map<String, dynamic> _desanitize(Map<String, dynamic> row) {
    return row.map((k, v) {
      if (v == BackupService.infinitySentinel) {
        return MapEntry(k, double.infinity);
      }
      if (v == BackupService.negativeInfinitySentinel) {
        return MapEntry(k, double.negativeInfinity);
      }
      if (v == BackupService.nanSentinel) {
        return MapEntry(k, double.nan);
      }
      return MapEntry(k, v);
    });
  }
}
