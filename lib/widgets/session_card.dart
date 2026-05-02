// SessionCard - displays session type, duration chip, start button
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int durationMinutes;
  final IconData icon;
  final VoidCallback onStart;

  const SessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.icon,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline3),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.body2),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$durationMinutes min',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
