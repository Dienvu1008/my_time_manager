import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/core/ai_cancellation_token.dart';
import 'package:my_time_manager/ai/core/ai_message.dart';
import 'package:my_time_manager/ai/core/ai_request.dart';
import 'package:my_time_manager/ai/core/ai_response.dart';
import 'package:my_time_manager/ai/core/ai_stream_event.dart';
import 'package:my_time_manager/ai/providers/llama_cpp/llama_backend.dart';
import 'package:my_time_manager/ai/providers/llama_cpp/llama_cpp_ai_engine.dart';

/// A scripted fake backend — no native llama.cpp needed.
class _FakeBackend implements LlamaBackend {
  _FakeBackend(this._events, {this.failLoad = false});
  final List<LlamaGenerationEvent> _events;
  final bool failLoad;

  bool _loaded = false;
  int cancelCount = 0;
  LlamaPrompt? lastPrompt;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load(String modelPath) async {
    if (failLoad) throw StateError('cannot load');
    _loaded = true;
  }

  @override
  Stream<LlamaGenerationEvent> generate(LlamaPrompt prompt) async* {
    lastPrompt = prompt;
    for (final e in _events) {
      yield e;
    }
  }

  @override
  void cancel() => cancelCount++;

  @override
  Future<void> dispose() async {}
}

const _req = AiRequest(messages: [
  AiMessage.system('You are helpful.'),
  AiMessage.user('Hello'),
]);

void main() {
  test('capabilities: streaming yes, tool-calling no', () {
    final engine = LlamaCppAiEngine(
        backend: _FakeBackend(const []), modelPath: '/models/m.gguf');
    expect(engine.capabilities.streaming, isTrue);
    expect(engine.capabilities.toolCalling, isFalse);
    expect(engine.id, 'llama_cpp');
  });

  test('isAvailable true for a non-empty model path', () async {
    final engine = LlamaCppAiEngine(
        backend: _FakeBackend(const []), modelPath: '/models/m.gguf');
    expect(await engine.isAvailable(), isTrue);
    final empty =
        LlamaCppAiEngine(backend: _FakeBackend(const []), modelPath: '');
    expect(await empty.isAvailable(), isFalse);
  });

  test('stream emits deltas then a done event with assembled text', () async {
    final backend = _FakeBackend(const [
      LlamaToken('Hel'),
      LlamaToken('lo!'),
      LlamaDone('stop'),
    ]);
    final engine =
        LlamaCppAiEngine(backend: backend, modelPath: '/models/m.gguf');

    final events = await engine.stream(_req).toList();
    final deltas = events.whereType<AiTextDelta>().map((e) => e.text).toList();
    expect(deltas, ['Hel', 'lo!']);
    final done = events.last as AiStreamDone;
    expect(done.response.text, 'Hello!');
    expect(done.response.finishReason, AiFinishReason.stop);
  });

  test('generate assembles the full text', () async {
    final backend = _FakeBackend(const [
      LlamaToken('Two '),
      LlamaToken('tokens'),
      LlamaDone('stop'),
    ]);
    final engine =
        LlamaCppAiEngine(backend: backend, modelPath: '/models/m.gguf');
    final resp = await engine.generate(_req);
    expect(resp.text, 'Two tokens');
  });

  test('backend failure surfaces as a stream error', () async {
    final backend = _FakeBackend(const [LlamaFailure('oom')]);
    final engine =
        LlamaCppAiEngine(backend: backend, modelPath: '/models/m.gguf');
    final events = await engine.stream(_req).toList();
    expect(events.single, isA<AiStreamError>());
  });

  test('load failure surfaces as a stream error', () async {
    final backend = _FakeBackend(const [], failLoad: true);
    final engine =
        LlamaCppAiEngine(backend: backend, modelPath: '/models/m.gguf');
    final events = await engine.stream(_req).toList();
    expect(events.single, isA<AiStreamError>());
  });

  test('pre-cancelled token yields a single error event', () async {
    final backend = _FakeBackend(const [LlamaToken('x'), LlamaDone('stop')]);
    final engine =
        LlamaCppAiEngine(backend: backend, modelPath: '/models/m.gguf');
    final token = AiCancellationToken()..cancel();
    final events = await engine.stream(_req, cancelToken: token).toList();
    expect(events.single, isA<AiStreamError>());
  });

  test('renderPrompt lays out roles and ends awaiting the assistant', () {
    final prompt = LlamaCppAiEngine.renderPrompt(const [
      AiMessage.system('SYS'),
      AiMessage.user('hi'),
      AiMessage.assistant('prev'),
    ]);
    expect(prompt, contains('[System]\nSYS'));
    expect(prompt, contains('[User]\nhi'));
    expect(prompt.trimRight().endsWith('[Assistant]'), isTrue);
  });
}
