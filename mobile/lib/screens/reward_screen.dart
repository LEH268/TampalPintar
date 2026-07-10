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
                    const Text('450', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
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
              _buildVoucherCard(context, 'Touch \'n Go eWallet RM5', '200 pts', 'assets/images/tng.png', true),
              _buildVoucherCard(context, 'Grab Ride RM8', '200 pts', 'assets/images/grab.png', true),
              _buildVoucherCard(context, 'Petronas Fuel RM10', '250 pts', 'assets/images/petronas.png', true),
              _buildVoucherCard(context, 'Shopee Voucher RM15', '500 pts', 'assets/images/shopee.png', false),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, String title, String points, String imagePath, bool canAfford) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.card_giftcard, color: Theme.of(context).colorScheme.primary),
            ),
          ),
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