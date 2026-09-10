import 'package:flutter/material.dart';

import 'ai_models_controller.dart';

/// A model-management screen: view installed Ollama models, select the active
/// one, delete models, and pull new ones by name (with progress).
class AiModelsPage extends StatefulWidget {
  const AiModelsPage({super.key, this.controller});

  final AiModelsController? controller;

  @override
  State<AiModelsPage> createState() => _AiModelsPageState();
}

class _AiModelsPageState extends State<AiModelsPage> {
  late final AiModelsController _controller;
  final _pullField = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AiModelsController();
    _controller.addListener(_onChange);
    _controller.refresh();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _pullField.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: c.loading ? null : c.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _PullBar(
            field: _pullField,
            busy: c.pullingId != null,
            pullingId: c.pullingId,
            fraction: c.pullFraction,
            onPull: () {
              final name = _pullField.text.trim();
              if (name.isNotEmpty) {
                _pullField.clear();
                c.pull(name);
              }
            },
          ),
          if (c.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(c.message!,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const Divider(height: 1),
          Expanded(
            child: c.loading
                ? const Center(child: CircularProgressIndicator())
                : c.models.isEmpty
                    ? const Center(child: Text('No models installed.'))
                    : ListView.builder(
                        itemCount: c.models.length,
                        itemBuilder: (_, i) {
                          final m = c.models[i];
                          final isSelected = m.id == c.selectedId;
                          return ListTile(
                            leading: Icon(isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                            title: Text(m.name),
                            subtitle: isSelected
                                ? const Text('Active model')
                                : null,
                            onTap: () => c.select(m.id),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmDelete(m.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String modelId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text('Remove "$modelId" from the Ollama server?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) _controller.delete(modelId);
  }
}

class _PullBar extends StatelessWidget {
  const _PullBar({
    required this.field,
    required this.busy,
    required this.pullingId,
    required this.fraction,
    required this.onPull,
  });
  final TextEditingController field;
  final bool busy;
  final String? pullingId;
  final double? fraction;
  final VoidCallback onPull;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: field,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Pull a model (e.g. llama3.2)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => busy ? null : onPull(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : onPull,
                child: const Text('Pull'),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: fraction),
                ),
                const SizedBox(width: 8),
                Text(pullingId ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
