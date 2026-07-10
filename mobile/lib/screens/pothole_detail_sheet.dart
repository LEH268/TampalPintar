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
    final statusSteps = [
      {'label': 'Reported', 'done': true, 'timestamp': p.reportedAt},
      {'label': 'Assigned', 'done': p.assignedAt != null, 'timestamp': p.assignedAt},
      {'label': 'Fixed', 'done': p.fixedAt != null, 'timestamp': p.fixedAt},
    ];
    final riskColor = p.riskScore >= 80
        ? Colors.red.shade700
        : p.riskScore >= 40
            ? Colors.amber.shade700
            : Colors.grey.shade700;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pothole report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800)),
                          const SizedBox(height: 4),
                          Text('Open for ${formatOpenFor(p.reportedAt)}', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${p.riskScore}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: riskColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                ...statusSteps.map((step) {
                  final isDone = step['done'] as bool;
                  final label = step['label'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade600 : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                              color: isDone ? Colors.black87 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (step['timestamp'] != null)
                          Text(
                            (step['timestamp'] as DateTime).toLocal().toString().split(' ')[0],
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text('Risk rationale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(p.riskRationale, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 12),
                Text('${roadTypeLabels[p.roadType] ?? p.roadType} • ${roleLabels[p.assignedRole] ?? p.assignedRole}'),
                const SizedBox(height: 4),
                Text(
                  '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
