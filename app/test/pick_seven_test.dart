import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/services/pick_seven.dart';

void main() {
  // photos exactly 1s apart around wake at t=10_000
  final epochs = [for (var i = 0; i < 20; i++) 3000 + i * 1000];

  test('full 7-photo window: 3 before + immediate + 3 after', () {
    final pick = pickSeven(epochs, 10000)!;
    expect(pick.epochsMs, [7000, 8000, 9000, 10000, 11000, 12000, 13000]);
    expect(pick.immediateIndex, 3);
    expect(pick.epochsMs[pick.immediateIndex], 10000);
  });

  test('slack pulls a photo 200ms after wake in as immediate', () {
    final pick = pickSeven([9000, 10200, 11000], 10000)!;
    expect(pick.epochsMs[pick.immediateIndex], 10200);
  });

  test('photo 400ms after wake is NOT immediate (outside 300ms slack)', () {
    final pick = pickSeven([9000, 10400, 11000], 10000)!;
    expect(pick.epochsMs[pick.immediateIndex], 9000);
  });

  test('drive just started: fewer before-photos, index shifts', () {
    final pick = pickSeven([9500, 10500, 11500, 12500], 10000)!;
    expect(pick.epochsMs, [9500, 10500, 11500, 12500]);
    expect(pick.immediateIndex, 0);
  });

  test('no after-photos yet: keeps what exists', () {
    final pick = pickSeven([7000, 8000, 9000, 10000], 10000)!;
    expect(pick.epochsMs, [7000, 8000, 9000, 10000]);
    expect(pick.immediateIndex, 3);
  });

  test('nothing at or before wake -> null (location-only draft)', () {
    expect(pickSeven([11000, 12000], 10000), isNull);
    expect(pickSeven([], 10000), isNull);
  });
}
