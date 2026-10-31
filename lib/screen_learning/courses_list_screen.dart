import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_course.dart';
import '../domain/repositories/learning_repository.dart';
import '../domain/services/learning_progress_service.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';
import 'learning_labels.dart';

/// Màn danh sách Khóa học (Core Track C7). Mở dạng route đẩy từ drawer; đọc
/// [LearningRepository] / [LearningProgressService] qua provider. Tiến độ mỗi
/// khóa học là giá trị suy ra (không lưu).
class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  late final LearningRepository _repository =
      context.read<LearningRepository>();
  late final LearningProgressService _progress =
      context.read<LearningProgressService>();
  late Future<(List<Course>, Map<String, CourseProgress>)> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _load();
  }

  Future<(List<Course>, Map<String, CourseProgress>)> _load() async {
    final courses = await _repository.getCourses();
    final progress = await _progress.progressOfLiveCourses();
    return (courses, progress);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CourseFormScreen()),
    );
    if (created == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.courses)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.newCourse,
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<(List<Course>, Map<String, CourseProgress>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${l.error}: ${snapshot.error}'));
          }
          final (courses, progress) =
              snapshot.data ?? (const <Course>[], const <String, CourseProgress>{});
          if (courses.isEmpty) {
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
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = courses[index];
                final p = progress[c.id];
                final ratio = p?.ratio ?? 0.0;
                final percent = formatPercent(ratio);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.color,
                    child: const ExcludeSemantics(
                        child: Icon(Icons.school_outlined)),
                  ),
                  title: Text(
                    c.title.isEmpty ? l.learningUntitled : c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l.lessonsCompleted}: '
                          '${p?.completedLessons ?? 0}/${p?.totalLessons ?? 0}'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: ratio,
                        semanticsLabel: l.learningProgress,
                        semanticsValue: percent,
                      ),
                    ],
                  ),
                  trailing: Text(percent),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CourseDetailScreen(courseId: c.id),
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
          Icon(Icons.school_outlined, size: 48, semanticLabel: l.courses),
          const SizedBox(height: 16),
          Text(l.noCoursesYet,
              style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noCoursesHint,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
