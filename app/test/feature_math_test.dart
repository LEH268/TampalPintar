import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/driving/wake_word/feature_math.dart';

void main() {
  test('toFloat32 normalizes to [-1,1]', () {
    final f = toFloat32(Int16List.fromList([-32768, 0, 16384, 32767]));
    expect(f[0], -1.0);
    expect(f[1], 0.0);
    expect(f[2], 0.5);
    expect(f[3], closeTo(0.99997, 1e-4));
  });

  test('buildMelInput is context ++ chunk (1760 samples)', () {
    final ctx = Float32List.fromList(List.filled(kMelContextSamples, 0.25));
    final chunk = Float32List.fromList(List.filled(kChunkSamples, -0.5));
    final input = buildMelInput(ctx, chunk);
    expect(input.length, kMelInputSamples);
    expect(input[0], 0.25);
    expect(input[kMelContextSamples - 1], 0.25);
    expect(input[kMelContextSamples], -0.5);
    expect(input[kMelInputSamples - 1], -0.5);
  });

  test('normalizeAndTakeLast applies x/10+2 and keeps the last 8 frames', () {
    // 9 frames of 32 bins; frame i filled with value i*10 (so norm -> i+2)
    final raw = <double>[
      for (var i = 0; i < 9; i++) ...List.filled(kMelBins, i * 10.0)
    ];
    final frames = normalizeAndTakeLast(raw);
    expect(frames, hasLength(kNewFramesPerChunk));
    expect(frames.first.first, closeTo(1 + 2, 1e-9)); // frame index 1
    expect(frames.last.first, closeTo(8 + 2, 1e-9));  // frame index 8
    expect(frames.first, hasLength(kMelBins));
  });

  test('flattenWindow is row-major oldest-first', () {
    final frames = [
      for (var i = 0; i < kWindowFrames; i++) List.filled(kMelBins, i.toDouble())
    ];
    final flat = flattenWindow(frames);
    expect(flat.length, kWindowFrames * kMelBins);
    expect(flat[0], 0.0);
    expect(flat[kMelBins], 1.0);
    expect(flat[flat.length - 1], (kWindowFrames - 1).toDouble());
  });

  test('stackLast16 zero-pads on the left', () {
    final embs = [
      Float32List.fromList(List.filled(kEmbeddingDim, 1.0)),
      Float32List.fromList(List.filled(kEmbeddingDim, 2.0)),
    ];
    final stacked = stackLast16(embs);
    expect(stacked.length, kClassifierSteps * kEmbeddingDim);
    expect(stacked[0], 0.0); // 14 padded rows first
    expect(stacked[13 * kEmbeddingDim], 0.0);
    expect(stacked[14 * kEmbeddingDim], 1.0);
    expect(stacked[15 * kEmbeddingDim], 2.0);
  });

  test('stackLast16 keeps only the newest 16', () {
    final embs = [
      for (var i = 0; i < 20; i++)
        Float32List.fromList(List.filled(kEmbeddingDim, i.toDouble()))
    ];
    final stacked = stackLast16(embs);
    expect(stacked[0], 4.0); // rows 4..19
    expect(stacked[15 * kEmbeddingDim], 19.0);
  });
}
