import 'package:flutter/material.dart';

import '../app/app_localizations.dart';

/// Một mục có thể chọn trong [EntityPickerScreen].
class PickerEntry {
  const PickerEntry({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
}

/// Màn hình chọn một thực thể (có ô tìm kiếm). Trả về (Navigator.pop) mục
/// [PickerEntry] đã chọn, hoặc null nếu người dùng quay lại.
class EntityPickerScreen extends StatefulWidget {
  const EntityPickerScreen({
    super.key,
    required this.title,
    required this.load,
    this.excludeIds = const {},
  });

  final String title;
  final Future<List<PickerEntry>> Function() load;

  /// Các id đã được gắn — không hiển thị để tránh chọn trùng.
  final Set<String> excludeIds;

  @override
  State<EntityPickerScreen> createState() => _EntityPickerScreenState();
}

class _EntityPickerScreenState extends State<EntityPickerScreen> {
  late final Future<List<PickerEntry>> _future = widget.load();
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                labelText: l.search,
                prefixIcon: const ExcludeSemantics(child: Icon(Icons.search)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PickerEntry>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('${l.error}: ${snapshot.error}'));
                }
                final q = _query.text.trim().toLowerCase();
                final entries = [
                  for (final e in snapshot.data ?? const <PickerEntry>[])
                    if (!widget.excludeIds.contains(e.id) &&
                        (q.isEmpty || e.title.toLowerCase().contains(q)))
                      e,
                ];
                if (entries.isEmpty) {
                  return Center(child: Text(l.pickerNoItems));
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return ListTile(
                      leading: ExcludeSemantics(child: Icon(e.icon)),
                      title:
                          Text(e.title.isEmpty ? l.projectUntitled : e.title),
                      subtitle: e.subtitle == null ? null : Text(e.subtitle!),
                      onTap: () => Navigator.pop(context, e),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
