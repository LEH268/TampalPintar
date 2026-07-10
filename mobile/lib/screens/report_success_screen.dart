import 'package:flutter/material.dart';

import 'map_screen.dart';

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, this.reportId});

  final String? reportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, size: 40, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Report submitted',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your pothole report is now in the system and will be visible on the map.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  if (reportId != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Report ID: $reportId',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade700),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => MapScreen(initialPotholeId: reportId)),
                          (route) => false,
                        );
                      },
                      child: const Text('View on map'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Back to home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
