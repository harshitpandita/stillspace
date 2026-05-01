// StreakProvider - manages streak data, freeze system, daily checks
import 'package:flutter/foundation.dart';

class StreakProvider extends ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastCompletedDate;
  int _freezesUsedThisWeek = 0;
  DateTime? _lastFreezeDate;
  int _goalDays = 21;
  DateTime? _goalStartDate;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastCompletedDate => _lastCompletedDate;
  int get freezesUsedThisWeek => _freezesUsedThisWeek;
  int get freezesRemaining => 1 - _freezesUsedThisWeek;
  int get goalDays => _goalDays;
  DateTime? get goalStartDate => _goalStartDate;

  int get daysLeftToGoal {
    if (_goalStartDate == null) return _goalDays;
    return _goalDays - _currentStreak;
  }

  bool get missedYesterday {
    if (_lastCompletedDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return !_isSameDay(_lastCompletedDate!, yesterday);
  }

  Future<void> init() async {
    notifyListeners();
  }

  Future<void> checkAndUpdateStreak() async {
    notifyListeners();
  }

  Future<void> incrementStreak() async {
    final today = DateTime.now();
    if (_lastCompletedDate != null && _isSameDay(_lastCompletedDate!, today)) {
      return;
    }
    _currentStreak++;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
    _lastCompletedDate = today;
    notifyListeners();
  }

  Future<void> applyFreeze() async {
    if (_freezesUsedThisWeek >= 1) return;
    _freezesUsedThisWeek++;
    _lastFreezeDate = DateTime.now();
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
