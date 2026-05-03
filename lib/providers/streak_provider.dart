// StreakProvider - manages streak data, freeze system, daily checks, Hive persistence, Firebase sync
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../services/firebase_service.dart';

class StreakProvider extends ChangeNotifier {
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastCompletedDate;
  int _freezesUsedThisWeek = 0;
  DateTime? _lastFreezeDate;
  int _goalDays = 21;
  DateTime? _goalStartDate;
  int _totalMinutesMeditated = 0;
  int _totalSessions = 0;
  final Set<String> _completedDates = {};
  final Set<String> _freezeDates = {};

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastCompletedDate => _lastCompletedDate;
  int get freezesUsedThisWeek => _freezesUsedThisWeek;
  int get freezesRemaining => 1 - _freezesUsedThisWeek;
  int get goalDays => _goalDays;
  DateTime? get goalStartDate => _goalStartDate;
  Set<String> get completedDates => Set.unmodifiable(_completedDates);
  Set<String> get freezeDates => Set.unmodifiable(_freezeDates);
  int get totalMinutesMeditated => _totalMinutesMeditated;
  int get totalSessions => _totalSessions;

  String get formattedTotalTime {
    if (_totalMinutesMeditated < 60) {
      return '$_totalMinutesMeditated min';
    }
    final hours = _totalMinutesMeditated ~/ 60;
    final mins = _totalMinutesMeditated % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  int get daysLeftToGoal {
    if (_goalStartDate == null) return _goalDays;
    return (_goalDays - _currentStreak).clamp(0, _goalDays);
  }

  bool get missedYesterday {
    if (_lastCompletedDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return !_isSameDay(_lastCompletedDate!, yesterday);
  }

  Future<void> init() async {
    await _loadFromHive();
    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    final box = Hive.box(AppConstants.hiveBoxStreakData);
    _currentStreak = box.get('currentStreak', defaultValue: 0);
    _longestStreak = box.get('longestStreak', defaultValue: 0);
    _freezesUsedThisWeek = box.get('freezesUsedThisWeek', defaultValue: 0);
    _goalDays = box.get('goalDays', defaultValue: 21);
    _totalMinutesMeditated = box.get('totalMinutesMeditated', defaultValue: 0);
    _totalSessions = box.get('totalSessions', defaultValue: 0);

    final lastCompletedStr = box.get('lastCompletedDate') as String?;
    if (lastCompletedStr != null) {
      _lastCompletedDate = DateTime.tryParse(lastCompletedStr);
    }

    final goalStartStr = box.get('goalStartDate') as String?;
    if (goalStartStr != null) {
      _goalStartDate = DateTime.tryParse(goalStartStr);
    }

    final completedList = box.get('completedDates', defaultValue: <dynamic>[]) as List<dynamic>;
    _completedDates.addAll(completedList.cast<String>());

    final freezeList = box.get('freezeDates', defaultValue: <dynamic>[]) as List<dynamic>;
    _freezeDates.addAll(freezeList.cast<String>());
  }

  Future<void> _saveToHive() async {
    final box = Hive.box(AppConstants.hiveBoxStreakData);
    await box.put('currentStreak', _currentStreak);
    await box.put('longestStreak', _longestStreak);
    await box.put('freezesUsedThisWeek', _freezesUsedThisWeek);
    await box.put('goalDays', _goalDays);
    await box.put('totalMinutesMeditated', _totalMinutesMeditated);
    await box.put('totalSessions', _totalSessions);
    await box.put('lastCompletedDate', _lastCompletedDate?.toIso8601String());
    await box.put('goalStartDate', _goalStartDate?.toIso8601String());
    await box.put('completedDates', _completedDates.toList());
    await box.put('freezeDates', _freezeDates.toList());
  }

  Future<void> checkAndUpdateStreak() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    if (_lastFreezeDate != null && !_isSameWeek(_lastFreezeDate!, weekStart)) {
      _freezesUsedThisWeek = 0;
    }

    await _saveToHive();
    notifyListeners();
  }

  Future<void> incrementStreak({int sessionMinutes = 0}) async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    _totalMinutesMeditated += sessionMinutes;
    _totalSessions++;

    if (_completedDates.contains(todayKey)) {
      await _saveToHive();
      notifyListeners();
      return;
    }

    _completedDates.add(todayKey);
    _currentStreak++;

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    _lastCompletedDate = today;

    _goalStartDate ??= today;

    await _saveToHive();
    notifyListeners();
    FirebaseService().syncOnChange();
  }

  Future<void> applyFreeze() async {
    if (_freezesUsedThisWeek >= 1) return;

    final today = DateTime.now();
    _freezesUsedThisWeek++;
    _lastFreezeDate = today;
    _freezeDates.add(_dateKey(today));

    await _saveToHive();
    notifyListeners();
    FirebaseService().syncOnChange();
  }

  bool isDateCompleted(DateTime date) {
    return _completedDates.contains(_dateKey(date));
  }

  bool isDateFreeze(DateTime date) {
    return _freezeDates.contains(_dateKey(date));
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameWeek(DateTime date, DateTime weekStart) {
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
           date.isBefore(weekStart.add(const Duration(days: 7)));
  }
}
