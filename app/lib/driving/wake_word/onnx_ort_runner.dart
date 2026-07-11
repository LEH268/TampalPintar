import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'ort_runner.dart';
import 'wake_word_pipeline.dart';

/// [OrtRunner] backed by the real `flutter_onnxruntime` plugin.
///
/// This is the only file in the app that imports `flutter_onnxruntime` --
/// everything else depends on the [OrtRunner] seam so it can be tested
/// against fakes on the host.
class OnnxOrtRunner implements OrtRunner {
  OnnxOrtRunner._(this._session);

  final OrtSession _session;

  static Future<OnnxOrtRunner> fromAsset(String assetPath) async {
    final session = await OnnxRuntime().createSessionFromAsset(assetPath);
    return OnnxOrtRunner._(session);
  }

  @override
  Future<List<double>> run(List<double> input, List<int> shape) async {
    final value = await OrtValue.fromList(input, shape);
    final outputs = await _session.run({_session.inputNames.first: value});
    final out = outputs[_session.outputNames.first]!;
    final flat = await out.asFlattenedList();
    return [for (final v in flat) (v as num).toDouble()];
  }

  Future<void> dispose() => _session.close();
}

/// A [WakeWordPipeline] plus the concrete [OnnxOrtRunner]s that back it.
///
/// [WakeWordPipeline] itself only knows about the [OrtRunner] seam (so it
/// stays testable against fakes without any ONNX dependency), so disposal
/// of the native ORT sessions lives here instead -- this holder is the one
/// place that knows both the pipeline and the concrete runners that need
/// closing.
class LoadedWakeWord {
  LoadedWakeWord(this.pipeline, this._runners);

  final WakeWordPipeline pipeline;
  final List<OnnxOrtRunner> _runners;

  Future<void> dispose() async {
    for (final runner in _runners) {
      await runner.dispose();
    }
  }
}

/// Loads the three bundled ONNX assets and wires them into a
/// [WakeWordPipeline], returned together with the runners as a
/// [LoadedWakeWord] so the caller can dispose them later.
class WakeWordModels {
  static Future<LoadedWakeWord> load() async {
    final mel = await OnnxOrtRunner.fromAsset('assets/models/melspectrogram.onnx');
    final embedding =
        await OnnxOrtRunner.fromAsset('assets/models/embedding_model.onnx');
    final classifier =
        await OnnxOrtRunner.fromAsset('assets/models/tampal_pintar.onnx');
    final pipeline = WakeWordPipeline(
        mel: mel, embedding: embedding, classifier: classifier);
    return LoadedWakeWord(pipeline, [mel, embedding, classifier]);
  }
}
