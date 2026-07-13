import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/utils/elapsed.dart';

void main() {
  test('seconds only', () => expect(formatOpenFor(const Duration(seconds: 45)), '45 saat'));
  test('minutes + padded seconds',
      () => expect(formatOpenFor(const Duration(minutes: 7, seconds: 30)), '7 min 30 saat'));
  test('hours + padded minutes',
      () => expect(formatOpenFor(const Duration(hours: 2, minutes: 5)), '2 jam 05 min'));
  test('days + hours',
      () => expect(formatOpenFor(const Duration(days: 3, hours: 4, minutes: 59)), '3 hari 4 jam'));
  test('negative clamps to zero',
      () => expect(formatOpenFor(const Duration(seconds: -10)), '0 saat'));
}
