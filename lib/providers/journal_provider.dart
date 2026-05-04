// JournalProvider - manages journal entries, persists to Hive, syncs to Firebase
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../features/journal/models/journal_entry.dart';
import '../services/firebase_service.dart';
import '../services/journal_image_service.dart';

class JournalProvider extends ChangeNotifier {
  List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  List<JournalEntry> get recentEntries {
    final sorted = List<JournalEntry>.from(_entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  Future<void> init() async {
    await _loadFromHive();
    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    final box = Hive.box(AppConstants.hiveBoxJournalEntries);
    final data = box.get('entries', defaultValue: <dynamic>[]) as List<dynamic>;
    _entries = data
        .map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveToHive() async {
    final box = Hive.box(AppConstants.hiveBoxJournalEntries);
    await box.put('entries', _entries.map((e) => e.toMap()).toList());
  }

  Future<void> addEntry({
    required String prompt,
    required String content,
    int? moodScore,
    List<String> imagePaths = const [],
  }) async {
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      prompt: prompt,
      content: content,
      moodScore: moodScore,
      timestamp: DateTime.now(),
      imagePaths: imagePaths,
    );
    _entries.add(entry);
    await _saveToHive();
    notifyListeners();
    FirebaseService().syncOnChange();
  }

  Future<void> deleteEntry(String id) async {
    final entry = _entries.firstWhere(
      (e) => e.id == id,
      orElse: () => JournalEntry(id: '', prompt: '', content: '', timestamp: DateTime.now()),
    );
    // Clean up local image files before removing the entry
    for (final path in entry.imagePaths) {
      await JournalImageService().deleteImage(path);
    }
    _entries.removeWhere((e) => e.id == id);
    await _saveToHive();
    notifyListeners();
    FirebaseService().syncOnChange();
  }

  bool get hasEntryToday {
    final now = DateTime.now();
    return _entries.any((e) =>
        e.timestamp.year == now.year &&
        e.timestamp.month == now.month &&
        e.timestamp.day == now.day);
  }
}
