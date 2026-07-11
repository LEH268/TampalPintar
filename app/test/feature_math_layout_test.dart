import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/driving/wake_word/feature_math.dart';

// The existing feature_math_test.dart uses frames/embeddings where every
// bin/dim within a row holds the SAME value, so a transposed inner index
// (bin swapped for frame, or vice versa) still passes. These tests use
// distinct per-cell values so a transposed index produces a different,
// detectably-wrong number.
void main() {
  test('flattenWindow: distinct per-cell values pin exact row-major layout',
      () {
    // frames[f][b] = f * 100.0 + b -- every (frame, bin) cell is unique.
    final frames = [
      for (var f = 0; f < kWindowFrames; f++)
        [for (var b = 0; b < kMelBins; b++) f * 100.0 + b]
    ];
    final flat = flattenWindow(frames);

    expect(flat.length, kWindowFrames * kMelBins);
    expect(flat[0], 0.0); // frame 0, bin 0
    expect(flat[1], 1.0); // frame 0, bin 1 -- catches a transposed bin index
    expect(flat[kMelBins - 1], 31.0); // frame 0, bin 31
    expect(flat[kMelBins], 100.0); // frame 1, bin 0
    expect(flat[kMelBins + 5], 105.0); // frame 1, bin 5
    expect(flat[flat.length - 1],
        (kWindowFrames - 1) * 100.0 + (kMelBins - 1));
  });

  test(
      'stackLast16: distinct per-cell values pin left-pad offset and within-row bin order',
      () {
    // emb[i][d] = i * 1000.0 + d -- every (embedding, dim) cell is unique.
    final embs = [
      for (var i = 0; i < 3; i++)
        Float32List.fromList(
            [for (var d = 0; d < kEmbeddingDim; d++) i * 1000.0 + d])
    ];
    final stacked = stackLast16(embs);

    expect(stacked.length, kClassifierSteps * kEmbeddingDim);

    // offset = kClassifierSteps - embs.length = 16 - 3 = 13 -> rows 0..12 zero.
    for (var row = 0; row < 13; row++) {
      expect(stacked[row * kEmbeddingDim], 0.0, reason: 'row $row should be zero-padding');
    }

    // Row 13 is embedding 0: element 0 is bin 0, element 1 is bin 1.
    expect(stacked[13 * kEmbeddingDim], 0.0); // embedding 0, bin 0
    expect(stacked[13 * kEmbeddingDim + 1], 1.0); // embedding 0, bin 1

    // Row 14 is embedding 1, row 15 is embedding 2.
    expect(stacked[14 * kEmbeddingDim], 1000.0);
    expect(stacked[15 * kEmbeddingDim], 2000.0);
  });
}
