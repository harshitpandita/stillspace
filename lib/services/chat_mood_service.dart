// Chat mood models - shared types for AI-based mood inference.
class ChatMoodSnapshot {
  final int score;
  final String label;

  const ChatMoodSnapshot({
    required this.score,
    required this.label,
  });

  static String labelForScore(int score) {
    switch (score) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Neutral';
    }
  }
}
