import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tampal_pintar/services/position_resolver.dart';

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  test('uses the fused fix when it succeeds, without touching fallbacks',
      () async {
    var lmCalls = 0, lastKnownCalls = 0;
    final r = PositionResolver(
      getCurrent: () async => _pos(3.0, 101.4),
      getCurrentViaLocationManager: () async {
        lmCalls++;
        return _pos(9, 9);
      },
      getLastKnown: () async {
        lastKnownCalls++;
        return _pos(8, 8);
      },
    );
    final pos = await r.resolve();
    expect(pos!.latitude, 3.0);
    expect(lmCalls, 0);
    expect(lastKnownCalls, 0);
  });

  test(
      'falls back to the raw LocationManager when the fused provider throws '
      '(emulator: LocationServiceDisabledException despite location being on)',
      () async {
    final r = PositionResolver(
      getCurrent: () async => throw const LocationServiceDisabledException(),
      getCurrentViaLocationManager: () async => _pos(3.0371, 101.4408),
      getLastKnown: () async => fail('must not reach lastKnown'),
    );
    final pos = await r.resolve();
    expect(pos!.latitude, 3.0371);
    expect(pos.longitude, 101.4408);
  });

  test('falls back to the last known fix when both live requests fail',
      () async {
    final r = PositionResolver(
      getCurrent: () async => throw const LocationServiceDisabledException(),
      getCurrentViaLocationManager: () async =>
          throw const LocationServiceDisabledException(),
      getLastKnown: () async => _pos(2.9, 101.5),
    );
    final pos = await r.resolve();
    expect(pos!.latitude, 2.9);
  });

  test('returns null when every source fails or is empty', () async {
    final r = PositionResolver(
      getCurrent: () async => throw const LocationServiceDisabledException(),
      getCurrentViaLocationManager: () async =>
          throw const LocationServiceDisabledException(),
      getLastKnown: () async => null,
    );
    expect(await r.resolve(), isNull);
  });

  test('a throwing lastKnown still resolves to null instead of escaping',
      () async {
    final r = PositionResolver(
      getCurrent: () async => throw Exception('boom'),
      getCurrentViaLocationManager: () async => throw Exception('boom'),
      getLastKnown: () async => throw Exception('boom'),
    );
    expect(await r.resolve(), isNull);
  });
}
