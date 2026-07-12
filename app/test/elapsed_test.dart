import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/utils/elapsed.dart';

void main() {
  test('seconds only', () => expect(formatOpenFor(const Duration(seconds: 45)), '45s'));
  test('minutes + padded seconds',
      () => expect(formatOpenFor(const Duration(minutes: 7, seconds: 30)), '7m 30s'));
  test('hours + padded minutes',
      () => expect(formatOpenFor(const Duration(hours: 2, minutes: 5)), '2h 05m'));
  test('days + hours',
      () => expect(formatOpenFor(const Duration(days: 3, hours: 4, minutes: 59)), '3d 4h'));
  test('negative clamps to zero',
      () => expect(formatOpenFor(const Duration(seconds: -10)), '0s'));
}
