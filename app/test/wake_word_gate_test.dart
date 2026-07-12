import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/driving/wake_word/wake_word_gate.dart';

void main() {
  test('fires at or above threshold, not below', () {
    var t = DateTime(2026, 1, 1);
    final gate = WakeWordGate(now: () => t);
    expect(gate.shouldFire(0.2799), isFalse);
    expect(gate.shouldFire(0.28), isTrue);
  });

  test('debounces repeat fires within 3s', () {
    var t = DateTime(2026, 1, 1);
    final gate = WakeWordGate(now: () => t);
    expect(gate.shouldFire(0.9), isTrue);
    t = t.add(const Duration(seconds: 2, milliseconds: 999));
    expect(gate.shouldFire(0.9), isFalse);
    t = t.add(const Duration(milliseconds: 2));
    expect(gate.shouldFire(0.9), isTrue);
  });

  test('below-threshold scores never consume the debounce window', () {
    var t = DateTime(2026, 1, 1);
    final gate = WakeWordGate(now: () => t);
    expect(gate.shouldFire(0.1), isFalse);
    expect(gate.shouldFire(0.5), isTrue); // still fires immediately after
  });
}
