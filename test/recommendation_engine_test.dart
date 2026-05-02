// Recommendation engine unit tests
import 'package:flutter_test/flutter_test.dart';
import 'package:stillspace/core/utils/recommendation_engine.dart';

void main() {
  group('RecommendationEngine', () {
    test('returns urgent recommendation when close to goal (3 days left)', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 18,
        daysLeftToGoal: 3,
        missedYesterday: false,
      );

      expect(recommendation.urgency, equals(Urgency.high));
      expect(recommendation.sessionType, equals(SessionType.focus));
      expect(recommendation.promptMessage, contains('close'));
    });

    test('returns urgent recommendation when 1 day left', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 20,
        daysLeftToGoal: 1,
        missedYesterday: false,
      );

      expect(recommendation.urgency, equals(Urgency.high));
      expect(recommendation.promptMessage, contains('One day left'));
    });

    test('prioritizes missed yesterday over low mood', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 2,
        currentStreak: 5,
        daysLeftToGoal: 10,
        missedYesterday: true,
      );

      expect(recommendation.urgency, equals(Urgency.high));
      expect(recommendation.sessionDuration, equals(5));
      expect(recommendation.promptMessage, contains('Welcome back'));
    });

    test('returns calming session for low mood', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 1,
        currentStreak: 5,
        daysLeftToGoal: 10,
        missedYesterday: false,
      );

      expect(recommendation.sessionType, equals(SessionType.calming));
      expect(recommendation.sessionDuration, equals(5));
      expect(recommendation.urgency, equals(Urgency.medium));
      expect(recommendation.journalPrompt, isNotNull);
    });

    test('returns longer session for high mood and strong streak', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 5,
        currentStreak: 10,
        daysLeftToGoal: 11,
        missedYesterday: false,
      );

      expect(recommendation.sessionType, equals(SessionType.focus));
      expect(recommendation.sessionDuration, equals(15));
      expect(recommendation.promptMessage, contains('great flow'));
    });

    test('returns default for mid-range mood and moderate streak', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 3,
        daysLeftToGoal: 18,
        missedYesterday: false,
      );

      expect(recommendation.sessionDuration, equals(10));
      expect(recommendation.urgency, equals(Urgency.low));
    });

    test('returns appropriate message for zero streak', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 0,
        daysLeftToGoal: 21,
        missedYesterday: false,
      );

      expect(recommendation.promptMessage, contains('Take a moment'));
    });

    test('returns appropriate message for building streak', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 2,
        daysLeftToGoal: 19,
        missedYesterday: false,
      );

      expect(recommendation.promptMessage, contains('Day 3'));
    });

    test('handles null mood score gracefully', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: null,
        currentStreak: 5,
        daysLeftToGoal: 16,
        missedYesterday: false,
      );

      expect(recommendation, isNotNull);
      expect(recommendation.sessionDuration, isPositive);
    });

    test('goal close priority is higher than missed yesterday', () {
      final recommendation = RecommendationEngine.getRecommendation(
        moodScore: 3,
        currentStreak: 19,
        daysLeftToGoal: 2,
        missedYesterday: true,
      );

      expect(recommendation.promptMessage, contains('days to go'));
    });

    test('getSessionTypeLabel returns correct labels', () {
      expect(
        RecommendationEngine.getSessionTypeLabel(SessionType.calming),
        equals('Calming'),
      );
      expect(
        RecommendationEngine.getSessionTypeLabel(SessionType.energizing),
        equals('Energizing'),
      );
      expect(
        RecommendationEngine.getSessionTypeLabel(SessionType.focus),
        equals('Focus'),
      );
      expect(
        RecommendationEngine.getSessionTypeLabel(SessionType.windDown),
        equals('Wind Down'),
      );
      expect(
        RecommendationEngine.getSessionTypeLabel(SessionType.standard),
        equals('Mindfulness'),
      );
    });
  });
}
