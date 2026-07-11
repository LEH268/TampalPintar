import 'package:geolocator/geolocator.dart';
import '../config.dart';

/// Resolves a GPS fix for a report, surviving provider quirks.
///
/// The default fused-provider [Geolocator.getCurrentPosition] throws
/// [LocationServiceDisabledException] on emulators even when device location
/// is enabled (Play-services settings-check quirk), and without a time limit
/// it can stall indefinitely waiting for a fresh fix. Try it bounded, then
/// the raw LocationManager, then the last known fix — a slightly stale
/// position beats silently losing the report.
class PositionResolver {
  PositionResolver({
    this.getCurrent = _fused,
    this.getCurrentViaLocationManager = _locationManager,
    this.getLastKnown = Geolocator.getLastKnownPosition,
  });

  final Future<Position> Function() getCurrent;
  final Future<Position> Function() getCurrentViaLocationManager;
  final Future<Position?> Function() getLastKnown;

  static Future<Position> _fused() => Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(timeLimit: kGpsFixTimeout));

  static Future<Position> _locationManager() => Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
          forceLocationManager: true, timeLimit: kGpsFixTimeout));

  Future<Position?> resolve() async {
    try {
      return await getCurrent();
    } catch (_) {}
    try {
      return await getCurrentViaLocationManager();
    } catch (_) {}
    try {
      return await getLastKnown();
    } catch (_) {}
    return null;
  }
}
