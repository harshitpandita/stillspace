// UserProvider - manages user profile, onboarding state, and settings
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class UserProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  String? _userName;
  int _goalDays = 21;
  String _notificationTime = '09:00';
  bool _notificationsEnabled = true;

  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get userName => _userName;
  int get goalDays => _goalDays;
  String get notificationTime => _notificationTime;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    _isOnboardingComplete = box.get('isOnboardingComplete', defaultValue: false);
    _userName = box.get('userName');
    _goalDays = box.get('goalDays', defaultValue: 21);
    _notificationTime = box.get('notificationTime', defaultValue: '09:00');
    _notificationsEnabled = box.get('notificationsEnabled', defaultValue: true);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required int goalDays,
    required String notificationTime,
  }) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    await box.put('isOnboardingComplete', true);
    await box.put('userName', name);
    await box.put('goalDays', goalDays);
    await box.put('notificationTime', notificationTime);
    await box.put('notificationsEnabled', true);

    _isOnboardingComplete = true;
    _userName = name;
    _goalDays = goalDays;
    _notificationTime = notificationTime;
    _notificationsEnabled = true;
    notifyListeners();
  }

  Future<void> updateNotificationTime(String time) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    await box.put('notificationTime', time);
    _notificationTime = time;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    await box.put('notificationsEnabled', enabled);
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  Future<void> updateGoalDays(int days) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    await box.put('goalDays', days);
    _goalDays = days;
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    await box.put('userName', name);
    _userName = name;
    notifyListeners();
  }
}
