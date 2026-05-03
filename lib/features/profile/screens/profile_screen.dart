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

              // Header
              _buildHeader(context, userProvider),

              const SizedBox(height: 24),

              // Stats row - at the top
              _buildStatsRow(streakProvider, journalProvider),

              const SizedBox(height: 24),

              // Total time card (if they've meditated)
              if (streakProvider.totalMinutesMeditated > 0) ...[
                _buildTotalTimeCard(streakProvider),
                const SizedBox(height: 24),
              ],

              // Streak Calendar with insight label
              _buildSectionLabel('Your Consistency', 'Activity over the last 30 days'),
              const SizedBox(height: 12),
              const StreakCalendar(),

              const SizedBox(height: 24),

              // Mood Chart with insight label
              _buildSectionLabel('Mood Trends', 'How you\'ve been feeling this week'),
              const SizedBox(height: 12),
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              userProvider.userName?.isNotEmpty == true
                  ? userProvider.userName![0].toUpperCase()
                  : '?',
              style: AppTextStyles.headline2.copyWith(color: AppColors.background),
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
              const SizedBox(height: 2),
              Text(
                '${userProvider.goalDays}-day journey',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
          ),
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
            icon: Icons.book_outlined,
            value: '${journalProvider.entries.length}',
            label: 'Entries',
            color: AppColors.streakFreeze,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTimeCard(StreakProvider streakProvider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.self_improvement, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakProvider.formattedTotalTime,
                  style: AppTextStyles.headline2.copyWith(color: AppColors.primary),
                ),
                Text(
                  'Total time meditated',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${streakProvider.totalSessions}',
                style: AppTextStyles.headline3.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'sessions',
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headline3),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyles.caption),
      ],
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
