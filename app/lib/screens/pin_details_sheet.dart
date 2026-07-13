import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import '../theme.dart';
import '../widgets/open_for_ticker.dart';

Future<void> showPinDetails(BuildContext context, String reportId) {
  final service = ReportService(Supabase.instance.client);
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => FutureBuilder<ReportDetails>(
      future: service.fetchDetails(reportId),
      builder: (context, snap) {
        if (snap.hasError) {
          return const SizedBox(
              height: 240,
              child: Center(child: Text('Butiran laporan tidak dapat dimuatkan.')));
        }
        if (!snap.hasData) {
          return const SizedBox(
              height: 240, child: Center(child: CircularProgressIndicator()));
        }
        final d = snap.data!;
        final scheme = Theme.of(context).colorScheme;
        final risk = riskStyle(context, d.riskScore);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.immediatePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    service.publicUrl(d.immediatePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      height: 180,
                      color: scheme.surfaceContainer,
                      child: Icon(Icons.broken_image_outlined,
                          color: scheme.onSurfaceVariant, size: 40),
                    ),
                  ),
                )
              else
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Tiada foto — laporan lokasi sahaja',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
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
                  d.assigned
                      ? StatusPill(
                          label: 'Telah Ditugaskan',
                          bg: scheme.secondaryContainer,
                          fg: scheme.onSecondaryContainer,
                          icon: Icons.assignment_turned_in_outlined)
                      : StatusPill(
                          label: 'Belum Ditugaskan',
                          bg: scheme.surfaceContainerHighest,
                          fg: scheme.onSurfaceVariant,
                          icon: Icons.assignment_outlined),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.account_balance_outlined,
                text:
                    '${kRoadTypeLabels[d.roadType] ?? 'Jenis jalan belum dikenal pasti'} · ${d.authorityName ?? 'Pihak berkuasa belum dikenal pasti'}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.place_outlined,
                text:
                    '${d.lat.toStringAsFixed(5)}, ${d.lng.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.schedule_rounded,
                text:
                    'Dilaporkan pada ${DateFormat('d MMM y, h:mm a', 'ms').format(d.reportedAt.toLocal())}',
              ),
              const SizedBox(height: 12),
              OpenForTicker(reportedAt: d.reportedAt),
            ],
          ),
        );
      },
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500))),
      ],
    );
  }
}
