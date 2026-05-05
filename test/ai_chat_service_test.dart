// AI chat service tests - verifies parsing, auth headers, and fallback behavior.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stillspace/services/ai_chat_service.dart';

void main() {
  group('AiChatService', () {
    test('returns validation message for empty input', () async {
      final service = AiChatService(
        client: MockClient((_) async => http.Response('unexpected', 500)),
      );

      final response = await service.sendMessage('   ');

      expect(response, equals('Please type something for me to respond to.'));
    });

    test('sends token header and parses chat completion response', () async {
      late http.Request capturedRequest;
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': ' Take one slow breath. '},
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.sendMessage('I feel tense');

      expect(response, equals('Take one slow breath.'));
      expect(capturedRequest.headers['Authorization'], equals('Bearer test-token'));
    });

    test('includes same-chat history in the request body', () async {
      late http.Request capturedRequest;
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'I remember what you said.'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await service.sendMessage(
        'What about that last thing?',
        history: const [
          AiChatContextMessage(role: 'user', content: 'I had a rough day.'),
          AiChatContextMessage(
            role: 'assistant',
            content: 'What part of it felt heaviest?',
          ),
        ],
      );

      final body =
          jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      final messages = body['messages'] as List<dynamic>;

      expect(messages[1]['role'], equals('user'));
      expect(messages[1]['content'], equals('I had a rough day.'));
      expect(messages[2]['role'], equals('assistant'));
      expect(messages[2]['content'], contains('heaviest'));
      expect(messages.last['content'], equals('What about that last thing?'));
    });

    test('falls through unavailable model and uses next response', () async {
      var attempts = 0;
      final service = AiChatService(
        modelUrls: const ['https://example.com/a', 'https://example.com/b'],
        client: MockClient((_) async {
          attempts++;
          if (attempts == 1) return http.Response('', 404);
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'I am here with you.'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.sendMessage('hello');

      expect(response, equals('I am here with you.'));
      expect(attempts, equals(2));
    });

    test('strips leaked think tags from model output', () async {
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '<think>I should reason here.</think>Try one gentle breath and notice your shoulders.'
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.sendMessage('I feel stressed');

      expect(
        response,
        equals('Try one gentle breath and notice your shoulders.'),
      );
    });

    test('parses list-based content blocks', () async {
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': [
                      {'type': 'text', 'text': 'You made it through today.'},
                      {'type': 'text', 'text': 'What feels heaviest right now?'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      final response = await service.sendMessage('I am overwhelmed');

      expect(
        response,
        equals('You made it through today.\nWhat feels heaviest right now?'),
      );
    });

    test('infers mood from structured json response', () async {
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"score": 2}'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final mood = await service.inferMood([
        'I have been really overwhelmed lately.',
      ]);

      expect(mood, isNotNull);
      expect(mood!.score, equals(2));
      expect(mood.label, equals('Low'));
    });

    test('returns null mood when model says signal is insufficient', () async {
      final service = AiChatService(
        token: 'test-token',
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"score": null}'},
                },
              ],
            }),
            200,
          );
        }),
      );

      final mood = await service.inferMood([
        'hey',
      ]);

      expect(mood, isNull);
    });
  });
}
