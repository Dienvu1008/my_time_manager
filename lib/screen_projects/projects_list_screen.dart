import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_project.dart';
import '../domain/repositories/project_repository.dart';
import 'project_labels.dart';
import 'project_workspace_screen.dart';

/// Màn danh sách Dự án (Core Track C6) — CHỈ ĐỌC: chưa có thao tác tạo / sửa /
/// xóa. Mở dạng route đẩy từ drawer; đọc [ProjectRepository] qua provider.
class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  late final ProjectRepository _repository = context.read<ProjectRepository>();
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _projectsFuture = _repository.getProjects();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _projectsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.projects)),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l.error}: ${snapshot.error}'));
          }
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [_EmptyState(l: l)],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = projects[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.color,
                    // CircleAvatar tự chọn màu chữ/icon tương phản với nền.
                    child: const ExcludeSemantics(
                        child: Icon(Icons.workspaces_outlined)),
                  ),
                  title: Text(
                    p.title.isEmpty ? l.projectUntitled : p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(projectStatusLabel(l, p.status)),
                  trailing: const ExcludeSemantics(
                      child: Icon(Icons.chevron_right)),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProjectWorkspaceScreen(projectId: p.id),
                      ),
                    );
                    if (mounted) await _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspaces_outlined,
              size: 48, semanticLabel: l.projects),
          const SizedBox(height: 16),
          Text(l.noProjectsYet,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noProjectsHint,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
