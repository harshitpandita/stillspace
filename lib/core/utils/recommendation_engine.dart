// Recommendation engine - suggests sessions and prompts based on user state
import '../../core/constants/app_constants.dart';

enum SessionType { calming, energizing, focus, windDown, standard, wimHof }

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
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final hour = currentTime.hour;
    final isBeforeNoon = hour >= 5 && hour < 12;
    final isMorning = hour >= 5 && hour < 10;
    final isEvening = hour >= 20 || hour < 5;
    final isLateEvening = hour >= 20;

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
        promptMessage:
            'Welcome back. A short session can restart your momentum.',
        journalPrompt:
            'What got in the way yesterday? How can today be different?',
        urgency: Urgency.high,
      );
    }

    // Priority 3a: Lower mood + energizing window - Wim Hof breathing to shift state
    if (moodScore != null &&
        moodScore <= 3 &&
        (isBeforeNoon || isLateEvening)) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.wimHof,
        promptMessage:
            'Feeling heavy? Wim Hof breathing can shift your state in 10 minutes.',
        journalPrompt:
            AppConstants.lowMoodJournalPrompts[currentTime.millisecond %
                AppConstants.lowMoodJournalPrompts.length],
        urgency: Urgency.medium,
      );
    }

    // Priority 3b: Low mood - gentle approach
    if (moodScore != null && moodScore <= 2) {
      return Recommendation(
        sessionDuration: 5,
        sessionType: SessionType.calming,
        promptMessage: 'Be gentle with yourself. Even 5 minutes can help.',
        journalPrompt:
            AppConstants.lowMoodJournalPrompts[currentTime.millisecond %
                AppConstants.lowMoodJournalPrompts.length],
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
        promptMessage:
            'End your day with calm. Let go of what you\'re carrying.',
        journalPrompt: 'What are you grateful for today?',
        urgency: Urgency.low,
      );
    }

    // Priority 6: Morning - energize
    if (isMorning) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.energizing,
        promptMessage:
            'Start your day with intention. Set the tone for what\'s ahead.',
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

  static Recommendation getChatRecommendation({
    int? moodScore,
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
    DateTime? now,
  }) {
    if (moodScore == null) {
      return getRecommendation(
        moodScore: null,
        currentStreak: currentStreak,
        daysLeftToGoal: daysLeftToGoal,
        missedYesterday: missedYesterday,
        now: now,
      );
    }

    final currentTime = now ?? DateTime.now();
    final hour = currentTime.hour;
    final isBeforeNoon = hour >= 5 && hour < 12;
    final isMorning = hour >= 5 && hour < 10;
    final isEvening = hour >= 20 || hour < 5;
    final isLateEvening = hour >= 20;

    if (moodScore <= 2) {
      return Recommendation(
        sessionDuration: 5,
        sessionType: SessionType.calming,
        promptMessage: missedYesterday
            ? 'You sound like you need a gentler restart. Let\'s keep today light and steady.'
            : 'You sound like you need something gentle. A short calming session fits here.',
        journalPrompt:
            AppConstants.lowMoodJournalPrompts[currentTime.millisecond %
                AppConstants.lowMoodJournalPrompts.length],
        urgency: Urgency.medium,
      );
    }

    if (moodScore == 3) {
      if (isBeforeNoon || isLateEvening) {
        return Recommendation(
          sessionDuration: 10,
          sessionType: SessionType.wimHof,
          promptMessage:
              'You sound a little in-between. Breathwork could help shift your state.',
          journalPrompt: 'What feels most present for you right now?',
          urgency: Urgency.medium,
        );
      }

      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.standard,
        promptMessage:
            'You sound fairly steady. A simple mindfulness session would fit well.',
        journalPrompt: 'What would make the rest of today feel a little better?',
        urgency: Urgency.low,
      );
    }

    if (moodScore >= 4 && currentStreak >= 7) {
      return Recommendation(
        sessionDuration: 15,
        sessionType: SessionType.focus,
        promptMessage:
            'You sound strong today. This could be a good moment for a deeper session.',
        journalPrompt: 'What is helping you feel grounded today?',
        urgency: Urgency.low,
      );
    }

    if (moodScore >= 4 && isMorning) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.energizing,
        promptMessage:
            'You sound ready to move. An energizing session would match that well.',
        journalPrompt: 'What do you want to carry into the rest of the day?',
        urgency: Urgency.low,
      );
    }

    if (moodScore >= 4 && isEvening) {
      return Recommendation(
        sessionDuration: 10,
        sessionType: SessionType.windDown,
        promptMessage:
            'You sound good. A smooth wind-down could help you end the day well.',
        journalPrompt: 'What felt especially good about today?',
        urgency: Urgency.low,
      );
    }

    return Recommendation(
      sessionDuration: 10,
      sessionType: SessionType.focus,
      promptMessage:
          daysLeftToGoal <= 3
              ? 'You sound ready. Let\'s use that energy and keep your momentum going.'
              : 'You sound ready for something a little more active and focused.',
      journalPrompt: 'What are you feeling more ready for right now?',
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
      case SessionType.wimHof:
        return 'Wim Hof Breathing';
    }
  }
}
