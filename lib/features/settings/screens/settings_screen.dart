// Settings screen - account, notifications, goal, about
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/firebase_service.dart';
import '../../walkthrough/screens/walkthrough_screen.dart';

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
              _buildSectionHeader('Account'),
              const SizedBox(height: 12),
              const _AccountTile(),
              const SizedBox(height: 32),
              _buildSectionHeader('Notifications'),
              const SizedBox(height: 12),
              _NotificationToggleTile(),
              const SizedBox(height: 12),
              _QuietModeToggleTile(),
              const SizedBox(height: 12),
              _ReminderTimeTile(),
              const SizedBox(height: 12),
              _TestNotificationTile(),
              const SizedBox(height: 32),
              _buildSectionHeader('Goal'),
              const SizedBox(height: 12),
              _GoalDaysTile(),
              const SizedBox(height: 32),
              _buildSectionHeader('About'),
              const SizedBox(height: 12),
              _buildTapTile(
                context: context,
                icon: Icons.explore_outlined,
                title: 'Take a Tour',
                subtitle: 'See what Stillspace can do',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WalkthroughScreen(showSkip: false),
                  ),
                ),
              ),
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

  Widget _buildTapTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body1),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
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

class _QuietModeToggleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.read<StreakProvider>();
    final sessionProvider = context.read<SessionProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.do_not_disturb_on_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quiet session mode', style: AppTextStyles.body1),
                const SizedBox(height: 2),
                Text(
                  userProvider.quietModeEnabled
                      ? 'Silences Stillspace reminders during active sessions.'
                      : 'Reminders remain active even when a session is running.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: userProvider.quietModeEnabled,
            onChanged: (value) async {
              await userProvider.setQuietModeEnabled(value);
              if (!value && NotificationService().quietModeActive) {
                await NotificationService().exitQuietMode(
                  notificationsEnabled: userProvider.notificationsEnabled,
                  time: userProvider.notificationTime,
                  currentStreak: streakProvider.currentStreak,
                  daysLeftToGoal: streakProvider.daysLeftToGoal,
                  missedYesterday: streakProvider.missedYesterday,
                );
              } else if (value && sessionProvider.isSessionActive && !NotificationService().quietModeActive) {
                await NotificationService().enterQuietMode();
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

class _TestNotificationTile extends StatefulWidget {
  @override
  State<_TestNotificationTile> createState() => _TestNotificationTileState();
}

class _TestNotificationTileState extends State<_TestNotificationTile> {
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return GestureDetector(
      onTap: userProvider.notificationsEnabled && !_isTesting
          ? () async {
              setState(() => _isTesting = true);
              await NotificationService().scheduleTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification scheduled in 5 seconds'),
                    backgroundColor: AppColors.surface,
                    duration: Duration(seconds: 3),
                  ),
                );
                await Future.delayed(const Duration(seconds: 6));
                if (mounted) setState(() => _isTesting = false);
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
              Icons.notifications_active_outlined,
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
                    'Test Notification',
                    style: AppTextStyles.body1.copyWith(
                      color: userProvider.notificationsEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isTesting ? 'Sending...' : 'Tap to test in 5 seconds',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (_isTesting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
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

class _AccountTile extends StatefulWidget {
  const _AccountTile();

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  bool _isLoading = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final isSignedIn = firebaseService.isSignedIn;
    final user = firebaseService.currentUser;

    if (isSignedIn) {
      return _buildSignedInView(user);
    } else {
      return _buildSignedOutView();
    }
  }

  Widget _buildSignedOutView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Cloud Backup', style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              Text(
                'Sign in to securely backup your meditation progress, journal entries, and streaks.',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildGoogleSignInButton(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBenefitChip(Icons.backup, 'Auto backup'),
                  const SizedBox(width: 12),
                  _buildBenefitChip(Icons.devices, 'Sync devices'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _signIn,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
              )
            else ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignedInView(dynamic user) {
    final streakProvider = context.watch<StreakProvider>();
    final journalProvider = context.watch<JournalProvider>();

    return Column(
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: user?.photoURL != null
                        ? ClipOval(
                            child: Image.network(
                              user!.photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                          )
                        : const Icon(Icons.person, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Stillspace User',
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Backup active',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sync status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cloud Sync', style: AppTextStyles.label),
                        Text(
                          _lastSyncTime != null
                              ? 'Last synced ${_formatSyncTime(_lastSyncTime!)}'
                              : 'Synced automatically',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSyncing ? null : _syncData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.sync, color: AppColors.primary, size: 18),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.background, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSyncStat(
                    '${streakProvider.totalSessions}',
                    'Sessions',
                  ),
                  _buildSyncStat(
                    '${journalProvider.recentEntries.length}',
                    'Entries',
                  ),
                  _buildSyncStat(
                    '${streakProvider.currentStreak}',
                    'Streak',
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.background, height: 1),
              ),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto-syncs once per day on app open + after every change',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sign out button
        GestureDetector(
          onTap: () => _showSignOutDialog(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.error.withValues(alpha: 0.8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign Out',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.error.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: AppTextStyles.headline3),
        content: Text(
          'Your data is safely backed up. You can sign in again anytime to restore it.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            child: Text(
              'Sign Out',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await FirebaseService().signInWithGoogle();

      if (user != null && mounted) {
        // Merge cloud into local (never resets local progress), then push merged result back
        await FirebaseService().syncAllDataFromCloud();
        await FirebaseService().syncAllDataToCloud();
        _refreshProviders();
        setState(() => _lastSyncTime = DateTime.now());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in failed. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseService().signOut();
    if (mounted) {
      setState(() => _lastSyncTime = null);
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      await FirebaseService().syncAllDataToCloud();

      if (mounted) {
        setState(() {
          _isSyncing = false;
          _lastSyncTime = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced successfully'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed. Check your connection.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _refreshProviders() {
    context.read<UserProvider>().init();
    context.read<StreakProvider>().init();
    context.read<MoodProvider>().init();
    context.read<JournalProvider>().init();
  }
}
