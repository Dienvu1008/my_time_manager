import 'ai_response.dart';
import 'ai_tool_call.dart';

/// An event emitted while streaming a generation. Sealed so callers can switch
/// exhaustively. Provider-independent.
sealed class AiStreamEvent {
  const AiStreamEvent();
}

/// A chunk of generated text.
class AiTextDelta extends AiStreamEvent {
  const AiTextDelta(this.text);
  final String text;

  @override
  bool operator ==(Object other) =>
      other is AiTextDelta && other.text == text;
  @override
  int get hashCode => text.hashCode;
  @override
  String toString() => 'AiTextDelta("$text")';
}

/// The model finished assembling a tool call.
class AiToolCallEvent extends AiStreamEvent {
  const AiToolCallEvent(this.toolCall);
  final AiToolCall toolCall;

  @override
  bool operator ==(Object other) =>
      other is AiToolCallEvent && other.toolCall == toolCall;
  @override
  int get hashCode => toolCall.hashCode;
  @override
  String toString() => 'AiToolCallEvent($toolCall)';
}

/// Streaming completed successfully. Carries the assembled final response so a
/// caller that only cares about the end result can use it directly.
class AiStreamDone extends AiStreamEvent {
  const AiStreamDone(this.response);
  final AiResponse response;

  @override
  bool operator ==(Object other) =>
      other is AiStreamDone && other.response.toString() == response.toString();
  @override
  int get hashCode => response.toString().hashCode;
  @override
  String toString() => 'AiStreamDone($response)';
}

/// An error occurred mid-stream. The stream should close after this event.
class AiStreamError extends AiStreamEvent {
  const AiStreamError(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      other is AiStreamError && other.message == message;
  @override
  int get hashCode => message.hashCode;
  @override
  String toString() => 'AiStreamError($message)';
}
