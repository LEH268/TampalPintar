import 'dart:async';

import 'package:flutter/material.dart';

import '../models/pothole.dart';

/// Read-only pin detail sheet for the citizen app.
class PotholeDetailSheet extends StatefulWidget {
  const PotholeDetailSheet({
    super.key,
    required this.pothole,
  });

  final Pothole pothole;

  @override
  State<PotholeDetailSheet> createState() => _PotholeDetailSheetState();
}

class _PotholeDetailSheetState extends State<PotholeDetailSheet> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Color _riskColor(int score) {
    if (score >= 70) return Colors.red;
    if (score >= 40) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pothole;
    final riskColor = _riskColor(p.riskScore);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [

                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    p.photoUrl,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    loadingBuilder:
                        (context, child, progress) {
                      if (progress == null) return child;

                      return Container(
                        height: 190,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },

                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        height: 190,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [

                    Chip(
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: riskColor,
                      ),
                      label: Text(
                        'Risk ${p.riskScore}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: riskColor,
                        ),
                      ),
                    ),

                    Chip(
                      avatar: Icon(
                        p.status == 'assigned'
                            ? Icons.check_circle_outline
                            : Icons.hourglass_empty,
                        size: 18,
                      ),
                      label: Text(
                        p.status == 'assigned'
                            ? 'Assigned'
                            : 'Not Assigned',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),

                    Text(
                      'Open for ${formatOpenFor(p.reportedAt)}',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  p.riskRationale,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const Divider(height: 28),

                Row(
                  children: [
                    const Icon(
                      Icons.route,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        roadTypeLabels[p.roadType] ??
                            p.roadType,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        roleLabels[p.assignedRole] ??
                            p.assignedRole,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),

                    Text(
                      '${p.lat.toStringAsFixed(5)}, '
                      '${p.lng.toStringAsFixed(5)}',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}