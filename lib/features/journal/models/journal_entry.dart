// JournalEntry model - stores prompt, content, mood score, timestamp, optional local image paths
class JournalEntry {
  final String id;
  final String prompt;
  final String content;
  final int? moodScore;
  final DateTime timestamp;
  final List<String> imagePaths;

  JournalEntry({
    required this.id,
    required this.prompt,
    required this.content,
    this.moodScore,
    required this.timestamp,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'content': content,
      'moodScore': moodScore,
      'timestamp': timestamp.toIso8601String(),
      'imagePaths': imagePaths,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final paths = map['imagePaths'];
    return JournalEntry(
      id: map['id'] as String,
      prompt: map['prompt'] as String,
      content: map['content'] as String,
      moodScore: map['moodScore'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePaths: paths is List ? List<String>.from(paths) : const [],
    );
  }
}
