import 'package:flutter/material.dart';

import '../ai/config/ai_config.dart';
import 'ai_models_page.dart';
import 'ai_settings_controller.dart';

/// A small settings screen for the AI assistant: choose the Ollama endpoint,
/// pick an installed model, set the privacy/execution mode, test the
/// connection, and save. Values persist via AiConfigService.
class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key, this.controller});

  /// Optional injected controller (for tests); a default is created otherwise.
  final AiSettingsController? controller;

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final AiSettingsController _controller;
  late final TextEditingController _endpoint;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AiSettingsController();
    _endpoint = TextEditingController();
    _controller.addListener(_onChange);
    _controller.init().then((_) {
      if (mounted) {
        _endpoint.text = _controller.config.endpoint ?? '';
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _endpoint.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final cfg = c.config;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Server', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _endpoint,
            decoration: InputDecoration(
              labelText: 'Ollama endpoint',
              hintText: AiConfig.defaultOllamaEndpoint,
              border: const OutlineInputBorder(),
              helperText: 'Leave blank to use ${AiConfig.defaultOllamaEndpoint}',
            ),
            onChanged: c.setEndpoint,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: c.isBusy ? null : c.refreshModels,
                icon: const Icon(Icons.refresh),
                label: const Text('Load models'),
              ),
              OutlinedButton.icon(
                onPressed: c.isBusy ? null : c.testConnection,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiModelsPage(),
                  ),
                ),
                icon: const Icon(Icons.storage_outlined),
                label: const Text('Manage models'),
              ),
              if (c.status == AiSettingsStatus.loadingModels ||
                  c.status == AiSettingsStatus.testing) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text('Model', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (c.models.isEmpty)
            Text(
              'No models loaded. Enter the endpoint and tap "Load models".',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            DropdownButtonFormField<String>(
              initialValue: c.models.contains(cfg.defaultModel)
                  ? cfg.defaultModel
                  : null,
              decoration: const InputDecoration(
                labelText: 'Default model',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final m in c.models)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: c.isBusy ? null : c.setModel,
            ),
          const SizedBox(height: 16),
          Text('Privacy mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<AiMode>(
            initialValue: cfg.mode,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final m in AiMode.values)
                DropdownMenuItem(
                    value: m, child: Text(_ModeSelector._labels[m] ?? m.name)),
            ],
            onChanged: c.isBusy
                ? null
                : (v) => v == null ? null : c.setMode(v),
          ),
          const SizedBox(height: 16),
          Text('Timezone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Use device timezone'),
            subtitle: Text('Device: ${c.deviceTimezone}'),
            value: c.usingDeviceTimezone,
            contentPadding: EdgeInsets.zero,
            onChanged: (useDevice) {
              // On → clear override (device default). Off → pick device zone as
              // a starting explicit override the user can then change.
              c.setTimezone(useDevice ? null : c.deviceTimezone);
            },
          ),
          if (!c.usingDeviceTimezone)
            DropdownButtonFormField<String>(
              initialValue: c.availableTimezones.contains(cfg.timezone)
                  ? cfg.timezone
                  : null,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final tz in c.availableTimezones)
                  DropdownMenuItem(value: tz, child: Text(tz)),
              ],
              onChanged: (tz) => tz == null ? null : c.setTimezone(tz),
            ),
          const SizedBox(height: 8),
          Text('The assistant will interpret times in: ${c.effectiveTimezoneName}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Chat history',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: c.chatHistoryRetentionDays ?? 0,
            decoration: const InputDecoration(
              labelText: 'Auto-delete old conversations',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Keep forever')),
              DropdownMenuItem(value: 7, child: Text('After 7 days')),
              DropdownMenuItem(value: 30, child: Text('After 30 days')),
              DropdownMenuItem(value: 90, child: Text('After 90 days')),
              DropdownMenuItem(value: 180, child: Text('After 180 days')),
              DropdownMenuItem(value: 365, child: Text('After 365 days')),
            ],
            onChanged: (v) => c.setChatHistoryRetentionDays(v),
          ),
          const SizedBox(height: 8),
          Text(
            c.chatHistoryRetentionDays == null
                ? 'Conversations are kept until you delete them.'
                : 'Conversations inactive for more than '
                    '${c.chatHistoryRetentionDays} days are deleted automatically '
                    'when you open the assistant.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: c.isBusy
                ? null
                : () async {
                    await c.save();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI settings saved.')),
                      );
                    }
                  },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          if (c.message != null) ...[
            const SizedBox(height: 12),
            Text(c.message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Human-readable labels for the privacy modes.
class _ModeSelector {
  const _ModeSelector._();
  static const _labels = {
    AiMode.localOnly: 'Local only (data stays on device)',
    AiMode.hybrid: 'Hybrid (prefer local, cloud fallback)',
    AiMode.cloudOptional: 'Cloud optional',
  };
}
