import 'package:flutter/material.dart';
// TODO: Import wakelock_plus and porcupine_flutter in pubspec.yaml for real hardware integration

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  bool _isListening = true;
  bool _dashcamConnected = false;
  int _pendingDrafts = 2; // Mock draft count

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Driving Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Dashcam Status Indicator (PRD Story #23)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _dashcamConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _dashcamConnected ? Icons.videocam : Icons.videocam_off, 
                  color: _dashcamConnected ? Colors.green.shade700 : Colors.red.shade700, 
                  size: 16
                ),
                const SizedBox(width: 6),
                Text(
                  _dashcamConnected ? 'Dashcam Connected' : 'No Dashcam',
                  style: TextStyle(
                    color: _dashcamConnected ? Colors.green.shade900 : Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Voice Listening UI (PRD Story #12 & #13)
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? scheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                border: Border.all(color: _isListening ? scheme.primary : Colors.grey, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    size: 64,
                    color: _isListening ? scheme.primary : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListening ? 'Listening for\n"Tampal Pintar"' : 'Paused',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isListening ? scheme.primary : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Pending Reports Button (PRD Story #18)
            if (_pendingDrafts > 0)
              FilledButton.tonalIcon(
                onPressed: () {
                  // TODO: Navigate to PendingReportsScreen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening pending drafts...')));
                },
                icon: const Icon(Icons.inbox),
                label: Text('Review $_pendingDrafts Pending Reports'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isListening = !_isListening),
        backgroundColor: _isListening ? Colors.redAccent : Colors.grey,
        child: Icon(_isListening ? Icons.stop : Icons.play_arrow, color: Colors.white),
      ),
    );
  }
}