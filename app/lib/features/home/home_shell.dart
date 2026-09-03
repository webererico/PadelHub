import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../arena/arena_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../ranking/ranking_screen.dart';

/// Hosts the bottom-nav tabs. "Registrar" (index 2) isn't a tab — it pushes
/// the full-screen record-match flow instead of swapping the IndexedStack.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  static const _tabs = [FeedScreen(), RankingScreen(), ArenaScreen(arenaId: 'arena-padel-club'), ProfileScreen()];

  void _onDestinationSelected(int index) {
    if (index == 2) {
      context.push('/record');
      return;
    }
    setState(() => _tabIndex = index < 2 ? index : index - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.16),
        selectedIndex: _tabIndex < 2 ? _tabIndex : _tabIndex + 1,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.accent), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: AppColors.accent), label: 'Ranking'),
          NavigationDestination(icon: Icon(Icons.add_circle, color: AppColors.accent, size: 30), label: 'Registrar'),
          NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place, color: AppColors.accent), label: 'Arenas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.accent), label: 'Perfil'),
        ],
      ),
    );
  }
}
