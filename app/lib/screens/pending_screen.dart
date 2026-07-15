import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/draft.dart';
import '../services/drafts_store.dart';
import '../services/profile_service.dart';
import '../services/report_service.dart';

const kLaneOptions = {
  'left_slow': 'Kiri (perlahan)',
  'middle': 'Tengah',
  'right_fast': 'Kanan (laju)',
  'single_lane': 'Jalan satu lorong',
};
const kImpactOptions = {
  'bump': 'Sekadar hentakan',
  'swerve': 'Terpaksa mengelak',
  'damage': 'Terkena kuat — rosak',
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Laporan dihantar — pin ditambah!')));
      }
    } on DuplicateReportException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Sudah ada dalam sistem: laporan aktif wujud dalam lingkungan 10 m. Anda boleh membuang draf ini.')));
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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

  Widget _metaRow(Draft d) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
        fontSize: 13, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule_rounded, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(DateFormat('d MMM y, h:mm a', 'ms').format(d.capturedAt.toLocal()),
              style: style),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.place_outlined, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('${d.lat.toStringAsFixed(5)}, ${d.lng.toStringAsFixed(5)}',
              style: style),
        ]),
        if (d.speedKmh != null)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.speed_rounded, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('${d.speedKmh!.round()} km/h', style: style),
          ]),
      ],
    );
  }

  Widget _photoStrip(Draft d) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var p = 0; p < d.mediaPaths.length; p++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: p == (d.immediateIndex ?? -1)
                          ? Border.all(color: scheme.secondary, width: 2.5)
                          : Border.all(color: scheme.outlineVariant),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                          _reports.publicUrl(d.mediaPaths[p]),
                          width: 104,
                          height: 84,
                          fit: BoxFit.cover),
                    ),
                  ),
                  if (p == (d.immediateIndex ?? -1))
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('SERTA-MERTA',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: scheme.onSecondary)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_drafts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: scheme.secondaryContainer,
                child: Icon(Icons.mic_none_rounded,
                    size: 32, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 16),
              Text('Tiada laporan menunggu',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Mula memandu dan sebut "Tampal Pintar" untuk merakam laporan secara bebas tangan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drafts.length,
        itemBuilder: (context, i) {
          final d = _drafts[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.mediaPaths.isNotEmpty)
                    _photoStrip(d)
                  else
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Draf lokasi sahaja (tiada foto dashcam)',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
                  const SizedBox(height: 10),
                  _metaRow(d),
                  const Divider(height: 24),
                  _toggleRow(d, 'Jenis Kenderaan', kVehicleOptions, d.vehicleType,
                      (v) => d.vehicleType = v),
                  _toggleRow(d, 'Kedudukan Lorong', kLaneOptions, d.lanePosition,
                      (v) => d.lanePosition = v),
                  _toggleRow(d, 'Tahap Impak', kImpactOptions,
                      d.impactSeverity, (v) => d.impactSeverity = v),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: scheme.error),
                          onPressed: () => _discard(d),
                          child: const Text('Buang')),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                          onPressed: () => _submit(d),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Hantar')),
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
