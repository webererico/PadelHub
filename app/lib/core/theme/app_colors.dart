import 'package:flutter/material.dart';

/// Palette matched to the PadelHub design canvas (Claude Design):
/// dark petrol teal background, vibrant orange accent.
abstract final class AppColors {
  static const Color background = Color(0xFF0E2926);
  static const Color surface = Color(0xFF163B37);
  static const Color surfaceRaised = Color(0xFF1C4642);
  static const Color border = Color(0xFF2C5450);

  static const Color textPrimary = Color(0xFFF7F5F0);
  static const Color textSecondary = Color(0xFFB9CFCB);
  static const Color textTertiary = Color(0xFF7FA29C);

  static const Color accent = Color(0xFFE8793A);
  static const Color accentStrong = Color(0xFFD96A2E);

  static const Color success = Color(0xFF6FE0B8);
  static const Color danger = Color(0xFFE15C4D);

  /// Patente (rank tier) colors, in ascending order.
  static const Color rankIniciante = Color(0xFF9BB3AF);
  static const Color rankDefensorDeVidro = Color(0xFF6FB8D9);
  static const Color rankMestreDoSmash = accent;
  static const Color rankLendaDaQuadra = Color(0xFFE8C468);
}
