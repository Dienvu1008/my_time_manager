import '../../domain/models/model_ai_action_log.dart';
import '../core/ai_tool_call.dart';
import '../policy/action_policy.dart';
import '../policy/ai_action_log.dart';
import '../policy/confirmation.dart';
import 'tool.dart';
import 'tool_registry.dart';
import 'tool_result.dart';

/// Decides whether a tool call may proceed. Returns null to allow, or a
/// human-readable reason to deny. This is a low-level, synchronous gate; the
/// richer [ActionPolicy] + [ConfirmationHandler] path is preferred.
typedef ToolPermissionCheck = String? Function(
    Tool tool, Map<String, dynamic> arguments);

/// Builds a short, human-readable summary of a proposed action for a
/// confirmation prompt. Defaults to a generic summary; callers can supply a
/// nicer one.
typedef ActionSummarizer = String Function(
    Tool tool, Map<String, dynamic> arguments);

/// Runs tool calls against a [ToolRegistry], turning every outcome into a
/// [ToolResult]. It never throws for a bad/unknown/failing tool — that keeps
/// the agent loop (Phase 4) fully in control.
///
/// Safety gate order for each call: malformed args → unknown tool →
/// [ToolPermissionCheck] (if any) → [ActionPolicy] (if any; may require a
/// [ConfirmationHandler]) → execute. A DESTRUCTIVE tool is never run without
/// explicit confirmation, and the LLM cannot bypass this.
///
/// Audit (Phase C8b): this is the single choke point for every model tool
/// call, so every execution attempt of a WRITE / DESTRUCTIVE tool (resolved in
/// the registry) is recorded to the injected [AiActionLog] with one outcome:
/// `deniedByPolicy` (permission check / policy deny), `declined` (user said
/// no), `executed` (tool succeeded) or `failed` (tool failure, thrown error,
/// malformed JSON args). Read-only and unknown tools are not logged. Logging
/// never throws and never changes the returned [ToolResult].
class ToolExecutor {
  ToolExecutor(
    this._registry, {
    ToolPermissionCheck? permissionCheck,
    ActionPolicy? policy,
    ConfirmationHandler? confirm,
    ActionSummarizer? summarizer,
    AiActionLog actionLog = const NoOpAiActionLog(),
    String? Function()? conversationId,
    DateTime Function()? clock,
  })  : _permissionCheck = permissionCheck,
        _policy = policy,
        // When a policy is set but no handler is given, default to deny so no
        // write/destructive action can slip through unapproved.
        _confirm =
            confirm ?? (policy != null ? denyByDefaultConfirmation : null),
        _summarizer = summarizer,
        _actionLog = actionLog,
        _conversationId = conversationId,
        _clock = clock ?? DateTime.now;

  final ToolRegistry _registry;
  final ToolPermissionCheck? _permissionCheck;
  final ActionPolicy? _policy;
  final ConfirmationHandler? _confirm;
  final ActionSummarizer? _summarizer;
  final AiActionLog _actionLog;
  final String? Function()? _conversationId;
  final DateTime Function() _clock;

  /// Execute a model-produced [AiToolCall]. Rejects malformed arguments and
  /// unknown tools with structured failures.
  Future<ToolResult> executeCall(AiToolCall call) async {
    if (call.hasMalformedArguments) {
      final result = ToolResult.failure(
        ToolResult.codeInvalidArguments,
        'Tool "${call.name}" was called with malformed JSON arguments.',
      );
      final tool = _registry.lookup(call.name);
      if (tool != null) {
        await _log(tool, call.arguments, AiActionOutcome.failed,
            result: result);
      }
      return result;
    }
    return execute(call.name, call.arguments);
  }

  /// Execute a tool by [name] with [arguments].
  Future<ToolResult> execute(
      String name, Map<String, dynamic> arguments) async {
    final tool = _registry.lookup(name);
    if (tool == null) {
      return ToolResult.failure(
        ToolResult.codeUnknownTool,
        'No tool named "$name" is registered.',
      );
    }

    final denyReason = _permissionCheck?.call(tool, arguments);
    if (denyReason != null) {
      final result =
          ToolResult.failure(ToolResult.codePermissionDenied, denyReason);
      await _log(tool, arguments, AiActionOutcome.deniedByPolicy,
          result: result);
      return result;
    }

    // Action policy: classify and, if needed, ask the user to confirm.
    final policy = _policy;
    if (policy != null) {
      final decision = policy.evaluate(tool);
      if (decision == PolicyDecision.deny) {
        final result = ToolResult.failure(
            ToolResult.codePermissionDenied, policy.denyReason(tool));
        await _log(tool, arguments, AiActionOutcome.deniedByPolicy,
            result: result);
        return result;
      }
      if (decision == PolicyDecision.needsConfirmation) {
        final request = ConfirmationRequest(
          toolName: tool.name,
          risk: tool.risk,
          summary: _summarizer?.call(tool, arguments) ??
              switch (tool) {
                ConfirmationDescriber d => d.confirmationSummary(arguments),
                _ => 'Run "${tool.name}" (${tool.risk.name}).',
              },
          arguments: arguments,
        );
        // _confirm is non-null whenever _policy is non-null (defaults to deny).
        final approved = await _confirm!(request);
        if (!approved) {
          final result = ToolResult.failure(
            ToolResult.codePermissionDenied,
            'User did not approve "${tool.name}".',
          );
          await _log(tool, arguments, AiActionOutcome.declined, result: result);
          return result;
        }
      }
    }

    ToolResult result;
    try {
      result = await tool.execute(arguments);
    } catch (e) {
      // Defense in depth: a tool should convert its own errors, but if one
      // escapes we still return a structured failure instead of throwing.
      result = ToolResult.failure(
        ToolResult.codeDomainError,
        'Tool "$name" failed: $e',
      );
    }
    await _log(
      tool,
      arguments,
      result.success ? AiActionOutcome.executed : AiActionOutcome.failed,
      result: result,
    );
    return result;
  }

  Future<void> _log(
    Tool tool,
    Map<String, dynamic> arguments,
    AiActionOutcome outcome, {
    required ToolResult result,
  }) async {
    if (tool.risk == ToolRisk.readOnly) return;
    try {
      await _actionLog.record(AiActionLogEntry(
        createdAt: _clock(),
        toolName: tool.name,
        policyLevel: tool.risk.name,
        policyMode: _policy?.mode.name,
        argsSummary: AiActionLogFormat.summarizeArgs(arguments),
        outcome: outcome,
        resultSummary: AiActionLogFormat.summarizeResult(result),
        errorMessage: AiActionLogFormat.errorOf(result),
        conversationId: _conversationId?.call(),
      ));
    } catch (_) {
      // Auditing must never break the agent loop.
    }
  }
}
