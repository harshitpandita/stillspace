// Chat mood service tests - verifies conversation-based mood inference.
import 'package:flutter_test/flutter_test.dart';
import 'package:stillspace/services/chat_mood_service.dart';

void main() {
  group('ChatMoodService', () {
    final service = ChatMoodService();

    test('returns very low mood for strongly negative language', () {
      final result = service.analyzeUserMessages([
        'I feel hopeless and completely overwhelmed today.',
      ]);

      expect(result, isNotNull);
      expect(result!.score, equals(1));
      expect(result.label, equals('Very Low'));
    });

    test('returns low mood for lighter stressed language', () {
      final result = service.analyzeUserMessages([
        'I am stressed, tired, and a little frustrated.',
      ]);

      expect(result, isNotNull);
      expect(result!.score, equals(2));
      expect(result.label, equals('Low'));
    });

    test('returns neutral mood for okay language', () {
      final result = service.analyzeUserMessages([
        'I am okay, just not sure what I need right now.',
      ]);

      expect(result, isNotNull);
      expect(result!.score, equals(3));
      expect(result.label, equals('Neutral'));
    });

    test('returns good mood for hopeful language', () {
      final result = service.analyzeUserMessages([
        'I feel calmer, lighter, and honestly pretty good.',
      ]);

      expect(result, isNotNull);
      expect(result!.score, equals(4));
      expect(result.label, equals('Good'));
    });

    test('returns great mood for strongly positive language', () {
      final result = service.analyzeUserMessages([
        'I feel amazing, energized, and really happy today.',
      ]);

      expect(result, isNotNull);
      expect(result!.score, equals(5));
      expect(result.label, equals('Great'));
    });
  });
}
