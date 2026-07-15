import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../services/gov_service.dart';
import '../theme.dart';
import '../widgets/map_frame.dart';
import '../widgets/report_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = GovService(Supabase.instance.client);
  final _mapKey = GlobalKey<MapFrameState>();
  Timer? _timer;
  String _roleLabel = '';
  String? _selectedReportId;

  @override
  void initState() {
    super.initState();
    _service.myProfile().then((p) {
      if (mounted) {
        setState(() => _roleLabel = kRoleLabels[p['role']] ?? p['role']);
      }
    });
    _refreshPins();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshPins());
  }

  Future<void> _refreshPins() async {
    final pins = await _service.fetchMyActivePins();
    _mapKey.currentState?.setPins(pins);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: 12),
            const Text('TampalPintar'),
            if (_roleLabel.isNotEmpty) ...[
              const SizedBox(width: 12),
              StatusPill(
                label: _roleLabel,
                bg: scheme.primaryContainer,
                fg: scheme.onPrimaryContainer,
                icon: Icons.verified_user_outlined,
              ),
            ],
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Keluar'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
              child: MapFrame(
            key: _mapKey,
            onPinTap: (id) => setState(() => _selectedReportId = id),
          )),
          Container(
            width: 440,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              border: Border(left: BorderSide(color: scheme.outlineVariant)),
            ),
            child: _selectedReportId == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: scheme.surfaceContainerHigh,
                            child: Icon(Icons.location_on_outlined,
                                size: 30, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Text('Tiada laporan dipilih',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Pilih pin merah pada peta untuk menyemak, menugaskan dan menyelesaikannya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReportPanel(
                    key: ValueKey(_selectedReportId),
                    reportId: _selectedReportId!,
                    service: _service,
                    onChanged: () {
                      _refreshPins();
                      setState(() {}); // re-pull details after assign/fix
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
