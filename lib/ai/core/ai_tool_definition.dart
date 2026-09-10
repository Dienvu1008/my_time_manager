/// A provider-independent description of a tool the model may call. This is the
/// *shape* advertised to the engine (name + description + JSON-schema of
/// arguments); the actual execution lives in the tool system (Phase 3).
///
/// [parametersSchema] is a JSON-Schema object describing the arguments. Keeping
/// it as a plain map avoids coupling core to any schema library and lets each
/// provider translate it to its own function-calling format.
class AiToolDefinition {
  const AiToolDefinition({
    required this.name,
    required this.description,
    this.parametersSchema = const {'type': 'object', 'properties': {}},
  });

  final String name;
  final String description;
  final Map<String, dynamic> parametersSchema;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parametersSchema': parametersSchema,
      };

  factory AiToolDefinition.fromJson(Map<String, dynamic> json) {
    return AiToolDefinition(
      name: json['name'] as String,
      description: json['description'] as String,
      parametersSchema:
          (json['parametersSchema'] as Map<String, dynamic>?) ??
              const {'type': 'object', 'properties': {}},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiToolDefinition &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() => 'AiToolDefinition(name: $name)';
}
