import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gov_service.dart';
import '../theme.dart';
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

  Widget _infoRow(IconData icon, String text, {bool emphasize = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        emphasize ? FontWeight.w700 : FontWeight.w500,
                    color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = _r;
    if (r == null) return const Center(child: CircularProgressIndicator());
    if (r['status'] == 'fixed') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.check_circle_rounded,
                    size: 34, color: kSuccessGreen),
              ),
              const SizedBox(height: 16),
              Text('Fixed', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Pin removed from all maps.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    final media = [...(r['media_paths'] as List? ?? []).cast<String>()];
    final immediateIdx = (r['immediate_index'] as int?) ?? 0;
    final assigned = r['assigned'] == true;
    final factors = (r['factor_breakdown'] as List?) ?? [];
    final risk = riskStyle(r['risk_score'] as int?);
    final answers = {
      'Vehicle Type': r['vehicle_type'],
      'Lane Position': r['lane_position'],
      'Impact Severity': r['impact_severity'],
    };
    final reportedAt = DateTime.parse(r['reported_at']).toLocal();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (media.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
          Row(children: [
            Icon(Icons.location_on_outlined,
                size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Location-only report (no dashcam / photo).',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
                label: risk.label,
                bg: risk.bg,
                fg: risk.fg,
                icon: Icons.warning_amber_rounded),
            _OpenFor(reportedAt: reportedAt),
          ],
        ),
        const SectionHeader('Location'),
        _infoRow(
            Icons.account_balance_outlined,
            '${kRoadTypeLabels[r['road_type']] ?? 'Road type pending'} · ${r['authority_name'] ?? 'authority pending'}',
            emphasize: true),
        _infoRow(Icons.place_outlined, '${r['lat']}, ${r['lng']}'),
        _infoRow(Icons.schedule_rounded,
            'Reported ${DateFormat('d MMM y, h:mm a').format(reportedAt)}'),
        if (r['speed_kmh'] != null)
          _infoRow(Icons.speed_rounded, '${r['speed_kmh']} km/h'),
        if (r['rationale'] != null || factors.isNotEmpty) ...[
          const SectionHeader('AI analysis'),
          if (r['rationale'] != null)
            Text(r['rationale'],
                style: TextStyle(
                    fontSize: 13.5, height: 1.5, color: scheme.onSurface)),
          if (factors.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final f in factors)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: scheme.tertiary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${f['name']}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '${f['level']}'),
                          if (f['note'] != null)
                            TextSpan(
                                text: ' — ${f['note']}',
                                style: TextStyle(
                                    color: scheme.onSurfaceVariant)),
                        ]),
                        style: TextStyle(
                            fontSize: 13.5, color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
        const SectionHeader('Driver answers'),
        for (final e in answers.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                width: 130,
                child: Text(e.key,
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant)),
              ),
              Expanded(
                child: Text(
                  e.value == null
                      ? 'skipped'
                      : (kAnswerLabels[e.value] ?? '${e.value}'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        e.value == null ? FontStyle.italic : FontStyle.normal,
                    color: e.value == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
            ]),
          ),
        const Divider(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: assigned ? null : _assign,
            icon: Icon(
                assigned
                    ? Icons.assignment_turned_in_outlined
                    : Icons.assignment_outlined,
                size: 19),
            label: Text(assigned ? 'Assigned' : 'Assign to authority'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kSuccessGreen),
            onPressed: assigned ? _complete : null, // disabled until assigned
            icon: const Icon(Icons.check_circle_outline_rounded, size: 19),
            label: const Text('Complete — mark as fixed'),
          ),
        ),
        const SizedBox(height: 12),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(widget.urls[_i],
            height: 140, width: double.infinity, fit: BoxFit.cover,
            gaplessPlayback: true),
      ),
      Positioned(
        right: 8,
        bottom: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'frame ${_i + 1}/${widget.urls.length}',
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.surfaceContainerLowest),
          ),
        ),
      ),
    ]);
  }
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StatusPill(
      label:
          'Open for ${formatOpenFor(DateTime.now().difference(widget.reportedAt))}',
      bg: scheme.surfaceContainerHighest,
      fg: scheme.onSurfaceVariant,
      icon: Icons.timer_outlined,
    );
  }
}
