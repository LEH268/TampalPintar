import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../services/gov_service.dart';
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('TampalPintar — $_roleLabel'),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Supabase.instance.client.auth.signOut()),
          ],
        ),
        body: Row(
          children: [
            Expanded(
                child: MapFrame(
              key: _mapKey,
              onPinTap: (id) => setState(() => _selectedReportId = id),
            )),
            SizedBox(
              width: 440,
              child: _selectedReportId == null
                  ? const Center(child: Text('Select a red pin to review it'))
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
