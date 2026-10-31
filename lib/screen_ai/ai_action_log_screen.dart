import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_localizations.dart';
import '../domain/models/model_ai_action_log.dart';
import '../domain/repositories/ai_action_log_repository.dart';

/// Localized label of an [AiActionOutcome].
String aiOutcomeLabel(AppLocalizations l, AiActionOutcome o) => switch (o) {
      AiActionOutcome.executed => l.aiOutcomeExecuted,
      AiActionOutcome.declined => l.aiOutcomeDeclined,
      AiActionOutcome.failed => l.aiOutcomeFailed,
      AiActionOutcome.deniedByPolicy => l.aiOutcomeDeniedByPolicy,
    };

IconData _outcomeIcon(AiActionOutcome o) => switch (o) {
      AiActionOutcome.executed => Icons.check_circle_outline,
      AiActionOutcome.declined => Icons.block_outlined,
      AiActionOutcome.failed => Icons.error_outline,
      AiActionOutcome.deniedByPolicy => Icons.gpp_bad_outlined,
    };

String _pad2(int n) => n.toString().padLeft(2, '0');

String _fmt(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)} '
    '${_pad2(d.hour)}:${_pad2(d.minute)}';

/// Read-only "AI activity log" (Phase C8b): every write / destructive action
/// the AI assistant attempted, newest first, filterable by outcome. The only
/// mutation offered is clearing the whole log (after confirmation).
class AiActionLogScreen extends StatefulWidget {
  const AiActionLogScreen({super.key});

  @override
  State<AiActionLogScreen> createState() => _AiActionLogScreenState();
}

class _AiActionLogScreenState extends State<AiActionLogScreen> {
  late final AiActionLogRepository _repo;
  AiActionOutcome? _filter;
  late Future<List<AiActionLogEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _repo = context.read<AiActionLogRepository>();
    _entries = _load();
  }

  Future<List<AiActionLogEntry>> _load() => _repo.getEntries(outcome: _filter);

  void _refresh() => setState(() {
        _entries = _load();
      });

  Future<void> _confirmClear() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.aiActivityLogClear),
        content: Text(l.aiActivityLogClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.clear();
    if (mounted) _refresh();
  }

  void _showDetails(AiActionLogEntry e) {
    final l = AppLocalizations.of(context)!;
    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                SelectableText(value),
              ],
            ),
          );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(e.toolName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${aiOutcomeLabel(l, e.outcome)} · ${_fmt(e.createdAt)}'),
              const SizedBox(height: 12),
              row(l.aiActionRiskLevel, e.policyLevel),
              row(l.aiActionPolicyMode, e.policyMode),
              row(l.aiActionArguments, e.argsSummary),
              row(l.aiActionResult, e.resultSummary),
              row(l.aiActionError, e.errorMessage),
              row(l.aiActionConversation, e.conversationId),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filters = <AiActionOutcome?>[null, ...AiActionOutcome.values];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.aiActivityLog),
        actions: [
          IconButton(
            tooltip: l.aiActivityLogClear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l.aiActivityLogInfo
                  .replaceAll('{n}', '${AiActionLogRetention.maxEntries}')
                  .replaceAll(
                      '{days}', '${AiActionLogRetention.maxAge.inDays}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final f in filters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                          f == null ? l.aiOutcomeAll : aiOutcomeLabel(l, f)),
                      selected: _filter == f,
                      onSelected: (_) {
                        _filter = f;
                        _refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AiActionLogEntry>>(
              future: _entries,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const <AiActionLogEntry>[];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.aiActivityLogEmpty,
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    final label = aiOutcomeLabel(l, e.outcome);
                    return ListTile(
                      leading: Semantics(
                        label: label,
                        child: ExcludeSemantics(
                          child: Icon(_outcomeIcon(e.outcome)),
                        ),
                      ),
                      title: Text(e.toolName),
                      subtitle: Text('$label · ${_fmt(e.createdAt)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetails(e),
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
