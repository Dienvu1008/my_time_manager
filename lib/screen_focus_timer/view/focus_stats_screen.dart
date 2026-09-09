import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/stats_cubit.dart';
import '../data/focus_repository.dart';

/// Màn hình thống kê các phiên focus theo ngày / tuần / tháng.
///
/// Nhận [repository] từ bên gọi để dùng chung nguồn dữ liệu (local-first).
class FocusStatsScreen extends StatelessWidget {
  const FocusStatsScreen({super.key, required this.repository});

  final FocusRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatsCubit(repository),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê tập trung')),
      body: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) {
          return Column(
            children: [
              // Bộ chọn khoảng thời gian.
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<StatsRange>(
                  segments: StatsRange.values
                      .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                      .toList(),
                  selected: {state.range},
                  onSelectionChanged: (sel) =>
                      context.read<StatsCubit>().load(sel.first),
                ),
              ),
              if (state.loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(child: _content(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, StatsState state) {
    if (state.totalSessionCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa có phiên tập trung nào trong khoảng này.\n'
            'Hãy hoàn thành một phiên Pomodoro để xem thống kê.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Hàng 1: tổng thời gian + tổng số phiên.
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                icon: Icons.timer,
                value: _formatMinutes(state.totalFocusMinutes),
                label: 'Tổng thời gian',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                context,
                icon: Icons.timelapse,
                value: '${state.totalSessionCount}',
                label: 'Tổng số phiên',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Hàng 2: phiên hoàn tất + phiên dở dang.
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                context,
                icon: Icons.check_circle,
                value: '${state.completedSessionCount}',
                label: 'Phiên hoàn tất',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                context,
                icon: Icons.pause_circle_outline,
                value: '${state.partialSessionCount}',
                label: 'Phiên dở dang',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Theo công việc', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...state.perTask.map((t) => _taskRow(context, t, state.totalFocusMinutes)),
      ],
    );
  }

  Widget _summaryCard(BuildContext context,
      {required IconData icon, required String value, required String label}) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(BuildContext context, TaskStat stat, int totalMinutes) {
    final theme = Theme.of(context);
    final fraction = totalMinutes == 0 ? 0.0 : stat.minutes / totalMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stat.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text(_formatMinutes(stat.minutes),
                  style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  /// Định dạng phút thành "Xh Ym" hoặc "Ym".
  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h giờ' : '$h giờ $m phút';
  }
}
