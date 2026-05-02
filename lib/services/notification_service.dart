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

  static const int _mainReminderId = 1;
  static const int _followUp1Id = 2;
  static const int _followUp2Id = 3;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
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

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - app will open naturally
  }

  Future<void> scheduleDailyReminder({
    required String time,
    required int currentStreak,
    required int daysLeftToGoal,
    required bool missedYesterday,
  }) async {
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
  }

  Future<void> cancelFollowUpNotifications() async {
    await _notifications.cancel(_followUp1Id);
    await _notifications.cancel(_followUp2Id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
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
}
