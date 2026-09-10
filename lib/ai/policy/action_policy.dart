import '../tools/tool.dart';

/// The decision a policy makes for a tool call before it runs.
enum PolicyDecision {
  /// Run immediately.
  allow,

  /// Run only after the user explicitly confirms.
  needsConfirmation,

  /// Never run in the current mode.
  deny,
}

/// How permissive the agent is with data-modifying tools. Local-first and safe
/// by default.
enum PolicyMode {
  /// Only read-only tools run automatically. Writes need confirmation;
  /// destructive actions also need confirmation. (Recommended default.)
  confirmWrites,

  /// Writes run automatically; destructive actions still need confirmation.
  autoWrites,

  /// Read-only only: any write or destructive action is denied outright.
  readOnly,
}

/// Classifies a tool call into a [PolicyDecision] based on the tool's
/// [ToolRisk] and the configured [PolicyMode]. Pure and synchronous — the
/// async "ask the user" step is handled by the executor via a
/// ConfirmationHandler.
///
/// Invariant: a DESTRUCTIVE tool is NEVER auto-allowed. It is either denied
/// (readOnly mode) or requires explicit confirmation. This is the rule the LLM
/// cannot bypass.
class ActionPolicy {
  const ActionPolicy({this.mode = PolicyMode.confirmWrites});

  final PolicyMode mode;

  PolicyDecision evaluate(Tool tool) {
    switch (tool.risk) {
      case ToolRisk.readOnly:
        return PolicyDecision.allow;

      case ToolRisk.write:
        switch (mode) {
          case PolicyMode.readOnly:
            return PolicyDecision.deny;
          case PolicyMode.confirmWrites:
            return PolicyDecision.needsConfirmation;
          case PolicyMode.autoWrites:
            return PolicyDecision.allow;
        }

      case ToolRisk.destructive:
        // Never auto-allowed, regardless of mode.
        switch (mode) {
          case PolicyMode.readOnly:
            return PolicyDecision.deny;
          case PolicyMode.confirmWrites:
          case PolicyMode.autoWrites:
            return PolicyDecision.needsConfirmation;
        }
    }
  }

  /// A human-readable reason used when a call is denied outright.
  String denyReason(Tool tool) =>
      'Tool "${tool.name}" (${tool.risk.name}) is not permitted in '
      '${mode.name} mode.';
}
