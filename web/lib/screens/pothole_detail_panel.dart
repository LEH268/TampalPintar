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

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isTitle = false, bool isSmall = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isSmall ? 16 : 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 13 : (isTitle ? 16 : 14),
              fontWeight: isTitle ? FontWeight.w600 : FontWeight.normal,
              color: isSmall ? Colors.grey[600] : Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pothole;
    final isAssigned = p.status == 'assigned';
    final riskColor = p.riskScore >= 70 ? Colors.red : (p.riskScore >= 40 ? Colors.orange : Colors.green);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(p.photoUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildStatusChip('Risk ${p.riskScore}%', riskColor, Icons.warning_amber_rounded),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    isAssigned ? 'Assigned' : 'Not Assigned',
                    isAssigned ? Colors.blue : Colors.grey.shade600,
                    isAssigned ? Icons.assignment_turned_in : Icons.assignment_late,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // detailed info rows
              _buildInfoRow(Icons.access_time_rounded, 'Open for ${formatOpenFor(p.reportedAt)}', isTitle: true),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.description_outlined, p.riskRationale),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.account_tree_outlined,
                '${roadTypeLabels[p.roadType] ?? p.roadType} • ${roleLabels[p.assignedRole] ?? p.assignedRole}',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on_outlined,
                '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
                isSmall: true,
              ),
              const SizedBox(height: 24),
              
              const Divider(height: 1),
              const SizedBox(height: 16),

              // bottom action buttons: Assign / Complete
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _busy || isAssigned ? null : _assign,
                  icon: const Icon(Icons.assignment_ind),
                  label: Text(
                    isAssigned ? 'Already Assigned' : 'Dispatch Assignment',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: isAssigned ? Colors.green : Colors.grey[300],
                    foregroundColor: isAssigned ? Colors.white : Colors.grey[500],
                  ),
                  onPressed: _busy || !isAssigned ? null : _complete,
                  icon: const Icon(Icons.done_all),
                  label: const Text(
                    'Complete Repair',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}