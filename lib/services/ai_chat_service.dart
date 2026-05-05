// AI Chat Service - provides conversational support for journal reflection.
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  AiChatService({
    http.Client? client,
    String? token,
    List<String>? modelUrls,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _tokenOverride = token,
        _models = modelUrls ?? _defaultModels;

  static const String _hfTokenFromEnvironment = String.fromEnvironment(
    'HUGGING_FACE_TOKEN',
  );
  static const String _envAssetPath = 'assets/config/.env';
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const String _chatCompletionsUrl =
      'https://router.huggingface.co/v1/chat/completions';

  static const List<String> _defaultModels = [
    'Qwen/Qwen2.5-7B-Instruct-1M',
    'meta-llama/Llama-3.1-8B-Instruct',
  ];
  static const String _tryNextModelPrefix = '__try_next_model__:';

  final http.Client _client;
  final bool _ownsClient;
  final String? _tokenOverride;
  final List<String> _models;
  String? _cachedToken;

static const String _supportPrompt = '''
You are Stillspace, a calm mental-wellness reflection companion.
Respond with warmth, keep replies concise, ask one gentle follow-up question,
and avoid diagnosis or medical claims. If the user mentions immediate danger,
encourage contacting local emergency services or a trusted person right away.
Do not reveal internal reasoning. Reply with only the final user-facing message.

User message:
''';

  Future<String> sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return 'Please type something for me to respond to.';
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await _resolveToken();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (token.isEmpty) {
      return 'AI chat is missing its Hugging Face token. Add HUGGING_FACE_TOKEN to assets/config/.env and restart the app.';
    }

    String? lastModelError;
    for (final model in _models) {
      final result = await _tryModel(model, headers, trimmedMessage);
      if (result != null) {
        if (result.startsWith(_tryNextModelPrefix)) {
          lastModelError = result.substring(_tryNextModelPrefix.length);
          continue;
        }
        return result;
      }
    }

    return lastModelError ??
        'Sorry, I\'m having trouble connecting right now. Please check your internet connection and try again.';
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<String> _resolveToken() async {
    final override = _tokenOverride;
    if (override != null) return override.trim();
    if (_hfTokenFromEnvironment.isNotEmpty) return _hfTokenFromEnvironment.trim();

    final cached = _cachedToken;
    if (cached != null) return cached;

    try {
      final envText = await rootBundle.loadString(_envAssetPath);
      final token = _readEnvValue(envText, 'HUGGING_FACE_TOKEN');
      _cachedToken = token;
      return token;
    } catch (e) {
      _cachedToken = '';
      return '';
    }
  }

  String _readEnvValue(String envText, String key) {
    for (final rawLine in const LineSplitter().convert(envText)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || !line.contains('=')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      final envKey = line.substring(0, separatorIndex).trim();
      if (envKey != key) continue;

      final value = line.substring(separatorIndex + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        return value.substring(1, value.length - 1).trim();
      }
      return value;
    }
    return '';
  }

  Future<String?> _tryModel(
    String model,
    Map<String, String> headers,
    String message,
  ) async {
    try {
      final body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': _supportPrompt.trim()},
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 160,
        'temperature': 0.7,
        'top_p': 0.9,
      });

      final response = await _client.post(
        Uri.parse(_chatCompletionsUrl),
        headers: headers,
        body: body,
      ).timeout(_requestTimeout);

      final responseBody = response.body.trim();
      if (response.statusCode == 200) {
        return _parseChatCompletion(responseBody) ??
            'I\'m here to listen. How are you feeling today?';
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return 'Authentication failed. Please confirm your Hugging Face token has inference permission.';
      }
      if (response.statusCode == 404) {
        // Try the next model if this one is unavailable
        return null;
      }
      if (response.statusCode == 400) {
        return '$_tryNextModelPrefix${_readApiError(responseBody, fallback: 'Hugging Face rejected the chat request. Check the model and token permissions.')}';
      }
      if (response.statusCode == 429) {
        return 'Rate limit reached. Please try again in a little while.';
      }
      if (response.statusCode == 503) {
        return null;
      }
      if (response.statusCode >= 500) {
        return 'The AI service is temporarily unavailable. Please try again later.';
      }

      return 'Connection error (${response.statusCode}). Please try again in a moment.';
    } catch (e) {
      return null;
    }
  }

  String _readApiError(String responseBody, {required String fallback}) {
    if (responseBody.isEmpty) return fallback;

    try {
      final data = jsonDecode(responseBody);
      if (data is Map) {
        final error = data['error'];
        if (error is String && error.trim().isNotEmpty) return error.trim();
        if (error is Map && error['message'] is String) {
          return (error['message'] as String).trim();
        }
        if (data['message'] is String) return (data['message'] as String).trim();
      }
    } catch (e) {
      return responseBody.length > 220
          ? '${responseBody.substring(0, 220)}...'
          : responseBody;
    }

    return fallback;
  }

  String? _parseChatCompletion(String responseBody) {
    if (responseBody.isEmpty) return null;

    final data = jsonDecode(responseBody);
    String? content;
    if (data is Map &&
        data['choices'] is List &&
        (data['choices'] as List).isNotEmpty) {
      final firstChoice = (data['choices'] as List).first;
      if (firstChoice is Map &&
          firstChoice['message'] is Map) {
        final message = firstChoice['message'] as Map;
        content = _extractMessageContent(message['content']);
      }
    }

    final text = content?.trim();
    if (text == null || text.isEmpty) return null;
    return _stripReasoningText(text);
  }

  String? _extractMessageContent(Object? rawContent) {
    if (rawContent is String) {
      return rawContent;
    }

    if (rawContent is List) {
      final buffer = StringBuffer();
      for (final item in rawContent) {
        if (item is Map) {
          final text = item['text'];
          if (text is String && text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            buffer.write(text.trim());
          }
        }
      }

      final combined = buffer.toString().trim();
      return combined.isEmpty ? null : combined;
    }

    return null;
  }

  String _stripReasoningText(String text) {
    var cleaned = text.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false),
      '',
    );

    final danglingThinkIndex = cleaned.toLowerCase().lastIndexOf('</think>');
    if (danglingThinkIndex != -1) {
      cleaned = cleaned.substring(danglingThinkIndex + '</think>'.length);
    }
    final danglingThinkingIndex = cleaned.toLowerCase().lastIndexOf('</thinking>');
    if (danglingThinkingIndex != -1) {
      cleaned = cleaned.substring(
        danglingThinkingIndex + '</thinking>'.length,
      );
    }

    cleaned = cleaned.trim();
    return cleaned.isEmpty
        ? 'I hear you. Tell me a little more about what is on your mind.'
        : cleaned;
  }
}
