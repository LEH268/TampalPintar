import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pothole.dart';

/// Government-side pin detail panel: same read-only info as the citizen
/// app's sheet, plus the Assign/Complete actions (stories #37, #39) behind
/// confirmation dialogs, each calling the matching atomic RPC.
class PotholeDetailPanel extends StatefulWidget {
  const PotholeDetailPanel({super.key, required this.pothole, required this.onChanged});

  final Pothole pothole;
  final VoidCallback onChanged;

  @override
  State<PotholeDetailPanel> createState() => _PotholeDetailPanelState();
}

class _PotholeDetailPanelState extends State<PotholeDetailPanel> {
  late final Timer _ticker;
  bool _busy = false;

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

  Future<void> _confirmAndRun(String title, String message, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assign() {
    final authority = roleLabels[widget.pothole.assignedRole] ?? widget.pothole.assignedRole;
    return _confirmAndRun(
      'Assign to $authority',
      'This permanently marks the report as dispatched to $authority. This cannot be undone.',
      () => Supabase.instance.client.rpc('assign_pothole', params: {'p_pothole_id': widget.pothole.id}),
    );
  }

  Future<void> _complete() => _confirmAndRun(
        'Mark repair Complete',
        'This permanently marks the pothole as fixed and removes it from every map.',
        () => Supabase.instance.client.rpc('mark_pothole_fixed', params: {'p_pothole_id': widget.pothole.id}),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.pothole;
    final isAssigned = p.status == 'assigned';
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
                Chip(label: Text(isAssigned ? 'Assigned' : 'Not Assigned')),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || isAssigned ? null : _assign,
              child: Text(isAssigned ? 'Assigned' : 'Not Assigned → Assign'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: isAssigned ? Colors.green : Colors.grey),
              onPressed: _busy || !isAssigned ? null : _complete,
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }
}
