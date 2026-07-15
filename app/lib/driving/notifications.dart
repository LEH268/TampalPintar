import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AppNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // flutter_local_notifications 20.x: initialize() takes a required named
    // `settings` parameter (older majors took it positionally).
    await _plugin.initialize(
      settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
  }

  /// Wake word heard but no GPS fix could be obtained from any source —
  /// surface the failure instead of silently dropping the report.
  static Future<void> recordingFailed() => _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Lubang jalan tidak dapat direkodkan',
        body: 'Tiada kedudukan GPS. Pastikan lokasi dihidupkan, kemudian cuba lagi.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pothole_events',
            'Peristiwa lubang jalan',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );

  /// "Pothole Recorded!" — doubles as the PRD's audible confirmation.
  static Future<void> potholeRecorded() => _plugin.show(
        // flutter_local_notifications 20.x: show() takes required named
        // `id`/`title`/`body`/`notificationDetails` (older majors were
        // positional).
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Lubang Jalan Direkodkan!',
        body: 'Disimpan sebagai draf — semak dalam tab Menunggu apabila kenderaan berhenti.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pothole_events',
            'Peristiwa lubang jalan',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
}
