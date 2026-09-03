import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CourtHero extends StatelessWidget {
  const CourtHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: AppColors.background),
          CustomPaint(size: Size.infinite, painter: _CourtPainter()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sports_tennis, color: AppColors.accent, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'PadelHub',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: -0.3),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'O STRAVA DO PADEL',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final courtPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(size.width * 0.16, size.height * 0.18, size.width * 0.68, size.height * 0.72);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, courtPaint);
    canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), courtPaint);

    final dashPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2;
    double y = rect.top;
    while (y < rect.bottom) {
      canvas.drawLine(Offset(rect.center.dx, y), Offset(rect.center.dx, y + 6), dashPaint);
      y += 12;
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 70, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
