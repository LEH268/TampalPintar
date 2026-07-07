import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'voice_task_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TampalPintar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DrivingModeScreen(),
    );
  }
}

class DrivingModeScreen extends StatefulWidget {
  const DrivingModeScreen({super.key});

  @override
  State<DrivingModeScreen> createState() => _DrivingModeScreenState();
}

class _DrivingModeScreenState extends State<DrivingModeScreen> {
  int _potholeCount = 0;
  bool _isServiceRunning = false;
  bool _permissionsGranted = false;
  String _liveTranscript = '';
  String _serviceStatus = '';
  String _errorMessage = '';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initializeForegroundTask();
    _setupTaskDataCallback();
    _requestPermissions();
    _checkServiceStatus();
  }

  void _setupTaskDataCallback() {
    FlutterForegroundTask.addTaskDataCallback(_onDataReceived);
  }

  void _initializeForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tampalPintar_channel',
        channelName: 'TampalPintar Service',
        channelDescription: 'Background voice detection for pothole logging',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    final notificationStatus = await Permission.notification.request();

    setState(() {
      _permissionsGranted = micStatus.isGranted && notificationStatus.isGranted;
    });

    if (!_permissionsGranted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app requires Microphone and Notification permissions to run in the background and detect potholes while you drive.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  Future<void> _startDriveMode() async {
    if (!_permissionsGranted) {
      _showPermissionDialog();
      return;
    }

    final ServiceRequestResult result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'TampalPintar',
      notificationText: 'Listening for hazards in the background...',
      callback: startVoiceCallback,
    );

    if (result is ServiceRequestSuccess) {
      setState(() {
        _isServiceRunning = true;
      });
    }
  }

  Future<void> _stopDriveMode() async {
    final ServiceRequestResult result = await FlutterForegroundTask.stopService();

    if (result is ServiceRequestSuccess) {
      setState(() {
        _isServiceRunning = false;
      });
    }
  }

  void _onDataReceived(dynamic data) {
    if (data is Map) {
      if (data['action'] == 'pothole_detected') {
        setState(() {
          _potholeCount++;
          _errorMessage = '';
        });
        _playBeep();
      } else if (data['action'] == 'transcript_update') {
        setState(() {
          _liveTranscript = data['text'] as String? ?? '';
          _errorMessage = '';
        });
      } else if (data['action'] == 'service_status') {
        setState(() {
          _serviceStatus = data['status'] as String? ?? '';
        });
      } else if (data['action'] == 'error') {
        setState(() {
          _errorMessage = data['message'] as String? ?? 'Unknown error';
        });
      } else if (data['action'] == 'heartbeat') {
        // Service is alive - just update status silently
        if (_serviceStatus != 'alive') {
          setState(() {
            _serviceStatus = 'alive';
          });
        }
      }
    }
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      // Fallback: system beep if asset not available
      // On Android, we could use SystemSound.play(SystemSoundType.click)
      // but AudioPlayer with TTS "beep" would be better
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onDataReceived);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('TampalPintar - Driving Mode'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_permissionsGranted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Permissions required to start driving mode',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service Error',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _errorMessage,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_serviceStatus.isNotEmpty && _errorMessage.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: $_serviceStatus',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _isServiceRunning ? Colors.green : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isServiceRunning
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$_potholeCount',
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Potholes Logged',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                if (_isServiceRunning)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.hearing, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'What Vosk Hears:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _liveTranscript.isEmpty
                                  ? '(listening...)'
                                  : _liveTranscript,
                              style: TextStyle(
                                fontSize: 16,
                                color: _liveTranscript.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic, color: Colors.green, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Listening in background...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Say "Hey Potholes" to log a pothole',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                if (!_isServiceRunning)
                  ElevatedButton(
                    onPressed: _startDriveMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'START DRIVE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _stopDriveMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'STOP DRIVE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
    );
  }
}
