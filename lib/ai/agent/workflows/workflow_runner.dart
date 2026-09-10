import '../../context/context_builder.dart';
import '../../core/ai_cancellation_token.dart';
import '../agent_result.dart';
import '../agent_runtime.dart';
import 'agent_workflow.dart';

/// Runs a high-level [AgentWorkflow] on an existing [AgentRuntime].
///
/// A workflow is just the base agent loop plus workflow-specific guidance and
/// an opening message — it reuses the same tools, action policy, and
/// confirmation flow. This keeps the "execution agent" a thin orchestration
/// layer, not a parallel engine.
class WorkflowRunner {
  WorkflowRunner({
    required AgentRuntime agentRuntime,
    ContextBuilder? contextBuilder,
  })  : _agent = agentRuntime,
        _context = contextBuilder;

  final AgentRuntime _agent;
  final ContextBuilder? _context;

  /// Run [workflow], building fresh context if a [ContextBuilder] was provided.
  Future<AgentResult> run(
    AgentWorkflow workflow, {
    AiCancellationToken? cancelToken,
  }) async {
    String? contextText;
    final context = _context;
    if (context != null) {
      final ctx = await context.build();
      contextText = ctx.render();
    }
    return _agent.run(
      workflow.openingMessage,
      contextText: contextText,
      extraSystemPrompt: workflow.guidance,
      cancelToken: cancelToken,
    );
  }
}
