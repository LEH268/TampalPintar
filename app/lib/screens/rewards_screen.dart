import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/rewards_service.dart';

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
        title: const Text('Confirm redemption'),
        content: Text(
            'Spend ${item['points_cost']} points on ${item['name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Redeem')),
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
          title: const Text('Voucher redeemed!'),
          content: SelectableText('Your code: $code'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done')),
          ],
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Redemption failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Spendable balance'),
                Text('$_balance pts',
                    style: Theme.of(context).textTheme.headlineMedium),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('Voucher catalog',
              style: Theme.of(context).textTheme.titleMedium),
          for (final item in _catalog)
            ListTile(
              title: Text(item['name']),
              subtitle: Text('${item['brand']} · RM${item['value_rm']}'),
              trailing: FilledButton(
                onPressed: _balance >= (item['points_cost'] as num).toInt()
                    ? () => _redeem(item)
                    : null, // affordability-disabled
                child: Text('${item['points_cost']} pts'),
              ),
            ),
          const Divider(height: 32),
          Text('My Vouchers', style: Theme.of(context).textTheme.titleMedium),
          if (_vouchers.isEmpty) const Text('Nothing redeemed yet.'),
          for (final v in _vouchers)
            ListTile(
              leading: const Icon(Icons.confirmation_number),
              title: Text(v['name']),
              subtitle: SelectableText(v['code']),
            ),
          const Divider(height: 32),
          Text('Points history',
              style: Theme.of(context).textTheme.titleMedium),
          for (final h in _history)
            ListTile(
              dense: true,
              title: Text(h['reason'] ?? ''),
              trailing: Text(
                '${(h['amount'] as num).toInt() > 0 ? '+' : ''}${h['amount']}',
                style: TextStyle(
                    color: (h['amount'] as num) > 0
                        ? Colors.green
                        : Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
