import '../core/ai_tool_definition.dart';
import 'tool_result.dart';

/// How risky a tool is. The permission model (Phase 6) uses this; it is
/// declared here so every tool states its risk up front.
enum ToolRisk {
  /// Reads only; never mutates data.
  readOnly,

  /// Creates or updates data.
  write,

  /// Deletes data or is otherwise hard to reverse.
  destructive,
}

/// A single capability the agent can invoke. Each tool exposes a stable [name],
/// a human/LLM-readable [description], a JSON-schema for its arguments, its
/// [risk] class, and an [execute] implementation that calls the DOMAIN layer
/// (repositories/services) — never SQLite directly.
///
/// Tools must validate their arguments and translate domain errors into a
/// failed [ToolResult] rather than throwing, so the agent loop stays in control.
abstract class Tool {
  const Tool();

  /// Unique tool name (snake_case), e.g. `list_tasks`.
  String get name;

  /// What the tool does, written for the model to decide when to call it.
  String get description;

  /// Risk classification used by the permission model.
  ToolRisk get risk;

  /// JSON-Schema (object) describing the arguments. Empty properties = no args.
  Map<String, dynamic> get parametersSchema =>
      const {'type': 'object', 'properties': {}};

  /// Execute the tool with already-parsed [arguments]. Implementations should
  /// return [ToolResult.ok]/[ToolResult.failure] and avoid throwing.
  Future<ToolResult> execute(Map<String, dynamic> arguments);

  /// The provider-independent definition advertised to the AI engine.
  AiToolDefinition get definition => AiToolDefinition(
        name: name,
        description: description,
        parametersSchema: parametersSchema,
      );
}

/// Opt-in for tools that can describe a proposed call in human-readable terms
/// for the confirmation prompt (e.g. `Create goal "Learn Spanish"`). Built
/// synchronously from the arguments only. The [ToolExecutor] uses it when no
/// explicit summarizer is given; tools without it keep the generic summary.
abstract interface class ConfirmationDescriber {
  String confirmationSummary(Map<String, dynamic> arguments);
}
