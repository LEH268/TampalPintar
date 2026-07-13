import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'driving_task.dart';

class DrivingController {
  static void _init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'driving',
        channelName: 'Mod Memandu',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> requestPermissions() async {
    final mic = await AudioRecorder().hasPermission(); // triggers the dialog
    var loc = await Geolocator.checkPermission();
    if (loc == LocationPermission.denied) {
      loc = await Geolocator.requestPermission();
    }
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    return mic &&
        (loc == LocationPermission.always ||
            loc == LocationPermission.whileInUse);
  }

  static Future<void> start() async {
    _init();
    await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'TampalPintar sedang mendengar',
      notificationText: 'Sebut "Tampal Pintar" untuk merekodkan lubang jalan',
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Berhenti')
      ],
      callback: startDrivingCallback,
    );
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();

  static Future<bool> isRunning() => FlutterForegroundTask.isRunningService;
}
