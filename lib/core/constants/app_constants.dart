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
}
