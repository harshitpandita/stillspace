// SessionProvider - manages session state, timer logic, completion
import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  bool _isSessionActive = false;
  int _selectedDuration = 10;
  int _elapsedSeconds = 0;
  bool _isComplete = false;

  bool get isSessionActive => _isSessionActive;
  int get selectedDuration => _selectedDuration;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isComplete => _isComplete;

  Future<void> init() async {
    notifyListeners();
  }

  void setDuration(int minutes) {
    _selectedDuration = minutes;
    notifyListeners();
  }

  void startSession() {
    _isSessionActive = true;
    _elapsedSeconds = 0;
    _isComplete = false;
    notifyListeners();
  }

  void endSession() {
    _isSessionActive = false;
    _isComplete = true;
    notifyListeners();
  }

  void resetSession() {
    _isSessionActive = false;
    _elapsedSeconds = 0;
    _isComplete = false;
    notifyListeners();
  }
}
