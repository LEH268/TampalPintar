import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pothole.dart';

/// Read-only pin detail sheet for the citizen app (photo, coords, live
/// "Open for" timer, Risk Score, road type, authority). The government
/// website has its own version of this sheet with Assign/Complete actions.
class PotholeDetailSheet extends StatefulWidget {
  const PotholeDetailSheet({super.key, required this.pothole});

  final Pothole pothole;

  @override
  State<PotholeDetailSheet> createState() => _PotholeDetailSheetState();
}

class _PotholeDetailSheetState extends State<PotholeDetailSheet> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pothole;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.photoUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text('Risk ${p.riskScore}%')),
                const SizedBox(width: 8),
                Chip(label: Text(p.status == 'assigned' ? 'Assigned' : 'Not Assigned')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Open for ${formatOpenFor(p.reportedAt)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.riskRationale),
            const SizedBox(height: 8),
            Text('${roadTypeLabels[p.roadType] ?? p.roadType} • ${roleLabels[p.assignedRole] ?? p.assignedRole}'),
            const SizedBox(height: 4),
            Text(
              '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
