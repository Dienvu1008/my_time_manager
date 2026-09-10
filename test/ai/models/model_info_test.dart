import 'package:flutter_test/flutter_test.dart';
import 'package:my_time_manager/ai/models/model_info.dart';
import 'package:my_time_manager/ai/models/model_registry.dart';

void main() {
  group('ModelInfo', () {
    test('json round-trip preserves fields', () {
      const info = ModelInfo(
        id: 'phi3-mini.gguf',
        name: 'Phi-3 Mini',
        format: ModelFormat.gguf,
        sizeBytes: 2200000000,
        capabilities: ModelCapabilities(toolCalling: true, contextLength: 4096),
        downloadUrl: 'https://example.com/phi3.gguf',
        checksum: 'sha256:abc',
        platformSupport: {'android': true, 'ios': false},
        installed: false,
      );
      final restored = ModelInfo.fromJson(info.toJson());
      expect(restored.id, 'phi3-mini.gguf');
      expect(restored.format, ModelFormat.gguf);
      expect(restored.sizeBytes, 2200000000);
      expect(restored.capabilities.toolCalling, isTrue);
      expect(restored.downloadUrl, 'https://example.com/phi3.gguf');
      expect(restored.checksum, 'sha256:abc');
      expect(restored.platformSupport['ios'], false);
    });

    test('supportsPlatform defaults to true when unspecified', () {
      const info = ModelInfo(id: 'm', name: 'M', format: ModelFormat.ollama);
      expect(info.supportsPlatform('windows'), isTrue);
    });

    test('supportsPlatform respects explicit false', () {
      const info = ModelInfo(
        id: 'm',
        name: 'M',
        format: ModelFormat.gguf,
        platformSupport: {'ios': false},
      );
      expect(info.supportsPlatform('ios'), isFalse);
      expect(info.supportsPlatform('android'), isTrue);
    });

    test('unknown format wire name throws', () {
      expect(() => ModelFormat.fromWireName('xyz'), throwsArgumentError);
    });
  });

  group('ModelRegistry', () {
    final reg = ModelRegistry([
      const ModelInfo(id: 'llama3', name: 'Llama 3', format: ModelFormat.ollama),
      const ModelInfo(
        id: 'phi3.gguf',
        name: 'Phi-3',
        format: ModelFormat.gguf,
        platformSupport: {'windows': false},
      ),
    ]);

    test('byId looks up a model', () {
      expect(reg.byId('llama3')!.name, 'Llama 3');
      expect(reg.byId('missing'), isNull);
    });

    test('ofFormat filters by format', () {
      expect(reg.ofFormat(ModelFormat.gguf).single.id, 'phi3.gguf');
    });

    test('supportedOn filters out unsupported platforms', () {
      final onWindows = reg.supportedOn('windows').map((m) => m.id).toList();
      expect(onWindows, contains('llama3')); // unspecified => supported
      expect(onWindows, isNot(contains('phi3.gguf'))); // explicitly false
    });
  });
}
