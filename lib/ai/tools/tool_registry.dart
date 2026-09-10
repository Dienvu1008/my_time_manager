import '../core/ai_tool_definition.dart';
import 'tool.dart';

/// Holds the set of tools available to the agent and looks them up by name.
/// Tool names must be unique; registering a duplicate name is a programming
/// error.
class ToolRegistry {
  ToolRegistry([Iterable<Tool> tools = const []]) {
    for (final tool in tools) {
      register(tool);
    }
  }

  final Map<String, Tool> _tools = {};

  void register(Tool tool) {
    if (_tools.containsKey(tool.name)) {
      throw StateError('Duplicate tool name: "${tool.name}"');
    }
    _tools[tool.name] = tool;
  }

  /// Look up a tool by name, or null if unknown.
  Tool? lookup(String name) => _tools[name];

  bool contains(String name) => _tools.containsKey(name);

  /// All registered tools, in registration order.
  List<Tool> get tools => _tools.values.toList(growable: false);

  /// The definitions to advertise to the AI engine (for [AiRequest.tools]).
  List<AiToolDefinition> get definitions =>
      tools.map((t) => t.definition).toList(growable: false);
}
