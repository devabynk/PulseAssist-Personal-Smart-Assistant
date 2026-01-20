import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    // Initialize timezone database
    tzdata.initializeTimeZones();
    
    // Set local timezone (Turkey is Europe/Istanbul)
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Create notification channels for Android
    final androidPlugin = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Alarm channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'smart_assistant_alarms',
          'Alarmlar',
          description: 'Alarm bildirimleri',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      
      // Reminder channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'smart_assistant_reminders',
          'Hatırlatıcılar',
          description: 'Hatırlatıcı bildirimleri',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
    
    debugPrint('NotificationService initialized successfully');
  }

  /// Request notification permission for Android 13+
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('Notification permission status: $status');
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS permission is handled during initialization
      return true;
    }
    return true;
  }

  /// Request exact alarm permission for Android 12+ (required for zonedSchedule)
  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      debugPrint('Exact alarm permission status: $status');
      
      if (status.isDenied || status.isPermanentlyDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        debugPrint('Exact alarm permission request result: $result');
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS doesn't need this permission
  }

  /// Check if all required permissions are granted
  Future<bool> checkAllPermissions() async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      
      debugPrint('Notification: $notificationStatus, Exact Alarm: $exactAlarmStatus');
      
      return notificationStatus.isGranted && exactAlarmStatus.isGranted;
    }
    return true;
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    bool notificationGranted = await requestNotificationPermission();
    bool exactAlarmGranted = await requestExactAlarmPermission();
    
    return notificationGranted && exactAlarmGranted;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to alarm/reminder screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_assistant_channel',
      'Smart Assistant',
      channelDescription: 'Smart Assistant Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifications.show(id, title, body, details);
  }

  /// Schedule an alarm notification (Note: Alarms now use the alarm package)
  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Ensure scheduled date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Alarm date is in the past, skipping: $scheduledDate');
      return;
    }
    
    const androidDetails = AndroidNotificationDetails(
      'smart_assistant_alarms',
      'Alarmlar',
      channelDescription: 'Alarm bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint('Scheduling alarm for: $tzScheduledDate (ID: $id)');

    await notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'alarm_$id',
    );
  }

  /// Schedule a reminder notification
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Ensure scheduled date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Reminder date is in the past, skipping: $scheduledDate');
      return false;
    }

    // Check exact alarm permission on Android
    if (Platform.isAndroid) {
      final hasPermission = await Permission.scheduleExactAlarm.status;
      if (!hasPermission.isGranted) {
        debugPrint('Exact alarm permission not granted, requesting...');
        final granted = await requestExactAlarmPermission();
        if (!granted) {
          debugPrint('Cannot schedule reminder: exact alarm permission denied');
          return false;
        }
      }
    }
    
    const androidDetails = AndroidNotificationDetails(
      'smart_assistant_reminders',
      'Hatırlatıcılar',
      channelDescription: 'Hatırlatıcı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    debugPrint('Scheduling reminder for: $tzScheduledDate (ID: $id)');

    try {
      await notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder_$id',
      );
      debugPrint('Reminder scheduled successfully');
      return true;
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
      return false;
    }
  }

  Future<void> cancelNotification(int id) async {
    await notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await notifications.cancelAll();
  }
  
  /// Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await notifications.pendingNotificationRequests();
  }
}
