// MoodProvider - manages mood logs, check-in logic, 2hr rule, Hive persistence
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class MoodProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _moodLogs = [];
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

  List<Map<String, dynamic>> get last7DaysMoods {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    return _moodLogs.where((log) {
      final timestamp = log['timestamp'] as DateTime;
      return timestamp.isAfter(sevenDaysAgo);
    }).toList()
      ..sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
  }

  Map<String, double> get dailyAverageMoods {
    final now = DateTime.now();
    final result = <String, double>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      final dayLogs = _moodLogs.where((log) {
        final timestamp = log['timestamp'] as DateTime;
        return _dateKey(timestamp) == dateKey;
      }).toList();

      if (dayLogs.isNotEmpty) {
        final sum = dayLogs.fold<int>(0, (sum, log) => sum + (log['score'] as int));
        result[dateKey] = sum / dayLogs.length;
      }
    }

    return result;
  }

  Future<void> init() async {
    await _loadFromHive();
    _updateTodaysMood();
    notifyListeners();
  }

  Future<void> _loadFromHive() async {
    final box = Hive.box(AppConstants.hiveBoxMoodLogs);
    final data = box.get('logs', defaultValue: <dynamic>[]) as List<dynamic>;

    _moodLogs = data.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['timestamp'] = DateTime.parse(map['timestamp'] as String);
      return map;
    }).toList();

    if (_moodLogs.isNotEmpty) {
      _moodLogs.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      _lastLogTime = _moodLogs.first['timestamp'] as DateTime;
    }
  }

  Future<void> _saveToHive() async {
    final box = Hive.box(AppConstants.hiveBoxMoodLogs);
    final data = _moodLogs.map((log) {
      return {
        'score': log['score'],
        'timestamp': (log['timestamp'] as DateTime).toIso8601String(),
        'note': log['note'],
      };
    }).toList();
    await box.put('logs', data);
  }

  void _updateTodaysMood() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);

    final todayLogs = _moodLogs.where((log) {
      final timestamp = log['timestamp'] as DateTime;
      return _dateKey(timestamp) == todayKey;
    }).toList();

    if (todayLogs.isNotEmpty) {
      todayLogs.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      _todaysMood = todayLogs.first['score'] as int;
    }
  }

  Future<void> logMood(int score, {String? note}) async {
    final now = DateTime.now();
    _moodLogs.insert(0, {
      'score': score,
      'timestamp': now,
      'note': note,
    });
    _lastLogTime = now;
    _todaysMood = score;

    await _saveToHive();
    notifyListeners();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
