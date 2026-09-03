import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/ranks.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/match.dart';
import '../../models/player_badge.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/pill_chip.dart';
import 'widgets/badge_tile.dart';
import 'widgets/rating_chart.dart';

class _ProfileData {
  const _ProfileData({required this.user, required this.ratingHistory, required this.badges, required this.recentMatches});

  final AppUser user;
  final List<double> ratingHistory;
  final List<PlayerBadge> badges;
  final List<PadelMatch> recentMatches;
}

final _profileProvider = FutureProvider.autoDispose((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return null;
  final userService = ref.watch(userServiceProvider);
  final matchService = ref.watch(matchServiceProvider);
  final results = await Future.wait([
    userService.fetchProfile(uid),
    userService.fetchRatingHistory(uid),
    userService.fetchBadges(uid),
    matchService.fetchHistory(uid),
  ]);
  return _ProfileData(
    user: results[0] as AppUser,
    ratingHistory: results[1] as List<double>,
    badges: results[2] as List<PlayerBadge>,
    recentMatches: results[3] as List<PadelMatch>,
  );
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(_profileProvider);

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (error, stack) => Center(
          child: TextButton(onPressed: () => ref.invalidate(_profileProvider), child: const Text('Não foi possível carregar o perfil.')),
        ),
        data: (data) {
          if (data == null) return const Center(child: Text('Faça login para ver seu perfil.'));
          final rank = PlayerRank.fromRating(data.user.rating);
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ProfileHeader(user: data.user, rank: rank),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: _StatTile(value: '${data.user.rating}', label: 'Rating')),
                    const SizedBox(width: 10),
                    const Expanded(child: _StatTile(value: '68%', label: 'Vitórias', valueColor: AppColors.success)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatTile(value: '${data.recentMatches.length}', label: 'Partidas')),
                  ],
                ),
              ),
              if (data.ratingHistory.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EVOLUÇÃO DO RATING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
                          const SizedBox(height: 10),
                          SizedBox(height: 90, child: RatingChart(points: data.ratingHistory)),
                        ],
                      ),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text('MEDALHAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    for (final badgeType in BadgeType.values) ...[
                      Expanded(child: BadgeTile(type: badgeType, locked: !data.badges.any((b) => b.type == badgeType))),
                      if (badgeType != BadgeType.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text('ÚLTIMAS PARTIDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
              ),
              for (final match in data.recentMatches.take(5))
                _RecentMatchRow(match: match),
              if (data.user.isAdmin) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => context.push('/admin'),
                      leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.accent),
                      title: const Text('Painel Admin', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Cadastrar arenas', style: TextStyle(color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.rank});

  final AppUser user;
  final PlayerRank rank;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 118,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.surfaceRaised, AppColors.background]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 78),
              AppAvatar(initials: user.initials, size: 80, borderColor: AppColors.background),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          [user.clubName, user.city].where((e) => e != null).join(' · '),
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  RankBadgeChip(label: rank.label, color: rank.color),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _RecentMatchRow extends StatelessWidget {
  const _RecentMatchRow({required this.match});

  final PadelMatch match;

  @override
  Widget build(BuildContext context) {
    final won = match.teamAWonMatch;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Container(width: 6, height: 32, decoration: BoxDecoration(color: won ? AppColors.success : AppColors.danger, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs ${match.teamB.map((p) => p.name).join(' & ')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(match.sets.map((s) => '${s.teamA}/${s.teamB}').join(' · '), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
