import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/elapsed.dart';

const kRoleLabels = {
  'jkr_malaysia': 'JKR Malaysia',
  'jkr_selangor': 'JKR Selangor',
  'local_council': 'Local Council (PBT)',
  'highway': 'Highway Concessionaire',
};

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(text: 'Top Reporters'),
              Tab(text: 'Department Response'),
            ]),
            Expanded(
              child: TabBarView(children: [
                _RpcList(
                  rpc: 'top_reporters',
                  builder: (rows) => [
                    for (var i = 0; i < rows.length; i++)
                      ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(rows[i]['display_name'] ?? ''),
                        trailing: Text('${rows[i]['lifetime_points']} pts',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                _RpcList(
                  rpc: 'department_response',
                  builder: (rows) => [
                    for (var i = 0; i < rows.length; i++)
                      ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(kRoleLabels[rows[i]['role']] ??
                            rows[i]['role'].toString()),
                        subtitle: Text('${rows[i]['fix_count']} fixed'),
                        trailing: Text(
                          rows[i]['avg_open_seconds'] == null
                              ? 'no data yet'
                              : 'avg ${formatOpenFor(Duration(seconds: (rows[i]['avg_open_seconds'] as num).round()))}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

class _RpcList extends StatelessWidget {
  const _RpcList({required this.rpc, required this.builder});
  final String rpc;
  final List<Widget> Function(List<dynamic> rows) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client
            .rpc(rpc)
            .then((r) => r as List<dynamic>),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tiles = builder(snap.data!);
          if (tiles.isEmpty) return const Center(child: Text('No data yet'));
          return ListView(children: tiles);
        },
      );
}
