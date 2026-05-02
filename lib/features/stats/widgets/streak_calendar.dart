// Streak calendar widget - 30-day horizontal grid showing completion status
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/streak_provider.dart';

class StreakCalendar extends StatelessWidget {
  const StreakCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final streakProvider = context.watch<StreakProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Streak Calendar', style: AppTextStyles.headline3),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${streakProvider.currentStreak}',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your consistency at a glance',
            style: AppTextStyles.insightLabel,
          ),
          const SizedBox(height: 20),
          _buildCalendarGrid(streakProvider),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(StreakProvider streakProvider) {
    final now = DateTime.now();
    final days = <DateTime>[];

    for (int i = 29; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final date = days[index];
        final isToday = _isToday(date);
        final isCompleted = streakProvider.isDateCompleted(date);
        final isFreeze = streakProvider.isDateFreeze(date);
        final isFuture = date.isAfter(now);

        return _CalendarDay(
          date: date,
          isToday: isToday,
          isCompleted: isCompleted,
          isFreeze: isFreeze,
          isFuture: isFuture,
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppColors.primary, 'Completed'),
        const SizedBox(width: 16),
        _legendItem(AppColors.streakFreeze, 'Freeze'),
        const SizedBox(width: 16),
        _legendItem(AppColors.streakMissed, 'Missed'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isCompleted;
  final bool isFreeze;
  final bool isFuture;

  const _CalendarDay({
    required this.date,
    required this.isToday,
    required this.isCompleted,
    required this.isFreeze,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color? borderColor;

    if (isFuture) {
      bgColor = AppColors.background;
    } else if (isCompleted) {
      bgColor = AppColors.primary;
    } else if (isFreeze) {
      bgColor = AppColors.streakFreeze;
    } else {
      bgColor = AppColors.streakMissed;
    }

    if (isToday) {
      borderColor = AppColors.textPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isCompleted || isFreeze
                ? AppColors.background
                : (isFuture ? AppColors.textSecondary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
