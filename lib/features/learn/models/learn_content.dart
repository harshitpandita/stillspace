// LearnContent models - parsed from assets/data/meditation_learn.json
class LearnCategory {
  final String id;
  final String title;
  final String description;
  final List<LearnArticle> items;

  const LearnCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });

  factory LearnCategory.fromJson(Map<String, dynamic> json) {
    return LearnCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      items: (json['items'] as List)
          .map((e) => LearnArticle.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class LearnArticle {
  final String id;
  final String title;
  final String summary;
  final int readingTimeMinutes;
  final List<LearnBlock> body;

  const LearnArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.readingTimeMinutes,
    required this.body,
  });

  factory LearnArticle.fromJson(Map<String, dynamic> json) {
    return LearnArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      readingTimeMinutes: json['readingTimeMinutes'] as int,
      body: (json['body'] as List)
          .map((e) => LearnBlock.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

enum LearnBlockType { paragraph, heading, bullet }

class LearnBlock {
  final LearnBlockType type;
  final String text;

  const LearnBlock({required this.type, required this.text});

  factory LearnBlock.fromJson(Map<String, dynamic> json) {
    final raw = json['type'] as String;
    final type = switch (raw) {
      'heading' => LearnBlockType.heading,
      'bullet' => LearnBlockType.bullet,
      _ => LearnBlockType.paragraph,
    };
    return LearnBlock(type: type, text: json['text'] as String);
  }
}
