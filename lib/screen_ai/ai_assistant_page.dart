import 'package:flutter/material.dart';

import '../ai/agent/workflows/agent_workflow.dart';
import '../ai/policy/confirmation.dart';
import 'ai_assistant_controller.dart';

/// A simple AI Assistant screen. It shows the transcript, a live status line
/// (thinking / running a tool), an input box with send/cancel, and prompts the
/// user to approve or reject actions the agent proposes.
///
/// The [controller] is injected (built from the AI stack in app.dart); this
/// widget is intentionally thin — all orchestration lives in the controller.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key, required this.controller});

  final AiAssistantController controller;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  AiAssistantController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    // Route confirmation prompts to a dialog.
    _controller.confirmationHandler = _confirm;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
    // Auto-scroll to the newest message after a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _confirm(ConfirmationRequest request) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve action?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.summary),
            const SizedBox(height: 8),
            Text('Tool: ${request.toolName} (${request.risk.name})',
                style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    return approved ?? false;
  }

  void _send() {
    final text = _input.text;
    if (text.trim().isEmpty || _controller.isBusy) return;
    _input.clear();
    _controller.send(text);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _controller.messages;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: _controller.isBusy ? null : _controller.reset,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const _EmptyHint()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
                  ),
          ),
          if (!_controller.isBusy)
            _WorkflowBar(
              onRun: (w) => _controller.runWorkflow(w),
            ),
          if (_controller.isBusy) _StatusBar(controller: _controller),
          _InputBar(
            input: _input,
            busy: _controller.isBusy,
            onSend: _send,
            onCancel: _controller.cancel,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Ask about your tasks, calendar, or focus time.\n'
          'e.g. "What should I focus on today?"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AiChatMessage message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bg;
    final Alignment align;
    if (message.isUser) {
      bg = theme.colorScheme.primaryContainer;
      align = Alignment.centerRight;
    } else if (message.isError) {
      bg = theme.colorScheme.errorContainer;
      align = Alignment.centerLeft;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      align = Alignment.centerLeft;
    }
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(message.text),
      ),
    );
  }
}

class _WorkflowBar extends StatelessWidget {
  const _WorkflowBar({required this.onRun});
  final void Function(AgentWorkflow) onRun;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final w in AgentWorkflow.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: Text(w.title),
                onPressed: () => onRun(w),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});
  final AiAssistantController controller;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.statusDetail.isEmpty
                  ? 'Working…'
                  : controller.statusDetail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.input,
    required this.busy,
    required this.onSend,
    required this.onCancel,
  });
  final TextEditingController input;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Message the assistant…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            busy
                ? IconButton.filledTonal(
                    tooltip: 'Cancel',
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop),
                  )
                : IconButton.filled(
                    tooltip: 'Send',
                    onPressed: onSend,
                    icon: const Icon(Icons.send),
                  ),
          ],
        ),
      ),
    );
  }
}
