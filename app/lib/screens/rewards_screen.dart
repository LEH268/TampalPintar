import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/rewards_service.dart';
import '../theme.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _service = RewardsService(Supabase.instance.client);
  int _balance = 0;
  List<Map<String, dynamic>> _catalog = [], _vouchers = [], _history = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.balance(),
      _service.catalog(),
      _service.myVouchers(),
      _service.history(),
    ]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as int;
      _catalog = results[1] as List<Map<String, dynamic>>;
      _vouchers = results[2] as List<Map<String, dynamic>>;
      _history = results[3] as List<Map<String, dynamic>>;
      _loaded = true;
    });
  }

  Future<void> _redeem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sahkan penebusan'),
        content: Text(
            'Belanjakan ${item['points_cost']} mata untuk ${item['name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tebus')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final code = await _service.redeem(item['id'] as String);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: Icon(Icons.celebration_rounded,
              color: Theme.of(context).colorScheme.tertiary, size: 32),
          title: const Text('Baucar berjaya ditebus!'),
          content: SelectableText('Kod anda: $code'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Selesai')),
          ],
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Penebusan gagal: $e')));
      }
    }
  }

  Widget _balanceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF075985)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.stars_rounded,
                color: Color(0xFFFCD34D), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Baki boleh dibelanjakan',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75))),
                const SizedBox(height: 2),
                Text(
                  '${NumberFormat.decimalPattern().format(_balance)} mata',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.card_giftcard_rounded,
              color: scheme.surface.withValues(alpha: 0.25), size: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _balanceCard(context),
          const SectionHeader('Katalog baucar'),
          Card(
            child: Column(children: [
              for (final item in _catalog)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.tertiaryContainer,
                    child: Icon(Icons.local_activity_outlined,
                        color: scheme.onTertiaryContainer, size: 22),
                  ),
                  title: Text(item['name']),
                  subtitle: Text('${item['brand']} · RM${item['value_rm']}'),
                  trailing: FilledButton.tonal(
                    onPressed:
                        _balance >= (item['points_cost'] as num).toInt()
                            ? () => _redeem(item)
                            : null, // affordability-disabled
                    child: Text('${item['points_cost']} mata'),
                  ),
                ),
            ]),
          ),
          const SectionHeader('Baucar saya'),
          if (_vouchers.isEmpty)
            Text('Belum ada yang ditebus.',
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            Card(
              child: Column(children: [
                for (final v in _vouchers)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.secondaryContainer,
                      child: Icon(Icons.confirmation_number_outlined,
                          color: scheme.onSecondaryContainer, size: 22),
                    ),
                    title: Text(v['name']),
                    subtitle: SelectableText(
                      v['code'],
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                    trailing: IconButton(
                      tooltip: 'Salin kod',
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: v['code'] as String));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kod disalin')));
                        }
                      },
                    ),
                  ),
              ]),
            ),
          const SectionHeader('Sejarah mata'),
          if (_history.isEmpty)
            Text('Tiada aktiviti lagi.',
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            Card(
              child: Column(children: [
                for (final h in _history)
                  ListTile(
                    dense: true,
                    title: Text(h['reason'] ?? ''),
                    trailing: Text(
                      '${(h['amount'] as num).toInt() > 0 ? '+' : ''}${h['amount']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: (h['amount'] as num) > 0
                            ? successColor(context)
                            : scheme.error,
                      ),
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
