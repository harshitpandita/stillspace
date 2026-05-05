// ChatMoodService - infers a 1-5 mood score from recent AI chat messages.
class ChatMoodSnapshot {
  final int score;
  final String label;

  const ChatMoodSnapshot({
    required this.score,
    required this.label,
  });
}

class ChatMoodService {
  static const int _maxMessagesToAnalyze = 6;

  static const Map<String, int> _veryLowSignals = {
    'hopeless': -5,
    'worthless': -5,
    'empty': -4,
    'numb': -4,
    'panic': -4,
    'terrified': -4,
    'can\'t cope': -5,
    'cant cope': -5,
    'falling apart': -4,
  };

  static const Map<String, int> _lowSignals = {
    'overwhelmed': -3,
    'anxious': -3,
    'anxiety': -3,
    'stressed': -2,
    'worried': -2,
    'down': -2,
    'sad': -3,
    'tired': -2,
    'heavy': -2,
    'upset': -2,
    'angry': -2,
    'frustrated': -2,
    'lonely': -3,
    'drained': -3,
    'burned out': -3,
  };

  static const Map<String, int> _highSignals = {
    'better': 2,
    'calm': 2,
    'hopeful': 3,
    'grateful': 3,
    'relieved': 2,
    'lighter': 2,
    'good': 2,
    'pretty good': 2,
  };

  static const Map<String, int> _veryHighSignals = {
    'great': 4,
    'amazing': 4,
    'joyful': 4,
    'excited': 3,
    'happy': 3,
    'energized': 3,
    'proud': 3,
  };

  static const List<String> _neutralSignals = [
    'okay',
    'ok',
    'fine',
    'meh',
    'so so',
    'alright',
    'not sure',
  ];

  ChatMoodSnapshot? analyzeUserMessages(List<String> userMessages) {
    if (userMessages.isEmpty) return null;

    final recentMessages = userMessages
        .where((message) => message.trim().isNotEmpty)
        .toList();
    if (recentMessages.isEmpty) return null;

    final window = recentMessages.length > _maxMessagesToAnalyze
        ? recentMessages.sublist(recentMessages.length - _maxMessagesToAnalyze)
        : recentMessages;
    final combined = window.join(' ').toLowerCase();

    var sentimentScore = 0;
    sentimentScore += _scoreSignals(combined, _veryLowSignals);
    sentimentScore += _scoreSignals(combined, _lowSignals);
    sentimentScore += _scoreSignals(combined, _highSignals);
    sentimentScore += _scoreSignals(combined, _veryHighSignals);

    if (_containsAny(combined, const ['not okay', 'not ok', 'not good'])) {
      sentimentScore -= 3;
    }
    if (_containsAny(combined, const ['not bad', 'doing okay now', 'feeling better'])) {
      sentimentScore += 2;
    }

    if (sentimentScore == 0 && _containsAny(combined, _neutralSignals)) {
      return const ChatMoodSnapshot(score: 3, label: 'Neutral');
    }

    if (sentimentScore <= -6) {
      return const ChatMoodSnapshot(score: 1, label: 'Very Low');
    }
    if (sentimentScore < 0) {
      return const ChatMoodSnapshot(score: 2, label: 'Low');
    }
    if (sentimentScore < 3) {
      return const ChatMoodSnapshot(score: 3, label: 'Neutral');
    }
    if (sentimentScore < 6) {
      return const ChatMoodSnapshot(score: 4, label: 'Good');
    }
    return const ChatMoodSnapshot(score: 5, label: 'Great');
  }

  int _scoreSignals(String text, Map<String, int> signals) {
    var total = 0;
    for (final entry in signals.entries) {
      if (text.contains(entry.key)) {
        total += entry.value;
      }
    }
    return total;
  }

  bool _containsAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) return true;
    }
    return false;
  }
}
