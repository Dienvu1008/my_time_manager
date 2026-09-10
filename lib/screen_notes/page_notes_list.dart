import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../data/models/model_note.dart';
import '../domain/repositories/note_repository.dart';
import 'page_note_editor.dart';

/// Màn danh sách ghi chú: liệt kê, tạo mới, mở để sửa, xóa.
///
/// Trả về `Expanded(child: Scaffold(...))` để hợp với layout của Home (giống
/// các trang nội dung khác trong app).
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  late final NoteRepository _noteRepository = context.read<NoteRepository>();
  late Future<List<Note>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _noteRepository.getNotes();
  }

  Future<void> _openEditor([Note? note]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );
    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEditor(),
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
              return const _EmptyNotes();
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(note),
                  ),
                  onTap: () => _openEditor(note),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: Text(
            'Xóa "${note.title.isEmpty ? 'ghi chú này' : note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _noteRepository.deleteNote(note.id);
    if (mounted) setState(_reload);
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sticky_note_2_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          const Text('Chưa có ghi chú nào'),
          const SizedBox(height: 4),
          const Text('Nhấn nút + để tạo ghi chú mới'),
        ],
      ),
    );
  }
}
