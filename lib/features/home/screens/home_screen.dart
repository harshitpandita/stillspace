// Home screen - main dashboard with greeting, recommendations, journey path, daily wisdom
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/recommendation_engine.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/mood_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/wisdom_service.dart';
import '../../learn/screens/learn_screen.dart';
import '../../mood/screens/mood_checkin_screen.dart';
import '../../music/screens/music_screen.dart';
import '../../session/data/breathing_sessions.dart';
import '../../session/screens/breathing_session_screen.dart';
import '../../session/screens/meditate_screen.dart';
import '../../session/screens/session_screen.dart';
import '../../settings/screens/settings_screen.dart';

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
    final userProvider = context.watch<UserProvider>();
    final streakProvider = context.watch<StreakProvider>();
    final moodProvider = context.watch<MoodProvider>();

    final recommendation = RecommendationEngine.getRecommendation(
      moodScore: moodProvider.todaysMood,
      currentStreak: streakProvider.currentStreak,
      daysLeftToGoal: streakProvider.daysLeftToGoal,
      missedYesterday: streakProvider.missedYesterday,
    );

    final goalCompleted = streakProvider.currentStreak >= userProvider.goalDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting(), style: AppTextStyles.body2),
                          Text(userName, style: AppTextStyles.headline1),
                        ],
                      ),
                    ),
                    _buildStreakBadge(context, streakProvider),
                  ],
                ),

                const SizedBox(height: 28),

                // Mood check-in (if needed)
                if (moodProvider.shouldShowMoodCheckIn) ...[
                  _buildMoodPrompt(context),
                  const SizedBox(height: 24),
                ],

                // Section: Today's Practice
                Text('Today\'s Practice', style: AppTextStyles.headline3),
                const SizedBox(height: 14),

                // PRIMARY: Recommended session - BIG and attention-grabbing
                _buildPrimaryRecommendation(context, recommendation),

                const SizedBox(height: 12),

                // Custom session
                _buildCustomSessionCard(context),

                const SizedBox(height: 12),

                // Music section (not part of recommendation engine)
                _buildMusicCard(context),

                const SizedBox(height: 12),

                // Learn Meditation (offline static content)
                _buildLearnCard(context),

                const SizedBox(height: 28),

                // Section: Daily Wisdom
                _buildWisdomCard(),

                const SizedBox(height: 24),

                // Section: Your Journey
                Text('Your Journey', style: AppTextStyles.headline3),
                const SizedBox(height: 14),
                _buildJourneyPath(context, userProvider, streakProvider, goalCompleted),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge(BuildContext context, StreakProvider streakProvider) {
    return GestureDetector(
      onTap: () => _showStreakExplanation(context, streakProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${streakProvider.currentStreak}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day Streak',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.ac_unit,
                      size: 10,
                      color: streakProvider.freezesRemaining > 0
                          ? AppColors.streakFreeze
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${streakProvider.freezesRemaining} freeze',
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMoodCheckIn(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('😊', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How are you feeling?', style: AppTextStyles.label),
                  Text('Log your mood', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryRecommendation(BuildContext context, Recommendation rec) {
    return GestureDetector(
      onTap: () => _startRecommended(context, rec),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.25),
              AppColors.primary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _getIconForSessionType(rec.sessionType),
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RecommendationEngine.getSessionTypeLabel(rec.sessionType),
                        style: AppTextStyles.headline1.copyWith(
                          color: AppColors.primary,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${rec.sessionDuration} minutes',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              rec.promptMessage,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'Start Session',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSessionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MeditateScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.tune, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Custom Session', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    'Pick your duration, choose your sound',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.secondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MusicScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.headphones, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Music', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    'Ambient sounds and frequencies for any mood',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LearnScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_outlined, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Learn Meditation', style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    'Practical reads on techniques and benefits',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.secondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Note',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: WisdomService().getTodaysQuote(),
            builder: (context, snapshot) {
              final quote = snapshot.data ??
                  AppConstants.hardcodedWisdom[
                      DateTime.now().day % AppConstants.hardcodedWisdom.length];
              return Text(
                quote,
                style: AppTextStyles.body1.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyPath(BuildContext context, UserProvider userProvider, StreakProvider streakProvider, bool goalCompleted) {
    final goalDays = userProvider.goalDays;
    final currentDay = streakProvider.currentStreak;
    final progress = (currentDay / goalDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                goalCompleted ? Icons.emoji_events : Icons.flag_outlined,
                color: goalCompleted ? AppColors.primary : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Day $currentDay of $goalDays',
                style: AppTextStyles.label.copyWith(
                  color: goalCompleted ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              if (goalCompleted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Complete!',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            _getJourneyMessage(currentDay, goalDays, goalCompleted),
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),

          if (goalCompleted) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Set new goal',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getJourneyMessage(int currentDay, int goalDays, bool goalCompleted) {
    if (goalCompleted) {
      return "You did it. $goalDays days of showing up for yourself.";
    } else if (currentDay == 0) {
      return "Your $goalDays-day journey begins with a single session.";
    } else if (currentDay == 1) {
      return "Day 1 complete. The hardest part is done.";
    } else if (currentDay < goalDays * 0.5) {
      return "Building momentum. Keep showing up.";
    } else {
      final daysLeft = goalDays - currentDay;
      return "$daysLeft day${daysLeft == 1 ? '' : 's'} to go. Almost there.";
    }
  }

  IconData _getIconForSessionType(SessionType type) {
    switch (type) {
      case SessionType.calming:
        return Icons.spa_outlined;
      case SessionType.energizing:
        return Icons.wb_sunny_outlined;
      case SessionType.focus:
        return Icons.psychology_outlined;
      case SessionType.windDown:
        return Icons.nightlight_outlined;
      case SessionType.standard:
        return Icons.self_improvement;
      case SessionType.wimHof:
        return Icons.air;
    }
  }

  void _startRecommended(BuildContext context, Recommendation rec) {
    if (rec.sessionType == SessionType.wimHof) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BreathingSessionScreen(session: BreathingSessions.wimHof),
        ),
      );
      return;
    }
    _startSession(
      context,
      rec.sessionDuration,
      MeditationSound.none,
      RecommendationEngine.getSessionTypeLabel(rec.sessionType),
    );
  }

  void _showStreakExplanation(BuildContext context, StreakProvider streakProvider) {
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
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Your Streak', style: AppTextStyles.headline2),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.self_improvement,
                      AppColors.primary,
                      'Complete a session',
                      'Meditation counts toward your streak',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.edit_note,
                      AppColors.primary,
                      'Write a journal entry',
                      'Journaling also counts',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.surface, height: 1),
                    ),
                    _buildInfoRow(
                      Icons.ac_unit,
                      AppColors.streakFreeze,
                      'Streak Freeze',
                      streakProvider.freezesRemaining > 0
                          ? '1 available — auto-protects if you miss a day'
                          : 'Used this week — resets soon',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.label),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
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

  void _startSession(BuildContext context, int duration, MeditationSound sound, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          duration: duration,
          sound: sound,
          meditationType: type,
        ),
      ),
    );
  }
}
