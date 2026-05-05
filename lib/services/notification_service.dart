// Notification service - handles local notifications and daily reminders
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _quietModeActive = false;

  static const int _mainReminderId = 1;
  static const int _followUp1Id = 2;
  static const int _followUp2Id = 3;
  static const int _quietModeNotificationId = 10;
  static const int _testNotificationId = 99;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _configureLocalTimeZone() {
    final now = DateTime.now();
    final offsetInHours = now.timeZoneOffset.inHours;
    final offsetMinutes = now.timeZoneOffset.inMinutes % 60;

    String tzName;
    if (offsetInHours >= 5 && offsetInHours <= 6 && offsetMinutes == 30) {
      tzName = 'Asia/Kolkata';
    } else if (offsetInHours == 0) {
      tzName = 'UTC';
    } else if (offsetInHours == -5) {
      tzName = 'America/New_York';
    } else if (offsetInHours == -8) {
      tzName = 'America/Los_Angeles';
    } else if (offsetInHours == 1) {
      tzName = 'Europe/London';
    } else if (offsetInHours == 8) {
      tzName = 'Asia/Singapore';
    } else if (offsetInHours == 9) {
      tzName = 'Asia/Tokyo';
    } else {
      tzName = 'UTC';
    }

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      return notifGranted ?? false;
    }
    return false;
  }

  bool get quietModeActive => _quietModeActive;

  Future<void> enterQuietMode() async {
    _quietModeActive = true;
    await cancelAllNotifications();
    await _showQuietModeNotification();
  }

  Future<void> exitQuietMode({
    required bool notificationsEnabled,
    required String time,
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
  }) async {
    await cancelQuietModeNotification();
    _quietModeActive = false;

    if (notificationsEnabled) {
      await scheduleDailyReminder(
        time: time,
        currentStreak: currentStreak,
        daysLeftToGoal: daysLeftToGoal,
        missedYesterday: missedYesterday,
      );
    } else {
      await cancelAllNotifications();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - app will open naturally
  }

  Future<void> scheduleDailyReminder({
    required String time,
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
  }) async {
    if (_quietModeActive) {
      return;
    }

    try {
      await cancelAllNotifications();

      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final message = _buildNotificationMessage(
        currentStreak: currentStreak,
        daysLeftToGoal: daysLeftToGoal,
        missedYesterday: missedYesterday,
        isFollowUp: false,
      );

      await _scheduleNotification(
        id: _mainReminderId,
        title: 'Time for Stillspace',
        body: message,
        scheduledDate: scheduledDate,
      );

      final followUp1Date = scheduledDate.add(
        Duration(hours: AppConstants.notificationFollowUp1Hours),
      );
      await _scheduleNotification(
        id: _followUp1Id,
        title: "Don't forget your practice",
        body: _buildFollowUpMessage(currentStreak, 1),
        scheduledDate: followUp1Date,
      );

      final followUp2Date = scheduledDate.add(
        Duration(hours: AppConstants.notificationFollowUp2Hours),
      );
      await _scheduleNotification(
        id: _followUp2Id,
        title: 'Last reminder for today',
        body: _buildFollowUpMessage(currentStreak, 2),
        scheduledDate: followUp2Date,
      );
    } catch (e) {
      // Scheduling failed - likely permission or timezone issue
    }
  }

  String _buildNotificationMessage({
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
    required bool isFollowUp,
  }) {
    if (daysLeftToGoal <= 3 && daysLeftToGoal > 0) {
      return "You're so close! Only $daysLeftToGoal days left to reach your goal.";
    }

    if (missedYesterday) {
      return "Let's get back on track today. Your journey continues now.";
    }

    if (currentStreak >= 7) {
      return "Amazing $currentStreak-day streak! Keep the momentum going.";
    }

    if (currentStreak > 0) {
      return "Day ${currentStreak + 1} awaits. A few minutes of calm can change your day.";
    }

    return "Take a moment for yourself. Your mindfulness practice is waiting.";
  }

  String _buildFollowUpMessage(int currentStreak, int followUpNumber) {
    if (currentStreak > 0) {
      if (followUpNumber == 1) {
        return "Your $currentStreak-day streak is still safe. Take 5 minutes now.";
      } else {
        return "Last chance to keep your streak alive today!";
      }
    }

    if (followUpNumber == 1) {
      return "A quick session can make all the difference.";
    }
    return "End your day with peace of mind. It only takes 5 minutes.";
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'stillspace_reminders',
        'Daily Reminders',
        channelDescription: 'Reminders for your mindfulness practice',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Notification scheduling failed - likely permission issue
    }
  }

  Future<void> cancelFollowUpNotifications() async {
    try {
      await _notifications.cancel(_followUp1Id);
      await _notifications.cancel(_followUp2Id);
    } catch (e) {
      // Cancel failed silently
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      // Cancel failed silently
    }
  }

  Future<void> cancelQuietModeNotification() async {
    try {
      await _notifications.cancel(_quietModeNotificationId);
    } catch (e) {
      // Cancel failed silently
    }
  }

  Future<void> _showQuietModeNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'stillspace_quiet_mode',
        'Quiet Mode',
        channelDescription: 'Shows when Stillspace is silencing notifications during a session',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        onlyAlertOnce: true,
      );

      const details = NotificationDetails(android: androidDetails);
      await _notifications.show(
        _quietModeNotificationId,
        'Quiet mode active',
        'Stillspace is keeping reminders quiet while your session is in progress.',
        details,
      );
    } catch (e) {
      // Quiet mode notification failed silently
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stillspace_general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(0, title, body, details);
  }

  Future<void> scheduleTestNotification() async {
    try {
      // Use simple show() instead of zonedSchedule for test - more reliable
      const androidDetails = AndroidNotificationDetails(
        'stillspace_test',
        'Test Notifications',
        channelDescription: 'Test notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      // Schedule for 5 seconds from now using Future.delayed + show
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await _notifications.show(
            _testNotificationId,
            'Test Notification',
            'If you see this, notifications are working!',
            details,
          );
        } catch (e) {
          // Notification failed silently
        }
      });
    } catch (e) {
      // Scheduling failed silently
    }
  }
}
