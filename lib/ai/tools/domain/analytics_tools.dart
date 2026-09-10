import '../../../domain/repositories/task_repository.dart';
import '../../../domain/repositories/focus_repository.dart';
import '../../../domain/repositories/time_interval_repository.dart';
import '../../../domain/services/focus_statistics_service.dart';
import '../../analytics/metric_inputs.dart';
import '../../analytics/metrics_sample_builder.dart';
import '../../analytics/productivity_metrics.dart';
import '../tool.dart';
import '../tool_args.dart';
import '../tool_result.dart';

/// Read-only analytics tools. They combine existing domain APIs into small,
/// deterministic summaries the model can interpret — including the Phase 11
/// productivity metrics, which are computed by application code (never by the
/// LLM). These tools never mutate data.
abstract class _AnalyticsTool extends Tool {
  const _AnalyticsTool();
  @override
  ToolRisk get risk => ToolRisk.readOnly;

  Future<ToolResult> guarded(
      Future<ToolResult> Function(ToolArgs args) body, Map<String, dynamic> a) async {
    try {
      return await body(ToolArgs(a));
    } on ToolArgumentError catch (e) {
      return ToolResult.failure(ToolResult.codeInvalidArguments, e.message);
    }
  }
}

class GetFocusSummaryTool extends _AnalyticsTool {
  const GetFocusSummaryTool(this._stats);
  final FocusStatisticsService _stats;

  @override
  String get name => 'get_focus_summary';
  @override
  String get description =>
      'A concise focus summary for a recent window (default 7 days): total '
      'focus time, session count, completion rate, and the top tasks by focus.';
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'days': {'type': 'integer'}
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final days = args.optInt('days') ?? 7;
        final s = await _stats.recent(days: days);
        final topTasks = [...s.perTask]
          ..sort((x, y) => y.focusMinutes.compareTo(x.focusMinutes));
        return ToolResult.ok({
          'windowDays': days,
          'totalFocusMinutes': s.totalFocusMinutes,
          'sessionCount': s.sessionCount,
          'completionRate': double.parse(s.completionRate.toStringAsFixed(4)),
          'activeDays': s.activeDays,
          'topTasks': [
            for (final t in topTasks.take(3))
              {'taskTitle': t.taskTitle, 'focusMinutes': t.focusMinutes}
          ],
        });
      }, a);
}

class GetProductivitySummaryTool extends _AnalyticsTool {
  const GetProductivitySummaryTool(this._tasks, this._stats);
  final TaskRepository _tasks;
  final FocusStatisticsService _stats;

  @override
  String get name => 'get_productivity_summary';
  @override
  String get description =>
      'A high-level productivity snapshot: how many visible tasks are complete '
      'vs outstanding, plus recent focus totals (default 7-day window).';
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'days': {'type': 'integer'}
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final days = args.optInt('days') ?? 7;
        final tasks = await _tasks.getTasks();
        final completed = tasks.where((t) => t.isCompleted).length;
        final s = await _stats.recent(days: days);
        return ToolResult.ok({
          'tasks': {
            'total': tasks.length,
            'completed': completed,
            'outstanding': tasks.length - completed,
          },
          'focus': {
            'windowDays': days,
            'totalFocusMinutes': s.totalFocusMinutes,
            'sessionCount': s.sessionCount,
          },
        });
      }, a);
}

/// Deterministic productivity metrics (Phase 11), computed by app code over
/// planned-vs-actual work derived from time intervals + focus. The model
/// INTERPRETS these numbers; it must not invent them.
class GetProductivityMetricsTool extends _AnalyticsTool {
  GetProductivityMetricsTool(this._builder, {this.service = const ProductivityMetricsService()});
  final MetricsSampleBuilder _builder;
  final ProductivityMetricsService service;

  @override
  String get name => 'get_productivity_metrics';
  @override
  String get description =>
      'Deterministic productivity metrics over a recent window (default 14 '
      'days): planning accuracy, execution rate, focus efficiency, estimation '
      'bias, reschedule rate, deadline miss rate, and workload score. Computed '
      'by the app from planned time intervals vs. actual focus — interpret '
      'these values, do not recompute them. Optionally pass availableMinutes '
      'to get a workload score.';
  @override
  Map<String, dynamic> get parametersSchema => const {
        'type': 'object',
        'properties': {
          'days': {'type': 'integer'},
          'availableMinutes': {
            'type': 'integer',
            'description': 'Capacity for the window, enables workloadScore.'
          },
        },
      };
  @override
  Future<ToolResult> execute(Map<String, dynamic> a) => guarded((args) async {
        final days = args.optInt('days') ?? 14;
        final availableMinutes = args.optInt('availableMinutes');
        final end = DateTime.now();
        final start = end.subtract(Duration(days: days));
        final samples = await _builder.build(start, end);
        final metrics = service.compute(
          samples,
          capacity: availableMinutes != null
              ? Capacity(availableMinutes: availableMinutes)
              : null,
          now: end,
        );
        return ToolResult.ok({
          'windowDays': days,
          ...metrics.toJson(),
        });
      }, a);
}

List<Tool> analyticsTools(
  TaskRepository tasks,
  TimeIntervalRepository timeIntervals,
  FocusRepository focus,
  FocusStatisticsService stats,
) =>
    [
      GetFocusSummaryTool(stats),
      GetProductivitySummaryTool(tasks, stats),
      GetProductivityMetricsTool(
        MetricsSampleBuilder(timeIntervals: timeIntervals, focus: focus),
      ),
    ];
