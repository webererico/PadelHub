import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/match.dart';
import '../../../services/match_service.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/pill_chip.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.matchService});

  final PadelMatch match;
  final MatchService matchService;

  @override
  Widget build(BuildContext context) {
    final won = match.teamAWonMatch;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DuplaAvatars(first: match.teamA[0].initials, second: match.teamA[1].initials),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.teamA[0].name} & ${match.teamA[1].name}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${won ? 'venceu' : 'perdeu'} · ${match.arenaName ?? 'Partida amistosa'} · ${_relativeTime(match.playedAt)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                RankBadgeChip(
                  label: won ? 'Vitória' : 'Derrota',
                  color: won ? AppColors.success : AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SetsRow(match: match),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('contra', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ...match.teamB.map((p) => PillChip(label: p.name)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _CountAction(
                  icon: Icons.sports_tennis,
                  count: match.kudosCount,
                  color: AppColors.accent,
                  onTap: () => matchService.giveKudos(match.id),
                ),
                const SizedBox(width: 18),
                _CountAction(icon: Icons.mode_comment_outlined, count: match.commentCount, color: AppColors.textSecondary),
                const Spacer(),
                if (match.ratingDelta != null)
                  Text(
                    '${match.ratingDelta! >= 0 ? '+' : ''}${match.ratingDelta} pts',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: match.ratingDelta! >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}

class _SetsRow extends StatelessWidget {
  const _SetsRow({required this.match});

  final PadelMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final set in match.sets)
            Column(
              children: [
                Text(
                  '${set.teamA}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SpaceGrotesk',
                    color: set.teamAWonSet ? AppColors.accent : AppColors.textTertiary,
                  ),
                ),
                Text(
                  '${set.teamB}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: set.teamAWonSet ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CountAction extends StatelessWidget {
  const _CountAction({required this.icon, required this.count, required this.color, this.onTap});

  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text('$count', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
