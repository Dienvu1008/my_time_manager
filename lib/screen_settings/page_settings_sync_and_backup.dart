import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../data/backup/backup_service.dart';
import '../data/backup/import_service.dart';
import '../data/device_calendar/device_calendar_service.dart';
import '../data/device_id_provider.dart';

/// Màn hình "Data & Sync": sao lưu (export) và khôi phục (import) dữ liệu.
class SyncAndBackupPage extends StatefulWidget {
  const SyncAndBackupPage({super.key});

  @override
  State<SyncAndBackupPage> createState() => _SyncAndBackupPageState();
}

class _SyncAndBackupPageState extends State<SyncAndBackupPage> {
  final BackupService _backup = BackupService();
  final ImportService _importer = ImportService();
  final DeviceCalendarService _deviceCalendar = DeviceCalendarService.instance;
  bool _busy = false;
  bool? _calendarPermissionGranted;

  @override
  void initState() {
    super.initState();
    _refreshCalendarPermission();
  }

  Future<void> _refreshCalendarPermission() async {
    if (!_deviceCalendar.isSupported) return;
    final granted = await _deviceCalendar.hasPermissions();
    if (mounted) setState(() => _calendarPermissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: [
              _deviceCard(),
              _deviceCalendarCard(),
              _exportCard(),
              _importCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deviceCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.devices_outlined),
        title: const Text('Thiết bị này'),
        subtitle: Text(DeviceIdProvider.deviceName ?? 'Không rõ tên thiết bị'),
      ),
    );
  }

  Widget _deviceCalendarCard() {
    final supported = _deviceCalendar.isSupported;
    final granted = _calendarPermissionGranted ?? false;
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Lịch thiết bị',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(supported
                ? (granted
                    ? 'Đã cấp quyền. Sự kiện lịch thiết bị hiển thị trên lịch.'
                    : 'Cấp quyền để hiển thị và quản lý sự kiện lịch thiết bị.')
                : 'Chỉ hỗ trợ trên Android/iOS. Trên máy tính sẽ bổ sung sau '
                    '(đăng nhập Google).'),
          ),
          if (supported && !granted)
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Cấp quyền lịch thiết bị'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final ok = await _deviceCalendar.requestPermissions();
                if (!mounted) return;
                setState(() => _calendarPermissionGranted = ok);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã cấp quyền lịch. Mở lại màn lịch để thấy sự kiện.'
                        : 'Chưa được cấp quyền lịch.'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _exportCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Xuất dữ liệu (sao lưu)',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: const Text(
                'Chọn định dạng để lưu toàn bộ dữ liệu ra file. '
                'Chỉ file JSON nhập lại được.'),
          ),
          for (final format in ExportFormat.values)
            ListTile(
              leading: Icon(_iconForFormat(format)),
              title: Text(format.label),
              trailing: const Icon(Icons.download_outlined),
              onTap: _busy ? null : () => _export(format),
            ),
        ],
      ),
    );
  }

  Widget _importCard() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Nhập dữ liệu (khôi phục)',
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: const Text(
                'Chọn một file JSON đã sao lưu. Dữ liệu trùng lặp được bỏ qua; '
                'khi xung đột sẽ hỏi hoặc áp dụng lựa chọn của bạn.'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Chọn file JSON để nhập'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy ? null : _import,
          ),
        ],
      ),
    );
  }

  IconData _iconForFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_outlined;
      case ExportFormat.csv:
        return Icons.table_chart_outlined;
      case ExportFormat.text:
        return Icons.notes_outlined;
    }
  }

  // ----------------------------------------------------------------
  // EXPORT
  // ----------------------------------------------------------------
  Future<void> _export(ExportFormat format) async {
    setState(() => _busy = true);
    try {
      final (content, total) = await _backup.buildContent(format);
      final fileName = _backup.suggestedFileName(format);

      // Cho người dùng chọn nơi lưu. Trên desktop (Windows/macOS/Linux),
      // saveFile chỉ trả về đường dẫn — KHÔNG tự ghi bytes; ta tự ghi bằng
      // writeToPath. Trên Android/iOS, cần truyền bytes để plugin tự ghi.
      // saveFile có thể ném trên vài nền tảng -> bọc riêng và fallback.
      String? savedPath;
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          savedPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Lưu bản sao lưu',
            fileName: fileName,
            bytes: Uint8List.fromList(utf8.encode(content)),
          );
        } else {
          savedPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Lưu bản sao lưu',
            fileName: fileName,
          );
          // Desktop: tự ghi nội dung vào đường dẫn người dùng chọn.
          if (savedPath != null) {
            await _backup.writeToPath(savedPath, content);
          }
        }
      } catch (e, st) {
        // Hộp thoại chọn nơi lưu không dùng được -> chuyển sang fallback.
        debugPrint('saveFile lỗi (chuyển sang lưu vào thư mục app): $e\n$st');
        savedPath = null;
      }

      // Nếu không chọn được nơi lưu (hoặc bị hủy) -> lưu vào thư mục tài liệu
      // của app để không mất dữ liệu đã xuất.
      savedPath ??= await _backup.writeToAppDir(fileName, content);

      // Bảo đảm file thực sự có nội dung (một số nền tảng trả path rỗng).
      final f = File(savedPath);
      if (!await f.exists() || (await f.length()) == 0) {
        await _backup.writeToPath(savedPath, content);
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline,
              color: Colors.green, size: 40),
          title: const Text('Đã xuất dữ liệu'),
          content: Text('Đã lưu $total mục vào:\n$savedPath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                OpenFile.open(savedPath);
              },
              child: const Text('Mở file'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Export lỗi: $e\n$st');
      _showError('Xuất dữ liệu thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ----------------------------------------------------------------
  // IMPORT
  // ----------------------------------------------------------------
  Future<void> _import() async {
    // 1) Chọn file.
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Chọn file JSON sao lưu',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } catch (e) {
      _showError('Không mở được hộp thoại chọn file: $e');
      return;
    }
    if (picked == null || picked.files.isEmpty) return;

    // 2) Đọc nội dung.
    String content;
    try {
      final file = picked.files.first;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        _showError('Không đọc được file đã chọn.');
        return;
      }
    } catch (e) {
      _showError('Đọc file thất bại: $e');
      return;
    }

    // 3) Kiểm tra định dạng + đọc metadata nguồn.
    final metadata = _importer.readMetadata(content);
    if (metadata == null) {
      _showError('File không đúng định dạng backup JSON của ứng dụng.');
      return;
    }

    // 4) Chọn chính sách xung đột.
    if (!mounted) return;
    final policy = await _askPolicy(metadata);
    if (policy == null) return; // Người dùng hủy.

    // 5) Import với hộp thoại tiến trình.
    if (!mounted) return;
    final progress = ValueNotifier<int>(0);
    final totalNotifier = ValueNotifier<int>(0);
    setState(() => _busy = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ImportProgressDialog(
        progress: progress,
        total: totalNotifier,
      ),
    );

    ImportSummary? summary;
    String? error;
    try {
      summary = await _importer.import(
        jsonContent: content,
        policy: policy,
        onConflict: policy == ConflictPolicy.askEach ? _askConflict : null,
        onProgress: (done, total) {
          progress.value = done;
          totalNotifier.value = total;
        },
      );
    } catch (e) {
      error = e.toString();
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // đóng dialog tiến trình
      setState(() => _busy = false);
    }
    progress.dispose();
    totalNotifier.dispose();

    if (!mounted) return;
    if (error != null) {
      _showError('Nhập dữ liệu thất bại: $error');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline,
            color: Colors.green, size: 40),
        title: const Text('Đã nhập dữ liệu'),
        content: Text(
          'Đã xử lý ${summary!.totalProcessed} mục:\n'
          '• Thêm mới: ${summary.added}\n'
          '• Trùng (bỏ qua): ${summary.skippedDuplicate}\n'
          '• Ghi đè: ${summary.overwritten}\n'
          '• Giữ bản trong máy: ${summary.keptLocal}\n'
          '• Lỗi: ${summary.failed}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Hỏi chính sách xung đột trước khi import. Trả về null nếu người dùng hủy.
  Future<ConflictPolicy?> _askPolicy(Map<String, dynamic> metadata) {
    final deviceName = metadata['deviceName'] as String?;
    final exportedAt = metadata['exportedAt'] as String?;
    return showDialog<ConflictPolicy>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cách xử lý khi trùng/xung đột'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nguồn: ${deviceName ?? 'không rõ'}'
                '${exportedAt != null ? '\nXuất lúc: $exportedAt' : ''}'),
            const SizedBox(height: 8),
            const Text('Dữ liệu giống hệt sẽ tự bỏ qua. Với dữ liệu cùng ID '
                'nhưng khác nội dung:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.askEach),
            child: const Text('Hỏi từng cái'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.keepNewest),
            child: const Text('Giữ bản mới nhất'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.keepLocal),
            child: const Text('Giữ bản trong máy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ConflictPolicy.keepIncoming),
            child: const Text('Ghi đè bằng bản nhập'),
          ),
        ],
      ),
    );
  }

  /// Hỏi người dùng cho MỘT xung đột (khi chọn "Hỏi từng cái").
  Future<ConflictDecision> _askConflict(ConflictInfo info) async {
    final decision = await showDialog<ConflictDecision>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Xung đột dữ liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mục: ${info.title}'),
            const SizedBox(height: 8),
            Text('• Bản trong máy — cập nhật: '
                '${_fmt(info.localUpdatedAt)}'),
            Text('• Bản nhập — cập nhật: ${_fmt(info.incomingUpdatedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ConflictDecision.keepLocal),
            child: const Text('Giữ bản máy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, ConflictDecision.keepIncoming),
            child: const Text('Ghi đè'),
          ),
        ],
      ),
    );
    // Nếu vì lý do nào đó dialog bị đóng mà không chọn -> an toàn: giữ bản máy.
    return decision ?? ConflictDecision.keepLocal;
  }

  String _fmt(DateTime? dt) => dt == null ? 'không rõ' : dt.toString();

  void _showError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại tiến trình khi import.
class _ImportProgressDialog extends StatelessWidget {
  const _ImportProgressDialog({required this.progress, required this.total});

  final ValueNotifier<int> progress;
  final ValueNotifier<int> total;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đang nhập dữ liệu...'),
      content: ValueListenableBuilder<int>(
        valueListenable: total,
        builder: (context, totalValue, _) {
          return ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (context, doneValue, __) {
              final ratio =
                  totalValue == 0 ? null : doneValue / totalValue;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: ratio),
                  const SizedBox(height: 12),
                  Text('$doneValue / $totalValue'),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
