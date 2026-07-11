import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report.dart';
import '../services/report_service.dart';
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
              child: Center(child: Text('Could not load report details.')));
        }
        if (!snap.hasData) {
          return const SizedBox(
              height: 240, child: Center(child: CircularProgressIndicator()));
        }
        final d = snap.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.immediatePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(service.publicUrl(d.immediatePath!),
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                )
              else
                const Text('No photo — location-only report'),
              const SizedBox(height: 12),
              Row(children: [
                Chip(
                  label: Text(d.riskScore == null
                      ? 'Analysis pending'
                      : 'Risk ${d.riskScore}'),
                  backgroundColor: d.riskScore == null
                      ? Colors.grey.shade300
                      : d.riskScore! >= 80
                          ? Colors.red.shade100
                          : d.riskScore! >= 50
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                ),
                const SizedBox(width: 8),
                Chip(label: Text(d.assigned ? 'Assigned' : 'Not Assigned')),
              ]),
              const SizedBox(height: 8),
              Text(
                  '${kRoadTypeLabels[d.roadType] ?? 'Road type pending'} · ${d.authorityName ?? 'Authority pending'}'),
              Text(
                  '${d.lat.toStringAsFixed(5)}, ${d.lng.toStringAsFixed(5)} · reported ${d.reportedAt}'),
              const SizedBox(height: 8),
              OpenForTicker(reportedAt: d.reportedAt),
            ],
          ),
        );
      },
    ),
  );
}
