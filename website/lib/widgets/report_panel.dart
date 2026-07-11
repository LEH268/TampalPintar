import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gov_service.dart';
import '../utils/elapsed.dart';

const kRoadTypeLabels = {
  'highway_expressway': 'Highway/Expressway',
  'federal_route': 'Federal Route',
  'state_route': 'State Route',
  'municipal_local': 'Municipal/Local Road',
};
const kAnswerLabels = {
  'motorcycle': 'Motorcycle', 'car': 'Car', 'heavy_commercial': 'Heavy Commercial',
  'left_slow': 'Left (slow)', 'middle': 'Middle', 'right_fast': 'Right (fast)',
  'single_lane': 'Single-lane road',
  'bump': 'Just a bump', 'swerve': 'Forced to swerve', 'damage': 'Hit hard — damaged',
};

class ReportPanel extends StatefulWidget {
  const ReportPanel(
      {super.key,
      required this.reportId,
      required this.service,
      required this.onChanged});
  final String reportId;
  final GovService service;
  final VoidCallback onChanged;
  @override
  State<ReportPanel> createState() => _ReportPanelState();
}

class _ReportPanelState extends State<ReportPanel> {
  Map<String, dynamic>? _r;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await widget.service.fetchDetails(widget.reportId);
    if (mounted) setState(() => _r = r);
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action)),
          ],
        ),
      ) ==
      true;

  Future<void> _assign() async {
    final name = _r!['authority_name'] ?? 'the responsible authority';
    if (!await _confirm('Confirm assignment',
        'Assign this pothole to $name for repair? This cannot be undone.',
        'Assign')) {
      return;
    }
    try {
      await widget.service.assign(widget.reportId);
      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not assign: $e')));
      }
    }
  }

  Future<void> _complete() async {
    if (!await _confirm(
        'Confirm completion',
        'Mark this pothole as fixed? Its pin disappears from every map and the '
            'reporter is awarded points equal to the Risk Score.',
        'Complete')) {
      return;
    }
    try {
      await widget.service.markFixed(widget.reportId);
      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not complete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    if (r == null) return const Center(child: CircularProgressIndicator());
    if (r['status'] == 'fixed') {
      return const Center(child: Text('Fixed — pin removed from all maps.'));
    }
    final media = [...(r['media_paths'] as List? ?? []).cast<String>()];
    final immediateIdx = (r['immediate_index'] as int?) ?? 0;
    final assigned = r['assigned'] == true;
    final factors = (r['factor_breakdown'] as List?) ?? [];
    final answers = {
      'Vehicle Type': r['vehicle_type'],
      'Lane Position': r['lane_position'],
      'Impact Severity': r['impact_severity'],
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (media.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
                widget.service
                    .publicUrl(media[immediateIdx.clamp(0, media.length - 1)]),
                height: 220,
                fit: BoxFit.cover),
          ),
          if (media.length > 1) ...[
            const SizedBox(height: 8),
            FrameSlideshow(
                urls: [for (final p in media) widget.service.publicUrl(p)]),
          ],
        ] else
          const Text('Location-only report (no dashcam / photo).'),
        const SizedBox(height: 12),
        Row(children: [
          Chip(
              label: Text(r['risk_score'] == null
                  ? 'Analysis pending'
                  : 'Risk ${r['risk_score']}')),
          const SizedBox(width: 8),
          _OpenFor(reportedAt: DateTime.parse(r['reported_at']).toLocal()),
        ]),
        const SizedBox(height: 8),
        Text(
            '${kRoadTypeLabels[r['road_type']] ?? 'Road type pending'} · ${r['authority_name'] ?? 'authority pending'}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('${r['lat']}, ${r['lng']} · reported ${r['reported_at']}'),
        if (r['speed_kmh'] != null) Text('Speed: ${r['speed_kmh']} km/h'),
        const Divider(height: 24),
        if (r['rationale'] != null) ...[
          Text('Rationale', style: Theme.of(context).textTheme.titleSmall),
          Text(r['rationale']),
          const SizedBox(height: 8),
        ],
        if (factors.isNotEmpty) ...[
          Text('Factor breakdown',
              style: Theme.of(context).textTheme.titleSmall),
          for (final f in factors)
            Text(
                '• ${f['name']}: ${f['level']}${f['note'] != null ? ' — ${f['note']}' : ''}'),
          const SizedBox(height: 8),
        ],
        Text('Driver answers', style: Theme.of(context).textTheme.titleSmall),
        for (final e in answers.entries)
          Text('• ${e.key}: ${e.value == null ? 'skipped' : kAnswerLabels[e.value] ?? e.value}'),
        const Divider(height: 24),
        FilledButton(
          onPressed: assigned ? null : _assign,
          child: Text(assigned ? 'Assigned' : 'Not Assigned — tap to assign'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: assigned ? Colors.green : Colors.grey,
          ),
          onPressed: assigned ? _complete : null, // grey until assigned
          child: const Text('Complete'),
        ),
      ],
    );
  }
}

/// Auto-advancing slideshow: the burst reads like dashcam footage.
class FrameSlideshow extends StatefulWidget {
  const FrameSlideshow({super.key, required this.urls});
  final List<String> urls;
  @override
  State<FrameSlideshow> createState() => _FrameSlideshowState();
}

class _FrameSlideshowState extends State<FrameSlideshow> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800),
        (_) => setState(() => _i = (_i + 1) % widget.urls.length));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(widget.urls[_i],
              height: 140, width: double.infinity, fit: BoxFit.cover,
              gaplessPlayback: true),
        ),
        Text('frame ${_i + 1}/${widget.urls.length}'),
      ]);
}

class _OpenFor extends StatefulWidget {
  const _OpenFor({required this.reportedAt});
  final DateTime reportedAt;
  @override
  State<_OpenFor> createState() => _OpenForState();
}

class _OpenForState extends State<_OpenFor> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Chip(
      label: Text(
          'Open for ${formatOpenFor(DateTime.now().difference(widget.reportedAt))}'));
}
