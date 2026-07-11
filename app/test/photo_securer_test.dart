import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/services/photo_securer.dart';

void main() {
  List<LivePhoto> photosAt(List<int> epochs) =>
      [for (final e in epochs) LivePhoto('live/CAM/$e.jpg', e)];

  test('waits for 3 after-photos, copies 7 with f0..f6 names', () async {
    const wake = 10000;
    var poll = 0;
    final copies = <String, String>{};
    final securer = PhotoSecurer(
      list: () async {
        poll++;
        if (poll == 1) return photosAt([7000, 8000, 9000, 10000, 11000]);
        if (poll == 2) return photosAt([7000, 8000, 9000, 10000, 11000, 12000]);
        return photosAt([7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000]);
      },
      copy: (src, dst) async => copies[dst] = src,
      wait: (_) async {},
    );
    final result =
        await securer.secure(wakeMs: wake, uid: 'U1', draftId: 'D1');
    expect(result, isNotNull);
    expect(result!.paths, [
      for (var i = 0; i < 7; i++) 'reports/U1/D1/f$i.jpg',
    ]);
    expect(result.immediateIndex, 3);
    expect(copies['reports/U1/D1/f0.jpg'], 'live/CAM/7000.jpg');
    expect(copies['reports/U1/D1/f3.jpg'], 'live/CAM/10000.jpg');
    expect(copies['reports/U1/D1/f6.jpg'], 'live/CAM/13000.jpg');
  });

  test('timeout: secures what exists (immediate + befores only)', () async {
    const wake = 10000;
    final securer = PhotoSecurer(
      list: () async => photosAt([8000, 9000, 10000]), // never any after
      copy: (src, dst) async {},
      wait: (_) async {},
      pollInterval: const Duration(milliseconds: 1500),
      timeout: const Duration(seconds: 15),
    );
    final result =
        await securer.secure(wakeMs: wake, uid: 'U1', draftId: 'D2');
    expect(result, isNotNull);
    expect(result!.paths, hasLength(3));
    expect(result.immediateIndex, 2);
  });

  test('no usable photos -> null (location-only draft)', () async {
    final securer = PhotoSecurer(
      list: () async => photosAt([12000, 13000]), // all after wake+slack
      copy: (src, dst) async => fail('must not copy'),
      wait: (_) async {},
    );
    expect(await securer.secure(wakeMs: 10000, uid: 'U', draftId: 'D'),
        isNull);
  });

  test('polling respects the timeout budget', () async {
    var waited = Duration.zero;
    var polls = 0;
    final securer = PhotoSecurer(
      list: () async {
        polls++;
        return photosAt([10000]);
      },
      copy: (src, dst) async {},
      wait: (d) async => waited += d,
      pollInterval: const Duration(milliseconds: 1500),
      timeout: const Duration(seconds: 15),
    );
    await securer.secure(wakeMs: 10000, uid: 'U', draftId: 'D');
    expect(waited, const Duration(seconds: 15));
    expect(polls, 11); // initial + 10 re-polls
  });
}
