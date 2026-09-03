import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.background = AppColors.surfaceRaised,
    this.borderColor,
  });

  final String initials;
  final double size;
  final Color background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Two avatars overlapped, used for a dupla (pair) header.
class DuplaAvatars extends StatelessWidget {
  const DuplaAvatars({super.key, required this.first, required this.second, this.size = 36});

  final String first;
  final String second;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size,
      child: Stack(
        children: [
          AppAvatar(initials: first, size: size, background: AppColors.surface, borderColor: AppColors.background),
          Positioned(
            left: size * 0.6,
            child: AppAvatar(initials: second, size: size, background: AppColors.accentStrong, borderColor: AppColors.background),
          ),
        ],
      ),
    );
  }
}
