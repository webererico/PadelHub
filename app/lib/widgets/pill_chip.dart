import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.background = AppColors.surfaceRaised,
    this.foreground = AppColors.textPrimary,
    this.fontSize = 11,
  });

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class RankBadgeChip extends StatelessWidget {
  const RankBadgeChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PillChip(label: label.toUpperCase(), background: color.withOpacity(0.18), foreground: color, fontSize: 9.5);
  }
}
