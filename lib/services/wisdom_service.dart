// WisdomService - daily wisdom quote with ZenQuotes API + hardcoded fallback.
// Logic: fetch fresh quotes from ZenQuotes once per day, cache to Hive.
// Pool = cached API quotes + hardcoded list. Pick one quote per day from the
// combined pool and cache the selection so it stays consistent through the day.
// Offline-safe: API failure silently falls back to the hardcoded list.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class WisdomService {
  static final WisdomService _instance = WisdomService._internal();
  factory WisdomService() => _instance;
  WisdomService._internal();

  static const String _apiUrl = 'https://zenquotes.io/api/quotes';
  static const String _kApiCacheDate = 'apiQuotesCacheDate';
  static const String _kApiCache = 'apiQuotesCache';
  static const String _kTodayQuoteDate = 'todayQuoteDate';
  static const String _kTodayQuote = 'todayQuote';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Returns today's quote. If today's selection is already cached, reuses it.
  // Otherwise picks a fresh one from the combined pool.
  Future<String> getTodaysQuote() async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    final today = _todayKey();

    // Reuse already-selected quote for today
    final selectedDate = box.get(_kTodayQuoteDate) as String?;
    final selected = box.get(_kTodayQuote) as String?;
    if (selectedDate == today && selected != null && selected.isNotEmpty) {
      // Still try to refresh API cache in the background for tomorrow
      unawaited(_maybeRefreshApiCache());
      return selected;
    }

    // Need a new selection. Refresh API cache if not done today.
    await _maybeRefreshApiCache();

    final pool = _buildPool(box);
    final picked = pool[Random().nextInt(pool.length)];

    await box.put(_kTodayQuoteDate, today);
    await box.put(_kTodayQuote, picked);

    return picked;
  }

  Future<void> _maybeRefreshApiCache() async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    final cacheDate = box.get(_kApiCacheDate) as String?;
    if (cacheDate == _todayKey()) return; // already fetched today

    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 6),
      );
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body is! List) return;

      final quotes = <String>[];
      for (final item in body) {
        if (item is Map && item['q'] is String) {
          final q = (item['q'] as String).trim();
          if (q.isNotEmpty) quotes.add(q);
        }
      }
      if (quotes.isEmpty) return;

      await box.put(_kApiCache, quotes);
      await box.put(_kApiCacheDate, _todayKey());
    } catch (e) {
      // Offline / API failure — silently use whatever cache + hardcoded we have
      debugPrint('WisdomService: API fetch failed - $e');
    }
  }

  List<String> _buildPool(Box box) {
    final cached = box.get(_kApiCache, defaultValue: <dynamic>[]) as List<dynamic>;
    final apiQuotes = cached.cast<String>();
    return [...AppConstants.hardcodedWisdom, ...apiQuotes];
  }
}
