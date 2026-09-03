import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/arena.dart';
import '../../models/leaderboard_entry.dart';
import '../../widgets/app_avatar.dart';

class _ArenaData {
  const _ArenaData({required this.arena, required this.live, required this.ranking});

  final Arena arena;
  final List<LiveMatch> live;
  final List<LeaderboardEntry> ranking;
}

final _arenaProvider = FutureProvider.autoDispose.family<_ArenaData, String>((ref, arenaId) async {
  final service = ref.watch(arenaServiceProvider);
  final results = await Future.wait([
    service.fetchArena(arenaId),
    service.fetchLiveMatches(arenaId),
    service.fetchInternalRanking(arenaId),
  ]);
  return _ArenaData(arena: results[0] as Arena, live: results[1] as List<LiveMatch>, ranking: results[2] as List<LeaderboardEntry>);
});

class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key, required this.arenaId});

  final String arenaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_arenaProvider(arenaId));

    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stack) => Center(
          child: TextButton(onPressed: () => ref.invalidate(_arenaProvider(arenaId)), child: const Text('Não foi possível carregar a arena.')),
        ),
        data: (arenaData) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 150,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.surfaceRaised, AppColors.background])),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(arenaData.arena.name, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text('${arenaData.arena.city}, ${arenaData.arena.state}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      // A plain GestureDetector, not OutlinedButton: Material's
                      // button here (Row > Expanded, inside a sliver list)
                      // collapses to zero width on Flutter web's html
                      // renderer, splitting the sibling Text onto one
                      // character per line. Confirmed by direct testing.
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                          child: const Text('Seguir', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ArenaStat(value: '${arenaData.arena.courtCount}', label: 'quadras'),
                      const SizedBox(width: 20),
                      _ArenaStat(value: '${arenaData.arena.activePlayerCount}', label: 'jogadores'),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('AO VIVO AGORA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
                  const SizedBox(height: 12),
                  if (arenaData.live.isEmpty)
                    const Text('Nenhuma partida em quadra agora.', style: TextStyle(color: AppColors.textSecondary))
                  else
                    for (final match in arenaData.live) _LiveMatchTile(match: match),
                  const SizedBox(height: 24),
                  const Text('TOP DO CLUBE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
                  const SizedBox(height: 12),
                  for (final entry in arenaData.ranking.take(5)) _ClubRankRow(entry: entry),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaStat extends StatelessWidget {
  const _ArenaStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        children: [
          TextSpan(text: value),
          TextSpan(text: ' $label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _LiveMatchTile extends StatelessWidget {
  const _LiveMatchTile({required this.match});

  final LiveMatch match;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.courtLabel, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text(match.teamA, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('vs ${match.teamB}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(match.scoreLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

class _ClubRankRow extends StatelessWidget {
  const _ClubRankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text('${entry.position}', style: const TextStyle(fontWeight: FontWeight.w700))),
          AppAvatar(initials: entry.initials, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(entry.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Text('${entry.rating}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
