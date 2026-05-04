// App-wide constants for Stillspace
class AppConstants {
  AppConstants._();

  static const String appName = 'Stillspace';

  static const String hiveBoxMoodLogs = 'mood_logs';
  static const String hiveBoxJournalEntries = 'journal_entries';
  static const String hiveBoxStreakData = 'streak_data';
  static const String hiveBoxUserProfile = 'user_profile';

  static const List<int> goalDayOptions = [7, 14, 21, 30];

  static const int moodCheckInCooldownHours = 2;

  static const int maxFreezesPerWeek = 1;

  static const List<int> sessionDurations = [5, 10, 15, 20];

  static const int morningHourThreshold = 10;
  static const int eveningHourThreshold = 20;

  static const int notificationFollowUp1Hours = 2;
  static const int notificationFollowUp2Hours = 4;

  static const List<String> moodEmojis = ['😔', '😕', '😐', '🙂', '😊'];

  static const List<String> defaultJournalPrompts = [
    'What are you grateful for today?',
    'What challenged you today and how did you handle it?',
    'What made you smile today?',
    'What is one thing you learned today?',
    'How are you feeling right now, and why?',
    'What would make tomorrow even better?',
  ];

  static const List<String> lowMoodJournalPrompts = [
    'What small thing could bring you comfort right now?',
    'Write about how you\'re feeling without judgment.',
    'What would you say to a friend feeling this way?',
    'What is one thing within your control today?',
    'Describe a moment when you felt at peace.',
  ];

  // Hardcoded daily wisdom — used as fallback pool combined with API-fetched quotes
  static const List<String> hardcodedWisdom = [
    "If it takes less than five minutes, do it now—future you will thank you.",
    "Avoiding a task doesn't remove it; it just adds anxiety on top of it.",
    "You don't need motivation—you need a start. Momentum creates motivation.",
    "Clarity comes from action, not overthinking.",
    "If you keep saying yes to everything, don't be surprised when nothing improves.",
    "What you tolerate becomes your standard.",
    "Rest before you burn out, not after.",
    "If you wouldn't take their advice, don't take their criticism.",
    "You can't control outcomes, but you can control preparation.",
    "Small daily decisions compound into a life you either want or regret.",
    "Watch your thoughts like clouds—don't build a home under every storm.",
    "What you resist persists; what you accept, you can change.",
    "Act fully in the moment, and regret disappears on its own.",
    "Attachment is the root of suffering; learn to hold things lightly.",
    "You don't find peace by fixing the world, but by understanding your mind.",
    "Feelings deserve attention, not automatic obedience.",
    "You don't need everyone to understand you to be valid.",
    "Silence is often a clearer answer than overexplaining.",
    "If you keep abandoning yourself, no relationship will feel safe.",
    "Closure rarely comes from others—it comes from deciding you're done.",
    "Loneliness decreases when you build a life you actually enjoy living.",
    "Not every thought needs to be believed, and not every emotion needs to be acted on.",
    "You can miss someone and still know they're not good for you.",
    "Healing isn't becoming someone new—it's returning to what was always there.",
    "Your patterns will repeat until you interrupt them consciously.",
    "Start before you're ready; ready is a moving target.",
    "If it's important, schedule it. If it's not scheduled, it's optional.",
    "Discipline is choosing what you want most over what you want now.",
    "The hard conversation saves more time than avoiding it ever will.",
    "Stop solving problems that don't exist yet—deal with what's real.",
  ];
}
