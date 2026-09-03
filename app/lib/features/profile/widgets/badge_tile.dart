import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/player_badge.dart';

class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.type, this.locked = false});

  final BadgeType type;
  final bool locked;

  static const _colors = {
    BadgeType.pneuFurado: Color(0xFFE0684A),
    BadgeType.nomadeDoPadel: Color(0xFF5FA8CC),
    BadgeType.inimigoDoErro: Color(0xFFE0B94F),
  };

  static const _icons = {
    BadgeType.pneuFurado: Icons.circle_outlined,
    BadgeType.nomadeDoPadel: Icons.place_outlined,
    BadgeType.inimigoDoErro: Icons.check_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: const Icon(Icons.lock_outline, color: AppColors.textTertiary, size: 22),
          ),
          const SizedBox(height: 6),
          const Text('A desbloquear', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
        ],
      );
    }

    final color = _colors[type]!;
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0.6)]),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(_icons[type], color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(type.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
