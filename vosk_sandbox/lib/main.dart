import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

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

class _DrivingModeScreenState extends State<DrivingModeScreen> with WidgetsBindingObserver {
  final _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  int _potholeCount = 0;
  bool _isListening = false;
  bool _permissionsGranted = false;
  bool _modelLoaded = false;
  String _liveTranscript = '';
  String _errorMessage = '';
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> _wakeWordVariants = [
    'hey potholes',
    'hey but holes',
    'a potholes',
    'hey paul holes',
    'hey pot hose',
    'hey part holes',
    'hey bought holes',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeForegroundTask();
    _requestPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep service running even when app is in background
    if (state == AppLifecycleState.paused && _isListening) {
      // App went to background - Vosk keeps running in main isolate
      print('[Main] App backgrounded, Vosk continues in foreground service');
    } else if (state == AppLifecycleState.resumed && _isListening) {
      print('[Main] App resumed, Vosk still active');
    }
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
        eventAction: ForegroundTaskEventAction.nothing(),
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
    } else {
      await _loadModel();
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

  Future<void> _loadModel() async {
    try {
      setState(() {
        _errorMessage = 'Loading Vosk model...';
      });

      final modelLoader = ModelLoader();
      const modelPath = 'assets/models/vosk-model-small-en-us-0.15.zip';

      final loadedModelPath = await modelLoader.loadFromAssets(modelPath);
      _model = await _vosk.createModel(loadedModelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      setState(() {
        _modelLoaded = true;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load model: $e';
      });
    }
  }

  Future<void> _startDriveMode() async {
    if (!_permissionsGranted || !_modelLoaded) {
      return;
    }

    try {
      // Start foreground service for persistent notification
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'TampalPintar',
        notificationText: 'Listening for potholes...',
        callback: _dummyCallback,
      );

      // Start Vosk in main isolate
      _speechService = await _vosk.initSpeechService(_recognizer!);

      _speechService!.onPartial().listen((partial) {
        try {
          final decoded = jsonDecode(partial);
          final partialText = decoded['partial'] as String? ?? '';

          if (partialText.isNotEmpty) {
            setState(() {
              _liveTranscript = partialText;
            });

            _checkForWakeWord(partialText.toLowerCase());
          }
        } catch (e) {
          print('[Main] JSON parse error: $e');
        }
      });

      await _speechService!.start();

      setState(() {
        _isListening = true;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start: $e';
      });
    }
  }

  void _checkForWakeWord(String text) {
    for (final variant in _wakeWordVariants) {
      if (text.contains(variant)) {
        _onWakeWordDetected();
        return;
      }
    }
  }

  void _onWakeWordDetected() {
    setState(() {
      _potholeCount++;
    });

    _speechService?.reset();
    _playBeep();

    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'TampalPintar',
      notificationText: 'Potholes detected: $_potholeCount',
    );
  }

  Future<void> _stopDriveMode() async {
    await _speechService?.stop();
    await FlutterForegroundTask.stopService();

    setState(() {
      _isListening = false;
      _liveTranscript = '';
    });
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('beep.mp3'));
    } catch (e) {
      // Silent fallback
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechService?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
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
                      color: _errorMessage.contains('Loading')
                          ? Colors.blue[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage.contains('Loading')
                            ? Colors.blue
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(fontSize: 14),
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
                          color: _isListening ? Colors.green : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
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
                if (_isListening)
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
                              'Listening (works in background)',
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
                if (_modelLoaded && !_isListening)
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
                else if (_isListening)
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
      ),
    );
  }
}

// Dummy callback for foreground service (no isolate work needed)
@pragma('vm:entry-point')
void _dummyCallback() {
  FlutterForegroundTask.setTaskHandler(_DummyTaskHandler());
}

class _DummyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[ForegroundTask] Started - notification active');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Just keep notification alive
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('[ForegroundTask] Destroyed');
  }
}
