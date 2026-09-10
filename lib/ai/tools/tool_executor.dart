import '../core/ai_tool_call.dart';
import '../policy/action_policy.dart';
import '../policy/confirmation.dart';
import 'tool.dart';
import 'tool_registry.dart';
import 'tool_result.dart';

/// Decides whether a tool call may proceed. Returns null to allow, or a
/// human-readable reason to deny. This is a low-level, synchronous gate; the
/// richer [ActionPolicy] + [ConfirmationHandler] path is preferred.
typedef ToolPermissionCheck = String? Function(Tool tool, Map<String, dynamic> arguments);

/// Builds a short, human-readable summary of a proposed action for a
/// confirmation prompt. Defaults to a generic summary; callers can supply a
/// nicer one.
typedef ActionSummarizer = String Function(Tool tool, Map<String, dynamic> arguments);

/// Runs tool calls against a [ToolRegistry], turning every outcome into a
/// [ToolResult]. It never throws for a bad/unknown/failing tool — that keeps
/// the agent loop (Phase 4) fully in control.
///
/// Safety gate order for each call: malformed args → unknown tool →
/// [ToolPermissionCheck] (if any) → [ActionPolicy] (if any; may require a
/// [ConfirmationHandler]) → execute. A DESTRUCTIVE tool is never run without
/// explicit confirmation, and the LLM cannot bypass this.
class ToolExecutor {
  ToolExecutor(
    this._registry, {
    ToolPermissionCheck? permissionCheck,
    ActionPolicy? policy,
    ConfirmationHandler? confirm,
    ActionSummarizer? summarizer,
  })  : _permissionCheck = permissionCheck,
        _policy = policy,
        // When a policy is set but no handler is given, default to deny so no
        // write/destructive action can slip through unapproved.
        _confirm = confirm ?? (policy != null ? denyByDefaultConfirmation : null),
        _summarizer = summarizer;

  final ToolRegistry _registry;
  final ToolPermissionCheck? _permissionCheck;
  final ActionPolicy? _policy;
  final ConfirmationHandler? _confirm;
  final ActionSummarizer? _summarizer;

  /// Execute a model-produced [AiToolCall]. Rejects malformed arguments and
  /// unknown tools with structured failures.
  Future<ToolResult> executeCall(AiToolCall call) {
    if (call.hasMalformedArguments) {
      return Future.value(ToolResult.failure(
        ToolResult.codeInvalidArguments,
        'Tool "${call.name}" was called with malformed JSON arguments.',
      ));
    }
    return execute(call.name, call.arguments);
  }

  /// Execute a tool by [name] with [arguments].
  Future<ToolResult> execute(String name, Map<String, dynamic> arguments) async {
    final tool = _registry.lookup(name);
    if (tool == null) {
      return ToolResult.failure(
        ToolResult.codeUnknownTool,
        'No tool named "$name" is registered.',
      );
    }

    final denyReason = _permissionCheck?.call(tool, arguments);
    if (denyReason != null) {
      return ToolResult.failure(ToolResult.codePermissionDenied, denyReason);
    }

    // Action policy: classify and, if needed, ask the user to confirm.
    final policy = _policy;
    if (policy != null) {
      final decision = policy.evaluate(tool);
      if (decision == PolicyDecision.deny) {
        return ToolResult.failure(
            ToolResult.codePermissionDenied, policy.denyReason(tool));
      }
      if (decision == PolicyDecision.needsConfirmation) {
        final request = ConfirmationRequest(
          toolName: tool.name,
          risk: tool.risk,
          summary: _summarizer?.call(tool, arguments) ??
              'Run "${tool.name}" (${tool.risk.name}).',
          arguments: arguments,
        );
        // _confirm is non-null whenever _policy is non-null (defaults to deny).
        final approved = await _confirm!(request);
        if (!approved) {
          return ToolResult.failure(
            ToolResult.codePermissionDenied,
            'User did not approve "${tool.name}".',
          );
        }
      }
    }

    try {
      return await tool.execute(arguments);
    } catch (e) {
      // Defense in depth: a tool should convert its own errors, but if one
      // escapes we still return a structured failure instead of throwing.
      return ToolResult.failure(
        ToolResult.codeDomainError,
        'Tool "$name" failed: $e',
      );
    }
  }
}
