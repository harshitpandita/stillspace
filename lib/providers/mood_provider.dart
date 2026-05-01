// MoodProvider - manages mood logs, check-in logic, 2hr rule
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class MoodProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _moodLogs = [];
  DateTime? _lastLogTime;
  int? _todaysMood;

  List<Map<String, dynamic>> get moodLogs => List.unmodifiable(_moodLogs);
  DateTime? get lastLogTime => _lastLogTime;
  int? get todaysMood => _todaysMood;

  bool get shouldShowMoodCheckIn {
    if (_lastLogTime == null) return true;
    final now = DateTime.now();
    final hoursSinceLastLog = now.difference(_lastLogTime!).inHours;
    return hoursSinceLastLog >= AppConstants.moodCheckInCooldownHours;
  }

  Future<void> init() async {
    notifyListeners();
  }

  Future<void> logMood(int score, {String? note}) async {
    final now = DateTime.now();
    _moodLogs.add({
      'score': score,
      'timestamp': now,
      'note': note,
    });
    _lastLogTime = now;
    _todaysMood = score;
    notifyListeners();
  }
}
