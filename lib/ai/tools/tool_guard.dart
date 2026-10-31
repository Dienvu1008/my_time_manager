import 'tool_args.dart';
import 'tool_result.dart';

const int _maxMessageLength = 300;

String _cap(String s) =>
    s.length <= _maxMessageLength ? s : '${s.substring(0, _maxMessageLength)}…';

/// Shared argument / error guard for every domain tool (Phase C8b).
///
/// Runs [body] with [ToolArgs] over [a] and converts anything that escapes
/// into a failed [ToolResult], so a tool NEVER throws into the agent loop:
/// - [ToolArgumentError], [ArgumentError] (incl. [RangeError]),
///   [FormatException] and [TypeError] (wrong-typed args) →
///   `invalid_arguments`;
/// - any other exception → `domain_error`.
Future<ToolResult> guardToolCall(
  Map<String, dynamic> a,
  Future<ToolResult> Function(ToolArgs args) body,
) async {
  try {
    return await body(ToolArgs(a));
  } on ToolArgumentError catch (e) {
    return ToolResult.failure(ToolResult.codeInvalidArguments, _cap(e.message));
  } on ArgumentError catch (e) {
    return ToolResult.failure(
        ToolResult.codeInvalidArguments, _cap('${e.message ?? e}'));
  } on FormatException catch (e) {
    return ToolResult.failure(ToolResult.codeInvalidArguments, _cap(e.message));
  } on TypeError catch (e) {
    return ToolResult.failure(
        ToolResult.codeInvalidArguments, _cap('Invalid argument type: $e'));
  } catch (e) {
    return ToolResult.failure(ToolResult.codeDomainError, _cap('$e'));
  }
}
