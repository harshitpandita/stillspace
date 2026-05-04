// LearnService - loads the static Learn Meditation JSON from assets and caches
// the parsed result in memory. Asset bundle is offline-by-design (no network).
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../features/learn/models/learn_content.dart';

class LearnService {
  static final LearnService _instance = LearnService._internal();
  factory LearnService() => _instance;
  LearnService._internal();

  static const String _assetPath = 'assets/data/meditation_learn.json';

  List<LearnCategory>? _cached;

  Future<List<LearnCategory>> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final categories = (json['categories'] as List)
        .map((e) => LearnCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _cached = categories;
    return categories;
  }
}
