import 'package:flutter/material.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      appBar: AppBar(title: const Text('Rewards Center')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Available Points', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('1,250', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () {},
                      style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                      child: const Text('View Points History', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Redeem Vouchers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildVoucherCard(context, 'Touch \'n Go eWallet RM5', '150 pts', Icons.account_balance_wallet, true),
              _buildVoucherCard(context, 'Grab Ride RM8', '200 pts', Icons.local_taxi, true),
              _buildVoucherCard(context, 'Petronas RM10', '250 pts', Icons.local_gas_station, true),
              _buildVoucherCard(context, 'Shopee RM15', '400 pts', Icons.shopping_bag, false),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, String title, String points, IconData icon, bool canAfford) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(points, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
        trailing: FilledButton(
          onPressed: canAfford ? () {} : null,
          child: const Text('Redeem'),
        ),
      ),
    );
  }
}