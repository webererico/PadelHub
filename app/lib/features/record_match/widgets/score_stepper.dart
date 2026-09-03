import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SetScoreEntry extends StatelessWidget {
  const SetScoreEntry({
    super.key,
    required this.label,
    required this.teamAGames,
    required this.teamBGames,
    required this.onTeamAChanged,
    required this.onTeamBChanged,
    this.highlighted = false,
  });

  final String label;
  final int teamAGames;
  final int teamBGames;
  final ValueChanged<int> onTeamAChanged;
  final ValueChanged<int> onTeamBChanged;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: highlighted ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: highlighted ? AppColors.accent : AppColors.textTertiary),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GameCounter(value: teamAGames, onChanged: onTeamAChanged, active: teamAGames > teamBGames),
                  const SizedBox(width: 22),
                  const Text('×', style: TextStyle(color: AppColors.textTertiary, fontSize: 18)),
                  const SizedBox(width: 22),
                  _GameCounter(value: teamBGames, onChanged: onTeamBChanged, active: teamBGames > teamAGames),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCounter extends StatelessWidget {
  const _GameCounter({required this.value, required this.onChanged, required this.active});

  final int value;
  final ValueChanged<int> onChanged;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: AppColors.textTertiary),
          onPressed: () => onChanged(value + 1),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          '$value',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: active ? AppColors.accent : AppColors.textPrimary),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
