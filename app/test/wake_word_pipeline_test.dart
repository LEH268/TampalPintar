import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/driving/wake_word/feature_math.dart';
import 'package:tampal_pintar/driving/wake_word/ort_runner.dart';
import 'package:tampal_pintar/driving/wake_word/wake_word_pipeline.dart';

class FakeRunner implements OrtRunner {
  FakeRunner(this.outputBuilder);
  final List<double> Function(List<double> input) outputBuilder;
  final List<List<int>> shapes = [];
  final List<List<double>> inputs = [];
  @override
  Future<List<double>> run(List<double> input, List<int> shape) async {
    shapes.add(shape);
    inputs.add(input);
    return outputBuilder(input);
  }
}

void main() {
  late FakeRunner mel, embedding, classifier;
  late WakeWordPipeline pipeline;

  setUp(() {
    // mel: returns 9 frames x 32 bins, every value 10.0 (normalizes to 3.0)
    mel = FakeRunner((_) => List.filled(9 * kMelBins, 10.0));
    // embedding: constant 96-vector of 0.5
    embedding = FakeRunner((_) => List.filled(kEmbeddingDim, 0.5));
    // classifier: score = first value of the stacked input (proves padding order)
    classifier = FakeRunner((input) => [input[0]]);
    pipeline = WakeWordPipeline(
        mel: mel, embedding: embedding, classifier: classifier);
  });

  Int16List chunk() => Int16List(kChunkSamples);

  test('warm-up: null until 76 mel frames exist (10 chunks)', () async {
    for (var i = 0; i < 9; i++) {
      expect(await pipeline.processChunk(chunk()), isNull, reason: 'chunk $i');
    }
    expect(await pipeline.processChunk(chunk()), isNotNull); // 10th -> 80 frames
    expect(embedding.shapes, hasLength(1));
  });

  test('shapes match the pinned contract', () async {
    for (var i = 0; i < 10; i++) {
      await pipeline.processChunk(chunk());
    }
    expect(mel.shapes.first, [1, kMelInputSamples]);
    expect(mel.inputs.first, hasLength(kMelInputSamples));
    expect(embedding.shapes.first, [1, kWindowFrames, kMelBins, 1]);
    expect(embedding.inputs.first, hasLength(kWindowFrames * kMelBins));
    expect(classifier.shapes.first, [1, kClassifierSteps, kEmbeddingDim]);
    expect(classifier.inputs.first,
        hasLength(kClassifierSteps * kEmbeddingDim));
  });

  test('first score sees zero left-padding, later scores see real rows',
      () async {
    double? first, later;
    for (var i = 0; i < 10; i++) {
      first = await pipeline.processChunk(chunk());
    }
    expect(first, 0.0); // 15 zero rows precede the single real embedding
    for (var i = 0; i < 15; i++) {
      later = await pipeline.processChunk(chunk());
    }
    expect(later, 0.5); // 16 real embeddings now -> first stacked value real
  });

  test('one embedding per chunk after warm-up; deque capped at 16', () async {
    for (var i = 0; i < 30; i++) {
      await pipeline.processChunk(chunk());
    }
    expect(embedding.shapes.length, 21); // chunks 10..30
    expect(classifier.inputs.last, hasLength(kClassifierSteps * kEmbeddingDim));
  });

  test(
      'mel input window is context(prev chunk tail) ++ current chunk, not current-chunk-only',
      () async {
    // Ramp fixtures: each sample's value depends on its position within the
    // chunk, so the test can distinguish a chunk's head from its tail (a
    // uniformly-filled chunk cannot). Integers chosen so /32768.0 is exact
    // in float32 (small integers, power-of-two denominator), and chunk A's
    // range never overlaps chunk B's range.
    final chunkA =
        Int16List.fromList([for (var i = 0; i < kChunkSamples; i++) 8192 + i]);
    final chunkB = Int16List.fromList(
        [for (var i = 0; i < kChunkSamples; i++) -16384 + i]);
    List<double> floatsOf(Int16List chunk, int start, int end) =>
        [for (var i = start; i < end; i++) chunk[i] / 32768.0];

    await pipeline.processChunk(chunkA);
    await pipeline.processChunk(chunkB);

    expect(mel.inputs, hasLength(2));

    final inputA = mel.inputs[0];
    expect(inputA, hasLength(kMelInputSamples));
    // Initial context is zero-filled.
    expect(inputA.sublist(0, kMelContextSamples),
        List.filled(kMelContextSamples, 0.0));
    // Chunk region is chunk A's ramp, head to tail, in order.
    expect(
        inputA.sublist(kMelContextSamples), floatsOf(chunkA, 0, kChunkSamples));

    final inputB = mel.inputs[1];
    expect(inputB, hasLength(kMelInputSamples));
    // The context must be chunk A's TAIL (previous chunk's last 480
    // samples), not chunk B's own tail and not chunk A's head -- this is
    // the assertion that catches a wrong-window bug where the mel input is
    // built from the wrong end of the previous chunk.
    expect(
        inputB.sublist(0, kMelContextSamples),
        floatsOf(chunkA, kChunkSamples - kMelContextSamples, kChunkSamples));
    expect(
        inputB.sublist(kMelContextSamples), floatsOf(chunkB, 0, kChunkSamples));
  });
}
