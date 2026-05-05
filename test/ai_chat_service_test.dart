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
  });
}
