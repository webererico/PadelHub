import 'package:flutter/material.dart';

import '../../../core/constants/ranks.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/leaderboard_entry.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/pill_chip.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key, required this.entry, this.highlighted = false});

  final LeaderboardEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final rank = PlayerRank.fromRating(entry.rating);
    final positive = entry.ratingDelta >= 0;

    final content = Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            '${entry.position}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: highlighted ? AppColors.accent : AppColors.textTertiary),
          ),
        ),
        const SizedBox(width: 10),
        AppAvatar(initials: entry.initials, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              RankBadgeChip(label: rank.label, color: rank.color),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${entry.rating}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(
              '${positive ? '↑' : '↓'} ${entry.ratingDelta.abs()}',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: positive ? AppColors.success : AppColors.danger),
            ),
          ],
        ),
      ],
    );

    if (!highlighted) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: content);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: content,
    );
  }
}
