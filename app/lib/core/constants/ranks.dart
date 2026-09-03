import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Patentes dinâmicas: substituem as categorias estáticas (5ª, 4ª, 3ª...)
/// por uma faixa de rating ELO, do menor para o maior.
enum PlayerRank {
  iniciante(label: 'Iniciante', minRating: 0, color: AppColors.rankIniciante),
  defensorDeVidro(label: 'Defensor de Vidro', minRating: 1200, color: AppColors.rankDefensorDeVidro),
  mestreDoSmash(label: 'Mestre do Smash', minRating: 1700, color: AppColors.rankMestreDoSmash),
  lendaDaQuadra(label: 'Lenda da Quadra', minRating: 2200, color: AppColors.rankLendaDaQuadra);

  const PlayerRank({required this.label, required this.minRating, required this.color});

  final String label;
  final int minRating;
  final Color color;

  static PlayerRank fromRating(int rating) {
    PlayerRank current = PlayerRank.iniciante;
    for (final rank in PlayerRank.values) {
      if (rating >= rank.minRating) current = rank;
    }
    return current;
  }
}
