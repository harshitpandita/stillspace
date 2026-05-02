// Settings screen - notification toggle, reminder time, about
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: AppTextStyles.headline3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Notifications'),
              const SizedBox(height: 12),
              _NotificationToggleTile(),
              const SizedBox(height: 12),
              _ReminderTimeTile(),
              const SizedBox(height: 32),
              _buildSectionHeader('Goal'),
              const SizedBox(height: 12),
              _GoalDaysTile(),
              const SizedBox(height: 32),
              _buildSectionHeader('About'),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.info_outline,
                title: AppConstants.appName,
                subtitle: 'Version 1.0.0',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.self_improvement,
                title: 'Your mindfulness companion',
                subtitle: 'Build consistency, find calm',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body1),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.read<StreakProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Reminders', style: AppTextStyles.body1),
                const SizedBox(height: 2),
                Text(
                  userProvider.notificationsEnabled ? 'Enabled' : 'Disabled',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: userProvider.notificationsEnabled,
            onChanged: (value) async {
              await userProvider.setNotificationsEnabled(value);
              if (value) {
                await NotificationService().requestPermissions();
                await NotificationService().scheduleDailyReminder(
                  time: userProvider.notificationTime,
                  currentStreak: streakProvider.currentStreak,
                  daysLeftToGoal: streakProvider.daysLeftToGoal,
                  missedYesterday: streakProvider.missedYesterday,
                );
              } else {
                await NotificationService().cancelAllNotifications();
              }
            },
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.background,
          ),
        ],
      ),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.read<StreakProvider>();

    final timeParts = userProvider.notificationTime.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return GestureDetector(
      onTap: userProvider.notificationsEnabled
          ? () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: timeOfDay,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        surface: AppColors.surface,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final timeString =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                await userProvider.updateNotificationTime(timeString);
                await NotificationService().scheduleDailyReminder(
                  time: timeString,
                  currentStreak: streakProvider.currentStreak,
                  daysLeftToGoal: streakProvider.daysLeftToGoal,
                  missedYesterday: streakProvider.missedYesterday,
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: userProvider.notificationsEnabled
                  ? AppColors.primary
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Time',
                    style: AppTextStyles.body1.copyWith(
                      color: userProvider.notificationsEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeOfDay.format(context),
                    style: AppTextStyles.caption.copyWith(
                      color: userProvider.notificationsEnabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: userProvider.notificationsEnabled
                  ? AppColors.textSecondary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDaysTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return GestureDetector(
      onTap: () => _showGoalPicker(context, userProvider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Duration', style: AppTextStyles.body1),
                  const SizedBox(height: 2),
                  Text(
                    '${userProvider.goalDays} days',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showGoalPicker(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Goal Duration', style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              Text(
                'Your progress will be preserved.',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: 24),
              ...List.generate(4, (index) {
                final days = [7, 14, 21, 30][index];
                final labels = ['1 Week', '2 Weeks', '3 Weeks', '1 Month'];
                final isSelected = userProvider.goalDays == days;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      await userProvider.updateGoalDays(days);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$days days',
                            style: AppTextStyles.body1.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(labels[index], style: AppTextStyles.caption),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
