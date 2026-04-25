import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_lecture_notes/services/reminder_api_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RevisionReminderSettings {
  final bool enabled;
  final int intervalDays;
  final int hour;
  final int minute;

  const RevisionReminderSettings({
    required this.enabled,
    required this.intervalDays,
    required this.hour,
    required this.minute,
  });

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

class RevisionReminderService {
  static const String _prefsEnabled = 'revision_enabled';
  static const String _prefsInterval = 'revision_interval_days';
  static const String _prefsHour = 'revision_hour';
  static const String _prefsMinute = 'revision_minute';

  static const String _channelId = 'revision_reminders';
  static const String _channelName = 'Revision Reminders';
  static const String _channelDescription = 'Notifications to review your notes';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final ReminderApiService _apiService = ReminderApiService();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    tz.initializeTimeZones();
    // Use a known IANA timezone for reliable scheduling.
    try {
      final tzName = 'Asia/Kolkata';
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[RevisionReminderService] Timezone set to $tzName');
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
      debugPrint('[RevisionReminderService] Timezone fallback to UTC: $e');
    }

    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final notificationsGranted =
          await androidImpl.requestNotificationsPermission();
      final exactAlarmsGranted =
          await androidImpl.requestExactAlarmsPermission();
      debugPrint(
        '[RevisionReminderService] Android - Notification: $notificationsGranted, '
        'Exact alarm: $exactAlarmsGranted',
      );
    }
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        sound: true,
        badge: true,
      );
      debugPrint('[RevisionReminderService] iOS permission: $granted');
    }
  }

  static Future<void> showTestNotification() async {
    await initialize();
    await requestPermissions();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Schedule for immediate delivery (1 second from now) to test timezone handling
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));
      debugPrint('[RevisionReminderService] Test notification scheduled for: $scheduledTime');
      
      await _plugin.zonedSchedule(
        id: 9999,
        title: 'Test Reminder',
        body: 'If you see this, notifications are working!',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'test_notification',
      );
      debugPrint('[RevisionReminderService] ✓ Test notification scheduled successfully');
    } catch (e) {
      debugPrint('[RevisionReminderService] ✗ Test notification error: $e');
      rethrow;
    }
  }

  /// Schedule an immediate notification for testing (appears in 1 minute)
  static Future<void> scheduleTestNotification() async {
    await initialize();
    await requestPermissions();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      debugPrint('[RevisionReminderService] Scheduling test notification for: $scheduledTime');
      debugPrint('[RevisionReminderService] Current time: ${tz.TZDateTime.now(tz.local)}');
      debugPrint('[RevisionReminderService] Time difference: ${scheduledTime.difference(tz.TZDateTime.now(tz.local)).inSeconds} seconds');
      
      await _plugin.zonedSchedule(
        id: 9998,
        title: 'Test Notification',
        body: 'This is a test notification (1 minute delay)',
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'test_1min',
      );
      debugPrint('[RevisionReminderService] ✓ Test notification scheduled for 1 minute from now');
    } catch (e) {
      debugPrint('[RevisionReminderService] ✗ Schedule test notification error: $e');
      rethrow;
    }
  }

  static Future<RevisionReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return RevisionReminderSettings(
      enabled: prefs.getBool(_prefsEnabled) ?? true,
      intervalDays: prefs.getInt(_prefsInterval) ?? 7,
      hour: prefs.getInt(_prefsHour) ?? 9,
      minute: prefs.getInt(_prefsMinute) ?? 0,
    );
  }

  static Future<void> saveSettings(RevisionReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, settings.enabled);
    await prefs.setInt(_prefsInterval, settings.intervalDays);
    await prefs.setInt(_prefsHour, settings.hour);
    await prefs.setInt(_prefsMinute, settings.minute);
  }

  static Future<void> scheduleReminders(
    RevisionReminderSettings settings,
  ) async {
    await initialize();
    await _plugin.cancelAll();

    if (!settings.enabled) {
      debugPrint('[RevisionReminderService] Reminders disabled, canceling all');
      return;
    }

    await requestPermissions();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    debugPrint('[RevisionReminderService] Current time: $now');
    debugPrint('[RevisionReminderService] Timezone: ${tz.local.name}');

    var first = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings.hour,
      settings.minute,
    );

    if (first.isBefore(now)) {
      final secondsLate = now.difference(first).inSeconds;
      if (secondsLate <= 60) {
        first = now.add(const Duration(minutes: 1));
        debugPrint('[RevisionReminderService] Time is within 1 min, scheduling for 1 min from now');
      } else {
        first = first.add(const Duration(days: 1));
        debugPrint('[RevisionReminderService] Time has passed, scheduling for tomorrow');
      }
    }

    if (first.difference(now).inSeconds < 60) {
      first = now.add(const Duration(minutes: 1));
      debugPrint('[RevisionReminderService] Adjusting to 1 minute from now for safety');
    }

    debugPrint('[RevisionReminderService] First notification: $first');
    debugPrint('[RevisionReminderService] Time until first: ${first.difference(now).inSeconds} seconds');
    debugPrint('[RevisionReminderService] Scheduling 30 reminders starting at: $first');
    debugPrint('[RevisionReminderService] Interval: ${settings.intervalDays} days');

    const occurrences = 30;
    var successCount = 0;
    var failureCount = 0;

    for (var i = 0; i < occurrences; i++) {
      final scheduled = first.add(Duration(days: settings.intervalDays * i));
      if (i < 5) {
        debugPrint('[RevisionReminderService] Reminder #${i + 1}: $scheduled');
      }

      try {
          await _plugin.zonedSchedule(
            id: 1000 + i,
            title: 'Time to revise',
            body: 'Open Smart Notes and review your saved notes.',
            scheduledDate: scheduled,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            payload: 'revision_reminder_${1000 + i}',
          );
          
          // Sync with backend (limit to first 10 for performance)
          if (i < 10) {
            _apiService.createReminder(
              title: 'Revision Reminder #${i + 1}',
              description: 'Automated study session reminder',
              reminderDateTime: scheduled,
              repeat: settings.intervalDays == 1 ? 'daily' : (settings.intervalDays == 7 ? 'weekly' : 'none'),
            ).catchError((e) => debugPrint('[RevisionReminderService] Backend sync failed: $e'));
          }

          successCount++;
      } catch (e) {
        debugPrint('[RevisionReminderService] ✗ Failed to schedule reminder #${i + 1}: $e');
        failureCount++;
      }
    }

    debugPrint('[RevisionReminderService] ✓ Scheduled $successCount/$occurrences reminders successfully');
    if (failureCount > 0) {
      debugPrint('[RevisionReminderService] ⚠ Failed to schedule $failureCount reminders');
    }
  }

  /// Debug method: Check pending notifications with the OS
  /// Returns the count of pending notification requests
  static Future<int> debugPendingNotifications() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      debugPrint('[RevisionReminderService] Pending notifications: ${pending.length}');
      for (final n in pending) {
        debugPrint('[RevisionReminderService]   ID: ${n.id}, Title: ${n.title}');
      }
      return pending.length;
    } catch (e) {
      debugPrint('[RevisionReminderService] ✗ Error fetching pending notifications: $e');
      return -1;
    }
  }
}
