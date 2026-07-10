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
  String? _selectedPotholeId;

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
    final potholes = rows.map(Pothole.fromJson).toList();
    setState(() {
      _potholes = potholes;
      if (_selectedPotholeId == null || !_potholes.any((p) => p.id == _selectedPotholeId)) {
        final active = _activePotholes;
        if (active.isNotEmpty) _selectedPotholeId = active.first.id;
      } else if (!_activePotholes.any((p) => p.id == _selectedPotholeId) && _activePotholes.isNotEmpty) {
        _selectedPotholeId = _activePotholes.first.id;
      }
    });
  }

  List<Pothole> get _activePotholes => _potholes.where((p) => p.status != 'fixed').toList();

  List<Pothole> get _sortedActivePotholes {
    final list = _activePotholes.toList();
    list.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return list;
  }

  int get _fixedCount => _potholes.where((p) => p.status == 'fixed').length;

  Pothole? _findPothole(String? id) {
    if (id == null) return null;
    for (final p in _potholes) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _onPinTap(String id) {
    final pothole = _findPothole(id);
    if (pothole == null) return;
    setState(() => _selectedPotholeId = pothole.id);
  }

  void _onListSelection(Pothole pothole) {
    setState(() => _selectedPotholeId = pothole.id);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'fixed':
        return 'Fixed';
      default:
        return 'Not assigned';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.amber.shade700;
      case 'fixed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _locationLabel(Pothole pothole) {
    return '${pothole.lat.toStringAsFixed(4)}, ${pothole.lng.toStringAsFixed(4)} · ${roadTypeLabels[pothole.roadType] ?? pothole.roadType}';
  }

  Widget _buildCountBadge({required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildRiskBadge(int score) {
    final color = score >= 80
        ? Colors.red.shade700
        : score >= 40
            ? Colors.amber.shade700
            : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePotholes = _sortedActivePotholes;
    final selectedPothole = _findPothole(_selectedPotholeId);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.deepOrange.shade700, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'TampalPintar',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Government Dashboard',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const Spacer(),
                _buildCountBadge(label: 'Active', count: activePotholes.length, color: Colors.deepOrange.shade700),
                const SizedBox(width: 10),
                _buildCountBadge(label: 'Fixed', count: _fixedCount, color: Colors.green.shade700),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _supabase.auth.signOut(),
                  icon: const Icon(Icons.logout_outlined),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                'Priority queue',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                              const Spacer(),
                              Text(
                                '${activePotholes.length} active',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: activePotholes.isEmpty
                              ? Center(
                                  child: Text(
                                    'No active reports',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: activePotholes.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final pothole = activePotholes[index];
                                    final isSelected = selectedPothole?.id == pothole.id;
                                    return Material(
                                      color: isSelected ? Colors.deepOrange.shade50 : Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _onListSelection(pothole),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _locationLabel(pothole),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey.shade800,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _buildRiskBadge(pothole.riskScore),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Open for ${formatOpenFor(pothole.reportedAt)}',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    _statusLabel(pothole.status),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: _statusColor(pothole.status),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                roadTypeLabels[pothole.roadType] ?? pothole.roadType,
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: JsMapWeb(pins: activePotholes, onPinTap: _onPinTap),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          constraints: const BoxConstraints(minHeight: 280, maxHeight: 360),
                          child: selectedPothole == null
                              ? Center(
                                  child: Text(
                                    'Select a pothole to inspect it.',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: PotholeDetailPanel(pothole: selectedPothole, onChanged: _loadPotholes),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
