// BackgroundSyncService - runs a "did we miss a sync today?" check on every app
// open. We don't use a true background scheduler (WorkManager) because Android
// OEM battery optimization makes those tasks unreliable for exact-time delivery.
// Instead: every time the user opens the app, if today's sync hasn't happened
// and they're online, we sync. This catches the "first launch after midnight"
// case which is what the requirement actually needs.
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import 'firebase_service.dart';

const String _lastSyncDateKey = 'lastAutoSyncDate'; // ISO date string yyyy-MM-dd

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  // Called on app open. If we haven't synced today (calendar-day basis),
  // sync now. This is our reliable daily-sync mechanism.
  Future<void> syncIfNeeded() async {
    if (!FirebaseService().isSignedIn) return;
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    final lastSyncDate = box.get(_lastSyncDateKey) as String?;
    if (lastSyncDate == _todayKey()) return;

    try {
      await FirebaseService().syncAllDataToCloud();
      await box.put(_lastSyncDateKey, _todayKey());
    } catch (e) {
      debugPrint('BackgroundSync: app-open sync failed - $e');
    }
  }

  DateTime? get lastAutoSyncDate {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    final str = box.get(_lastSyncDateKey) as String?;
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
