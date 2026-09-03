import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../arena/my_arena_tab.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../ranking/ranking_screen.dart';

/// Hosts the bottom-nav tabs. "+" (index 2) isn't a tab — it opens a choice
/// sheet between recording a match and creating a Super 8/12 event.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tabIndex = 0;

  static const _tabs = [FeedScreen(), RankingScreen(), MyArenaTab(), ProfileScreen()];

  void _onDestinationSelected(int index) {
    if (index == 2) {
      _showCreateChoiceSheet();
      return;
    }
    setState(() => _tabIndex = index < 2 ? index : index - 1);
  }

  Future<void> _showCreateChoiceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sports_tennis, color: AppColors.accent),
              title: const Text('Registrar Partida', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Lançar o placar de uma partida com validação cruzada'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/record');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups, color: AppColors.accent),
              title: const Text('Criar Super 8/12', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Gerar o rodízio completo com duplas rotativas'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/events/new');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Blocks the tabs (which each fetch data for the signed-in uid) until a
    // matching Postgres row is guaranteed to exist — avoids a race where a
    // tab's own fetch 404s because it ran before the profile was created.
    final ensured = ref.watch(ensureProfileProvider);

    return Scaffold(
      body: ensured.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stack) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(ensureProfileProvider),
            child: const Text('Não foi possível preparar seu perfil. Tentar novamente.'),
          ),
        ),
        data: (_) => IndexedStack(index: _tabIndex, children: _tabs),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.16),
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
