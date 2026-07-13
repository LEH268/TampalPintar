import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/elapsed.dart';

const kRoleLabels = {
  'jkr_malaysia': 'JKR Malaysia',
  'jkr_selangor': 'JKR Selangor',
  'local_council': 'Majlis Tempatan (PBT)',
  'highway': 'Konsesi Lebuh Raya',
};

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: const TabBar(tabs: [
                Tab(text: 'Pelapor Terbaik'),
                Tab(text: 'Respons Jabatan'),
              ]),
            ),
            Expanded(
              child: TabBarView(children: [
                _RpcList(
                  rpc: 'top_reporters',
                  builder: (context, rows) => [
                    for (var i = 0; i < rows.length; i++)
                      ListTile(
                        leading: _RankBadge(rank: i + 1),
                        title: Text(rows[i]['display_name'] ?? ''),
                        trailing: Text(
                          '${rows[i]['lifetime_points']} mata',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                  ],
                ),
                _RpcList(
                  rpc: 'department_response',
                  builder: (context, rows) => [
                    for (var i = 0; i < rows.length; i++)
                      ListTile(
                        leading: _RankBadge(rank: i + 1),
                        title: Text(kRoleLabels[rows[i]['role']] ??
                            rows[i]['role'].toString()),
                        subtitle: Text('${rows[i]['fix_count']} dibaiki'),
                        trailing: Text(
                          rows[i]['avg_open_seconds'] == null
                              ? 'tiada data lagi'
                              : 'purata ${formatOpenFor(Duration(seconds: (rows[i]['avg_open_seconds'] as num).round()))}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      );
}

/// Rank circle: gold / silver / bronze for the podium, neutral otherwise.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (rank) {
      1 => (const Color(0xFFF59E0B), Colors.white),
      2 => (const Color(0xFF94A3B8), Colors.white),
      3 => (const Color(0xFFB45309), Colors.white),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: Text('$rank',
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w800, fontSize: 14)),
    );
  }
}

class _RpcList extends StatelessWidget {
  const _RpcList({required this.rpc, required this.builder});
  final String rpc;
  final List<Widget> Function(BuildContext context, List<dynamic> rows) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client
            .rpc(rpc)
            .then((r) => r as List<dynamic>),
        builder: (context, snap) {
          final scheme = Theme.of(context).colorScheme;
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 36, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 10),
                    Text('Papan pendahulu tidak dapat dimuatkan',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('${snap.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tiles = builder(context, snap.data!);
          if (tiles.isEmpty) {
            return Center(
                child: Text('Tiada data lagi',
                    style: TextStyle(color: scheme.onSurfaceVariant)));
          }
          return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: tiles);
        },
      );
}
