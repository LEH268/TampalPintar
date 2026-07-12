/// Minimal inference abstraction so the pipeline is testable without ONNX.
///
/// Intentionally has no `dispose()` member: the three `FakeRunner`s in
/// `test/wake_word_pipeline_test.dart` use `implements OrtRunner`, and Dart's
/// `implements` only adopts the implicit interface (member signatures), never
/// a default method body from an abstract class -- so any `dispose()` added
/// here, with or without a body, would force those untouchable fakes to
/// declare their own `dispose()` override or fail to compile
/// (`non_abstract_class_inherits_abstract_member`). Native ORT sessions are
/// closed by [LoadedWakeWord] in `onnx_ort_runner.dart`, which holds the
/// concrete [OnnxOrtRunner]s and disposes them directly -- keeping this
/// interface, and [WakeWordPipeline] itself, free of any ONNX dependency.
abstract class OrtRunner {
  /// Runs the model on a flattened float32 [input] reshaped to [shape]
  /// and returns the flattened output tensor.
  Future<List<double>> run(List<double> input, List<int> shape);
}
