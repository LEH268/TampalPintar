import 'dart:typed_data';

// Pipeline contract pinned from Voice Assistants.md §2.3 + spec §3.2.
const kChunkSamples = 1280; // 80 ms @ 16 kHz
const kMelContextSamples = 480; // mel window lookback carried between chunks
const kMelInputSamples = kMelContextSamples + kChunkSamples; // 1760
const kNewFramesPerChunk = 8; // 1280 samples / 160-sample hop
const kMelBins = 32;
const kWindowFrames = 76; // embedding model input frames
const kEmbeddingDim = 96;
const kClassifierSteps = 16;

Float32List toFloat32(Int16List pcm) {
  final out = Float32List(pcm.length);
  for (var i = 0; i < pcm.length; i++) {
    out[i] = pcm[i] / 32768.0;
  }
  return out;
}

Float32List buildMelInput(Float32List context480, Float32List chunk1280) {
  assert(context480.length == kMelContextSamples);
  assert(chunk1280.length == kChunkSamples);
  final out = Float32List(kMelInputSamples);
  out.setAll(0, context480);
  out.setAll(kMelContextSamples, chunk1280);
  return out;
}

/// rawMel: flattened (frames, 32) mel-model output. Applies openWakeWord's
/// x/10 + 2 normalization and returns the newest [take] frames as rows.
List<List<double>> normalizeAndTakeLast(List<double> rawMel,
    {int take = kNewFramesPerChunk}) {
  final frames = rawMel.length ~/ kMelBins;
  final start = frames - take;
  assert(start >= 0, 'mel output produced fewer than $take frames');
  return [
    for (var f = start; f < frames; f++)
      [
        for (var b = 0; b < kMelBins; b++) rawMel[f * kMelBins + b] / 10.0 + 2.0
      ]
  ];
}

Float32List flattenWindow(List<List<double>> frames76) {
  assert(frames76.length == kWindowFrames);
  final out = Float32List(kWindowFrames * kMelBins);
  for (var f = 0; f < kWindowFrames; f++) {
    for (var b = 0; b < kMelBins; b++) {
      out[f * kMelBins + b] = frames76[f][b];
    }
  }
  return out;
}

Float32List stackLast16(List<Float32List> embeddings) {
  final out = Float32List(kClassifierSteps * kEmbeddingDim); // zero-filled
  final take = embeddings.length > kClassifierSteps
      ? embeddings.sublist(embeddings.length - kClassifierSteps)
      : embeddings;
  final offset = kClassifierSteps - take.length; // left pad
  for (var i = 0; i < take.length; i++) {
    out.setAll((offset + i) * kEmbeddingDim, take[i]);
  }
  return out;
}
