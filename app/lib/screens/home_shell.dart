import 'package:flutter/material.dart';
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

  // Tabs 0-3 are replaced by Tasks 29 (Map), 31 (Pending), 32 (Leaderboard),
  // 33 (Rewards). Each of those tasks swaps exactly one line here.
  static const _titles = ['Map', 'Pending', 'Leaderboard', 'Rewards', 'Settings'];

  Widget _tab(int i) => switch (i) {
        0 => const MapScreen(),
        1 => const PendingScreen(),
        2 => const LeaderboardScreen(),
        3 => const RewardsScreen(),
        _ => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('TampalPintar — ${_titles[_index]}')),
        body: _tab(_index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
            NavigationDestination(
                icon: Icon(Icons.pending_actions), label: 'Pending'),
            NavigationDestination(
                icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
            NavigationDestination(
                icon: Icon(Icons.card_giftcard), label: 'Rewards'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
}
