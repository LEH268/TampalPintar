import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/draft.dart';
import '../services/drafts_store.dart';
import '../services/profile_service.dart';
import '../services/report_service.dart';

const kLaneOptions = {
  'left_slow': 'Left (slow)',
  'middle': 'Middle',
  'right_fast': 'Right (fast)',
  'single_lane': 'Single-lane road',
};
const kImpactOptions = {
  'bump': 'Just a bump',
  'swerve': 'Forced to swerve',
  'damage': 'Hit it hard — damaged',
};

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  final _reports = ReportService(Supabase.instance.client);
  DraftsStore? _store;
  List<Draft> _drafts = [];

  @override
  void initState() {
    super.initState();
    _load();
    FlutterForegroundTask.addTaskDataCallback(_onServiceData);
  }

  void _onServiceData(Object data) => _load();

  Future<void> _load() async {
    final docs = await getApplicationDocumentsDirectory();
    _store ??= DraftsStore(Directory('${docs.path}${Platform.pathSeparator}drafts'));
    final drafts = await _store!.list();
    if (mounted) setState(() => _drafts = drafts);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onServiceData);
    super.dispose();
  }

  Future<void> _submit(Draft d) async {
    try {
      await _reports.submitDraft(d);
      await _store!.delete(d.id); // photos stay: the report references them
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted — pin added!')));
      }
    } on DuplicateReportException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Already in the system: an active report exists within 10 m. You can discard this draft.')));
      }
    }
    await _load();
  }

  Future<void> _discard(Draft d) async {
    if (d.mediaPaths.isNotEmpty) {
      await Supabase.instance.client.storage.from('media').remove(d.mediaPaths);
    }
    await _store!.delete(d.id);
    await _load();
  }

  Future<void> _saveAnswer(Draft d, void Function() mutate) async {
    mutate();
    await _store!.save(d);
    if (!mounted) return;
    setState(() {});
  }

  Widget _toggleRow(Draft d, String label, Map<String, String> options,
      String? value, void Function(String?) set) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 6,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  onSelected: (_) => _saveAnswer(
                      d, () => set(value == e.key ? null : e.key)), // tap again = skip
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_drafts.isEmpty) {
      return const Center(
          child: Text('No pending reports.\nDrive and say "Tampal Pintar"!',
              textAlign: TextAlign.center));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _drafts.length,
        itemBuilder: (context, i) {
          final d = _drafts[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.mediaPaths.isNotEmpty)
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var p = 0; p < d.mediaPaths.length; p++)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  decoration: p == (d.immediateIndex ?? -1)
                                      ? BoxDecoration(
                                          border: Border.all(
                                              color: Colors.red, width: 3))
                                      : null,
                                  child: Image.network(
                                      _reports.publicUrl(d.mediaPaths[p]),
                                      width: 96,
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    const Text('Location-only draft (no dashcam photos)'),
                  const SizedBox(height: 8),
                  Text(
                      '${d.capturedAt.toLocal()} · ${d.lat.toStringAsFixed(5)}, ${d.lng.toStringAsFixed(5)}'
                      '${d.speedKmh != null ? ' · ${d.speedKmh!.round()} km/h' : ''}'),
                  const Divider(),
                  _toggleRow(d, 'Vehicle Type', kVehicleOptions, d.vehicleType,
                      (v) => d.vehicleType = v),
                  _toggleRow(d, 'Lane Position', kLaneOptions, d.lanePosition,
                      (v) => d.lanePosition = v),
                  _toggleRow(d, 'Impact Severity', kImpactOptions,
                      d.impactSeverity, (v) => d.impactSeverity = v),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => _discard(d),
                          child: const Text('Discard')),
                      const SizedBox(width: 8),
                      FilledButton(
                          onPressed: () => _submit(d),
                          child: const Text('Submit')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
