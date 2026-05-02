// Recommendation engine - suggests sessions and prompts based on user state
import '../../core/constants/app_constants.dart';

enum SessionType { calming, energizing, focus, windDown, standard }

enum Urgency { low, medium, high }

class Recommendation {
  final int sessionDuration;
  final SessionType sessionType;
  final String promptMessage;
  final String? journalPrompt;
  final Urgency urgency;

  const Recommendation({
    required this.sessionDuration,
    required this.sessionType,
    required this.promptMessage,
    this.journalPrompt,
    required this.urgency,
  });
}

class RecommendationEngine {
  static Recommendation getRecommendation({
    int? moodScore,
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
  }) {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 5 && hour < 10;
    final isEvening = hour >= 20 || hour < 5;

    // Priority 1: Close to goal completion
    if (daysLeftToGoal <= 3 && daysLeftToGoal > 0) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.focus,
        promptMessage: _goalCloseMessage(daysLeftToGoal),
        journalPrompt: 'Reflect on how far you\'ve come in your journey.',
        urgency: Urgency.high,
      );
    }

    // Priority 2: Missed yesterday - need to get back on track
    if (missedYesterday) {
      return Recommendation(
        sessionDuration: 5,
        sessionType: SessionType.calming,
        promptMessage: 'Welcome back. A short session can restart your momentum.',
        journalPrompt: 'What got in the way yesterday? How can today be different?',
        urgency: Urgency.high,
      );
    }

    // Priority 3: Low mood - gentle approach
    if (moodScore != null && moodScore <= 2) {
      return Recommendation(
        sessionDuration: 5,
        sessionType: SessionType.calming,
        promptMessage: 'Be gentle with yourself. Even 5 minutes can help.',
        journalPrompt: AppConstants.lowMoodJournalPrompts[
            DateTime.now().millisecond % AppConstants.lowMoodJournalPrompts.length],
        urgency: Urgency.medium,
      );
    }

    // Priority 4: High mood + strong streak - challenge them
    if (moodScore != null && moodScore >= 4 && currentStreak >= 7) {
      return Recommendation(
        sessionDuration: 15,
        sessionType: SessionType.focus,
        promptMessage: 'You\'re in a great flow. Ready for a deeper session?',
        journalPrompt: 'What\'s contributing to your positive state right now?',
        urgency: Urgency.low,
      );
    }

    // Priority 5: Evening - wind down
    if (isEvening) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.windDown,
        promptMessage: 'End your day with calm. Let go of what you\'re carrying.',
        journalPrompt: 'What are you grateful for today?',
        urgency: Urgency.low,
      );
    }

    // Priority 6: Morning - energize
    if (isMorning) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.energizing,
        promptMessage: 'Start your day with intention. Set the tone for what\'s ahead.',
        journalPrompt: 'What do you want to focus on today?',
        urgency: Urgency.low,
      );
    }

    // Default recommendation
    return Recommendation(
      sessionDuration: 10,
      sessionType: SessionType.standard,
      promptMessage: _defaultMessage(currentStreak),
      journalPrompt: null,
      urgency: Urgency.low,
    );
  }

  static String _goalCloseMessage(int daysLeft) {
    if (daysLeft == 1) {
      return 'One day left! You\'re about to complete your goal.';
    }
    return 'Only $daysLeft days to go. You\'re so close—don\'t stop now.';
  }

  static String _defaultMessage(int streak) {
    if (streak == 0) {
      return 'Take a moment for yourself. Your practice awaits.';
    }
    if (streak < 3) {
      return 'Keep building. Day ${streak + 1} starts now.';
    }
    if (streak < 7) {
      return 'Nice momentum! Let\'s keep it going.';
    }
    return '$streak days strong. Ready for today\'s session?';
  }

  static String getSessionTypeLabel(SessionType type) {
    switch (type) {
      case SessionType.calming:
        return 'Calming';
      case SessionType.energizing:
        return 'Energizing';
      case SessionType.focus:
        return 'Focus';
      case SessionType.windDown:
        return 'Wind Down';
      case SessionType.standard:
        return 'Mindfulness';
    }
  }
}
