import '../tools/tool.dart';

/// A request presented to the user (via the UI in Phase 7) to approve or reject
/// a proposed action before it runs. Provider-independent and inspectable.
class ConfirmationRequest {
  const ConfirmationRequest({
    required this.toolName,
    required this.risk,
    required this.summary,
    required this.arguments,
  });

  /// The tool the agent proposes to run.
  final String toolName;

  /// The tool's risk class.
  final ToolRisk risk;

  /// A short, human-readable description of what will happen.
  final String summary;

  /// The exact arguments the tool would run with (so the UI can show details).
  final Map<String, dynamic> arguments;

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'risk': risk.name,
        'summary': summary,
        'arguments': arguments,
      };

  @override
  String toString() => 'ConfirmationRequest($toolName, ${risk.name}: $summary)';
}

/// Asks the user to approve a proposed action. Returns true to proceed, false
/// to reject. The UI supplies this in Phase 7.
typedef ConfirmationHandler = Future<bool> Function(ConfirmationRequest request);

/// A safe default handler for headless/automated contexts: it rejects anything
/// that needs confirmation. This guarantees that, without an explicit UI
/// handler, no write/destructive action can slip through unapproved.
Future<bool> denyByDefaultConfirmation(ConfirmationRequest request) async =>
    false;

/// A handler that approves everything — for tests or an explicit "auto-approve"
/// mode the user opts into. Never the default.
Future<bool> approveAllConfirmation(ConfirmationRequest request) async => true;
