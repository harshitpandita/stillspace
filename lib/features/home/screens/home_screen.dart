// Home screen - main dashboard with greeting, streak, mood prompt, session cards
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/mood_provider.dart';
import '../../../widgets/session_card.dart';
import '../../mood/screens/mood_checkin_screen.dart';
import '../../session/screens/session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserProvider>().userName ?? 'there';
    final streakProvider = context.watch<StreakProvider>();
    final moodProvider = context.watch<MoodProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '${_getGreeting()},',
                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
              ),
              Text(userName, style: AppTextStyles.headline1),
              const SizedBox(height: 24),

              _buildStreakCard(context, streakProvider),
              const SizedBox(height: 20),

              if (moodProvider.shouldShowMoodCheckIn) ...[
                _buildMoodPrompt(context),
                const SizedBox(height: 20),
              ],

              Text('Today\'s Sessions', style: AppTextStyles.headline3),
              const SizedBox(height: 16),

              SessionCard(
                title: 'Quick Calm',
                subtitle: 'A short breathing exercise',
                durationMinutes: 5,
                icon: Icons.air,
                onStart: () => _startSession(context, 5),
              ),
              const SizedBox(height: 12),

              SessionCard(
                title: 'Mindful Moment',
                subtitle: 'Focus and center yourself',
                durationMinutes: 10,
                icon: Icons.self_improvement,
                onStart: () => _startSession(context, 10),
              ),
              const SizedBox(height: 12),

              SessionCard(
                title: 'Deep Meditation',
                subtitle: 'Extended mindfulness practice',
                durationMinutes: 15,
                icon: Icons.spa,
                onStart: () => _startSession(context, 15),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, StreakProvider streakProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${streakProvider.currentStreak}',
                style: AppTextStyles.streakNumber,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day Streak', style: AppTextStyles.headline3),
                const SizedBox(height: 4),
                Text(
                  streakProvider.currentStreak == 0
                      ? 'Start your journey today!'
                      : 'Keep it going! You\'re doing great.',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: streakProvider.freezesRemaining > 0
                          ? AppColors.streakFreeze
                          : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${streakProvider.freezesRemaining} freeze available',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMoodCheckIn(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_emotions_outlined, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling?',
                    style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('Tap to log your mood', style: AppTextStyles.body2),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _openMoodCheckIn(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MoodCheckinScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  void _startSession(BuildContext context, int duration) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionScreen(duration: duration),
      ),
    );
  }
}
