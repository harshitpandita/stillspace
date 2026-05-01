// UserProvider - manages user profile, onboarding state
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class UserProvider extends ChangeNotifier {
  bool _isOnboardingComplete = false;
  String? _userName;
  int _goalDays = 21;
  String _notificationTime = '09:00';

  bool get isOnboardingComplete => _isOnboardingComplete;
  String? get userName => _userName;
  int get goalDays => _goalDays;
  String get notificationTime => _notificationTime;

  Future<void> init() async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    _isOnboardingComplete = box.get('isOnboardingComplete', defaultValue: false);
    _userName = box.get('userName');
    _goalDays = box.get('goalDays', defaultValue: 21);
    _notificationTime = box.get('notificationTime', defaultValue: '09:00');
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

    _isOnboardingComplete = true;
    _userName = name;
    _goalDays = goalDays;
    _notificationTime = notificationTime;
    notifyListeners();
  }
}
