import 'package:flutter/material.dart';
import '../theme.dart';
import 'leaderboard_screen.dart';
import 'map_screen.dart';
import 'pending_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Peta', 'Menunggu', 'Ranking', 'Ganjaran', 'Tetapan'];

  Widget _tab(int i) => switch (i) {
        0 => const MapScreen(),
        1 => const PendingScreen(),
        2 => const LeaderboardScreen(),
        3 => const RewardsScreen(),
        _ => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 28),
              const SizedBox(width: 10),
              Text(_titles[_index]),
            ],
          ),
        ),
        body: _tab(_index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Peta'),
            NavigationDestination(
                icon: Icon(Icons.pending_actions_outlined),
                selectedIcon: Icon(Icons.pending_actions),
                label: 'Menunggu'),
            NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard),
                label: 'Papan Pendahulu'),
            NavigationDestination(
                icon: Icon(Icons.card_giftcard_outlined),
                selectedIcon: Icon(Icons.card_giftcard),
                label: 'Ganjaran'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Tetapan'),
          ],
        ),
      );
}
