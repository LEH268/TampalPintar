import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../map/js_map_web.dart';
import '../models/pothole.dart';
import 'pothole_detail_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Pothole> _potholes = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadPotholes();
    // RLS already scopes this official to only their assigned_role's rows
    // (see migration 0009) -- no extra client-side role filtering needed.
    _channel = _supabase
        .channel('potholes-changes-gov')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'potholes',
          callback: (_) => _loadPotholes(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _supabase.removeChannel(channel);
    super.dispose();
  }

  Future<void> _loadPotholes() async {
    final rows = await _supabase.from('potholes').select();
    if (!mounted) return;
    setState(() => _potholes = rows.map(Pothole.fromJson).toList());
  }

  List<Pothole> get _activePins => _potholes.where((p) => p.status != 'fixed').toList();

  Pothole? _findPothole(String id) {
    for (final p in _potholes) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _onPinTap(String id) {
    final pothole = _findPothole(id);
    if (pothole == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PotholeDetailPanel(pothole: pothole, onChanged: _loadPotholes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TampalPintar — Government Dashboard'),
        actions: [
          IconButton(onPressed: () => _supabase.auth.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: JsMapWeb(pins: _activePins, onPinTap: _onPinTap),
    );
  }
}
