/// Threshold 0.28 is the eval-validated operating point from
/// tampal_pintar_onnx.md (FPPH <= 0.1) -- not the default 0.5.
class WakeWordGate {
  WakeWordGate({
    this.threshold = 0.28,
    this.debounce = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final double threshold;
  final Duration debounce;
  final DateTime Function() _now;
  DateTime? _lastFire;

  bool shouldFire(double score) {
    if (score < threshold) return false;
    final t = _now();
    if (_lastFire != null && t.difference(_lastFire!) < debounce) return false;
    _lastFire = t;
    return true;
  }
}
