import 'dart:typed_data';
import 'feature_math.dart';
import 'ort_runner.dart';

/// Streaming three-model chain: mel -> embedding -> classifier.
/// One 1280-sample chunk in => at most one new embedding + score out.
class WakeWordPipeline {
  WakeWordPipeline(
      {required this.mel, required this.embedding, required this.classifier});

  final OrtRunner mel;
  final OrtRunner embedding;
  final OrtRunner classifier;

  final Float32List _context = Float32List(kMelContextSamples);
  final List<List<double>> _melFrames = [];
  final List<Float32List> _embeddings = [];

  Future<double?> processChunk(Int16List chunkPcm) async {
    assert(chunkPcm.length == kChunkSamples);
    final chunk = toFloat32(chunkPcm);
    final melInput = buildMelInput(_context, chunk);
    _context.setAll(0, chunk.sublist(kChunkSamples - kMelContextSamples));

    final rawMel = await mel.run(melInput, [1, kMelInputSamples]);
    _melFrames.addAll(normalizeAndTakeLast(rawMel));
    if (_melFrames.length < kWindowFrames) return null;
    while (_melFrames.length > kWindowFrames) {
      _melFrames.removeAt(0); // keep exactly the newest 76
    }

    final emb = await embedding.run(
        flattenWindow(_melFrames), [1, kWindowFrames, kMelBins, 1]);
    _embeddings.add(Float32List.fromList(emb));
    while (_embeddings.length > kClassifierSteps) {
      _embeddings.removeAt(0);
    }

    final out = await classifier.run(
        stackLast16(_embeddings), [1, kClassifierSteps, kEmbeddingDim]);
    return out.first;
  }
}
