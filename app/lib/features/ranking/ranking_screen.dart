import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ranking_service.dart';
import 'widgets/leaderboard_row.dart';

final _rankingScopeProvider = StateProvider.autoDispose((ref) => RankingScope.city);

final rankingProvider = FutureProvider.autoDispose((ref) {
  final scope = ref.watch(_rankingScopeProvider);
  return ref.watch(rankingServiceProvider).fetchLeaderboard(scope: scope);
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  static const _scopeLabels = {
    RankingScope.city: 'Cidade',
    RankingScope.club: 'Clube',
    RankingScope.friends: 'Amigos',
    RankingScope.state: 'Estado',
    RankingScope.country: 'País',
    RankingScope.global: 'Global',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(_rankingScopeProvider);
    final ranking = ref.watch(rankingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _scopeLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entryScope = _scopeLabels.keys.elementAt(index);
                final selected = entryScope == scope;
                return ChoiceChip(
                  label: Text(_scopeLabels[entryScope]!),
                  selected: selected,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
                  onSelected: (_) => ref.read(_rankingScopeProvider.notifier).state = entryScope,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ranking.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (error, stack) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(rankingProvider),
                  child: const Text('Não foi possível carregar o ranking. Tentar novamente.'),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(child: Text('Ninguém no ranking ainda.', style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => LeaderboardRow(entry: entries[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
