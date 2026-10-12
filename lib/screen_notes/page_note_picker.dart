import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../domain/models/model_note.dart';
import '../domain/repositories/note_repository.dart';
import 'page_note_editor.dart';

/// Màn CHỌN một ghi chú để đính kèm vào Task/TimeInterval.
///
/// Liệt kê các ghi chú hiện có (bỏ những id đã đính kèm qua [excludeIds]).
/// Nhấn vào một ghi chú -> trả (Navigator.pop) `Note` đó. Nút "+" tạo ghi chú
/// mới bằng [NoteEditorPage]; sau khi tạo xong sẽ chọn luôn ghi chú mới nhất.
class NotePickerPage extends StatefulWidget {
  const NotePickerPage({super.key, this.excludeIds = const []});

  /// Các id ghi chú đã được đính kèm (không hiển thị lại để tránh trùng).
  final List<String> excludeIds;

  @override
  State<NotePickerPage> createState() => _NotePickerPageState();
}

class _NotePickerPageState extends State<NotePickerPage> {
  late final NoteRepository _noteRepository = context.read<NoteRepository>();
  late Future<List<Note>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<List<Note>> _load() async {
    final all = await _noteRepository.getNotes();
    return all.where((n) => !widget.excludeIds.contains(n.id)).toList();
  }

  /// Tạo ghi chú mới rồi chọn luôn ghi chú đó.
  Future<void> _createAndPick() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NoteEditorPage()),
    );
    if (created != true || !mounted) return;
    // Ghi chú mới nằm đầu danh sách (sắp xếp updatedAt DESC) và chưa bị loại trừ.
    final all = await _noteRepository.getNotes();
    final candidates =
        all.where((n) => !widget.excludeIds.contains(n.id)).toList();
    if (candidates.isEmpty || !mounted) {
      setState(_reload);
      return;
    }
    Navigator.of(context).pop(candidates.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn ghi chú'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAndPick,
        tooltip: 'Ghi chú mới',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải ghi chú: ${snapshot.error}'));
          }
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const _EmptyPicker();
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(
                  note.title.isEmpty ? '(Không tiêu đề)' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(note.updatedAt)}',
                ),
                onTap: () => Navigator.of(context).pop(note),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          const Text('Chưa có ghi chú nào để đính kèm'),
          const SizedBox(height: 4),
          const Text('Nhấn nút + để tạo ghi chú mới'),
        ],
      ),
    );
  }
}
