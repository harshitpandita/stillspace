// Profile screen - user stats, streak calendar, mood chart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/journal_provider.dart';
import '../../stats/widgets/streak_calendar.dart';
import '../../stats/widgets/mood_chart.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.watch<StreakProvider>();
    final journalProvider = context.watch<JournalProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context, userProvider),
              const SizedBox(height: 24),
              _buildStatsRow(streakProvider, journalProvider),
              const SizedBox(height: 24),
              _buildGoalProgress(userProvider, streakProvider),
              const SizedBox(height: 20),
              const StreakCalendar(),
              const SizedBox(height: 20),
              const MoodChart(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProvider userProvider) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              userProvider.userName?.isNotEmpty == true
                  ? userProvider.userName![0].toUpperCase()
                  : '?',
              style: AppTextStyles.headline1.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userProvider.userName ?? 'User',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 4),
              Text(
                '${userProvider.goalDays}-day journey',
                style: AppTextStyles.body2,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow(StreakProvider streakProvider, JournalProvider journalProvider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            value: '${streakProvider.currentStreak}',
            label: 'Current Streak',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            value: '${streakProvider.longestStreak}',
            label: 'Best Streak',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.book,
            value: '${journalProvider.entries.length}',
            label: 'Entries',
            color: AppColors.streakFreeze,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(UserProvider userProvider, StreakProvider streakProvider) {
    final progress = (streakProvider.currentStreak / userProvider.goalDays).clamp(0.0, 1.0);
    final daysLeft = (userProvider.goalDays - streakProvider.currentStreak).clamp(0, userProvider.goalDays);

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
              const Text('Goal Progress', style: AppTextStyles.headline3),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress >= 1.0
                ? 'Congratulations! You completed your ${userProvider.goalDays}-day goal!'
                : '$daysLeft days left to complete your goal',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
