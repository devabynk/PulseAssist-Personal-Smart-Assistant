import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import '../models/alarm.dart' as app_alarm;
import '../models/notification_log.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

import 'package:uuid/uuid.dart';

class AlarmProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();
  
  List<app_alarm.Alarm> _alarms = [];
  bool _isLoading = true;

  List<app_alarm.Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  /// Check if a duplicate alarm exists
  /// Returns the duplicate alarm if found, null otherwise
  app_alarm.Alarm? checkDuplicateAlarm(app_alarm.Alarm newAlarm) {
    for (final existing in _alarms) {
      // Skip if comparing with itself (during edit)
      if (existing.id == newAlarm.id) continue;
      
      // Check if times match (hour and minute)
      if (existing.time.hour != newAlarm.time.hour || 
          existing.time.minute != newAlarm.time.minute) {
        continue;
      }
      
      // For repeating alarms: check if repeat days overlap
      if (newAlarm.repeatDays.isNotEmpty && existing.repeatDays.isNotEmpty) {
        final hasOverlap = newAlarm.repeatDays.any((day) => existing.repeatDays.contains(day));
        if (hasOverlap) return existing;
      }
      
      // For one-time alarms: check if same date
      if (newAlarm.repeatDays.isEmpty && existing.repeatDays.isEmpty) {
        if (existing.time.year == newAlarm.time.year &&
            existing.time.month == newAlarm.time.month &&
            existing.time.day == newAlarm.time.day) {
          return existing;
        }
      }
    }
    return null;
  }

  /// Snooze an alarm for a specific duration
  Future<void> snoozeAlarm(int alarmId, Duration duration, String? title, String? body) async {
    // Stop the ringing alarm
    await stopRingingAlarm(alarmId);
    
    // Schedule a new one-time alarm
    final now = DateTime.now();
    final snoozeTime = now.add(duration);
    
    final snoozedAlarm = app_alarm.Alarm(
      id: _uuid.v4(),
      title: title != null && title.isNotEmpty ? '$title (Erte)' : 'Ertelenmiş Alarm',
      time: snoozeTime,
      isActive: true, // Auto active
      repeatDays: [], // One-time
      // soundPath: We could verify if original alarm had a sound, but for now use default or let UI decide
    );
    
    await addAlarm(snoozedAlarm);
    debugPrint('Alarm snoozed until $snoozeTime');
  }

  /// Skip the next occurrence of a repeating alarm without disabling it entirely
  Future<void> skipNextAlarm(app_alarm.Alarm alarm) async {
    if (alarm.repeatDays.isEmpty) return; // Cannot skip non-repeating
    
    // Find next valid occurrence
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);
    
    // If today's time passed, start checking from tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    
    // Find next valid repeating day
    while (!alarm.repeatDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }
    
    // Add date only (normlized to midnight) to skippedDates to avoid time confusion
    final dateToSkip = DateTime(next.year, next.month, next.day);
    final updatedSkipped = List<DateTime>.from(alarm.skippedDates)..add(dateToSkip);
    
    // Clean up old skipped dates (older than yesterday)
    updatedSkipped.removeWhere((d) => d.isBefore(DateTime(now.year, now.month, now.day - 1)));
    
    final updatedAlarm = alarm.copyWith(skippedDates: updatedSkipped);
    
    await updateAlarm(updatedAlarm);
  }

  StreamSubscription<alarm_pkg.AlarmSettings>? _subscription;

  AlarmProvider() {
    _init();
  }

  Future<void> _init() async {
    await syncAlarms(); // Sync first to clean up orphaned alarms
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Handle alarm ring event (called from main.dart)
  Future<void> handleAlarmRing(alarm_pkg.AlarmSettings alarmSettings) async {
    debugPrint('Alarm ringing (handled by provider): ${alarmSettings.id}');
    
    // Find the alarm in our list by matching the ID
    try {
      final alarm = _alarms.firstWhere(
        (a) => a.id.hashCode.abs() == alarmSettings.id,
      );
      
      // Log notification
      try {
        final now = DateTime.now();
        await _db.insertNotificationLog(NotificationLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
          title: 'Alarm',
          body: '${alarm.title.isNotEmpty ? alarm.title : 'Alarm'} çalıyor!',
          timestamp: now,
          isRead: false,
          type: 'alarm',
          payload: alarm.id,
        ));
      } catch (e) {
        debugPrint('Failed to log alarm notification: $e');
      }

      // If it's a one-time alarm (no repeat days), deactivate it
      if (alarm.repeatDays.isEmpty) {
        debugPrint('One-time alarm finished, deactivating: ${alarm.title}');
        final deactivated = alarm.copyWith(isActive: false);
        await _db.updateAlarm(deactivated);
        await loadAlarms(); // Refresh the list
      } else {
        debugPrint('Repeating alarm, keeping active: ${alarm.title}');
        // Repeating alarms stay active and will reschedule automatically
      }
    } catch (e) {
      debugPrint('Alarm not found locally or error processing ring: $e');
    }
  }

  Future<void> loadAlarms() async {
    _isLoading = true;
    final alarms = await _db.getAlarms();
    _alarms = alarms;
    _isLoading = false;
    notifyListeners();
    // Update all alarm widgets
    await WidgetService.updateAlarmsListWidget(alarms);
    await WidgetService.updateSingleAlarmWidget(alarms);
  }

  /// Sync database alarms with system alarms
  /// Removes alarms from database that don't exist in system
  Future<void> syncAlarms() async {
    try {
      final dbAlarms = await _db.getAlarms();
      final systemAlarms = await alarm_pkg.Alarm.getAlarms();
      
      // Create a set of system alarm IDs for quick lookup
      final systemAlarmIds = systemAlarms.map((a) => a.id).toSet();
      
      // Remove alarms from DB that don't exist in system
      for (var dbAlarm in dbAlarms) {
        final alarmId = dbAlarm.id.hashCode.abs();
        if (!systemAlarmIds.contains(alarmId)) {
          debugPrint('Removing orphaned alarm from DB: ${dbAlarm.title}');
          await _db.deleteAlarm(dbAlarm.id);
        }
      }
      
      // Reload alarms after cleanup
      await loadAlarms();
    } catch (e) {
      debugPrint('Error syncing alarms: $e');
    }
  }

  Future<void> addAlarm(app_alarm.Alarm alarm) async {
    try {
      await _db.insertAlarm(alarm);
      await _scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e) {
      debugPrint('Error adding alarm: $e');
      await _db.deleteAlarm(alarm.id);
      rethrow;
    }
  }

  Future<void> updateAlarm(app_alarm.Alarm alarm) async {
    try {
      await _db.updateAlarm(alarm);
      await _cancelAlarm(alarm);
      if (alarm.isActive) {
        await _scheduleAlarm(alarm);
      }
      await loadAlarms();
    } catch (e) {
      debugPrint('Error updating alarm: $e');
      rethrow;
    }
  }

  Future<void> deleteAlarm(app_alarm.Alarm alarm) async {
    await _db.deleteAlarm(alarm.id);
    await _cancelAlarm(alarm);
    await loadAlarms();
  }

  Future<void> toggleAlarm(app_alarm.Alarm alarm) async {
    final updated = alarm.copyWith(isActive: !alarm.isActive);
    await updateAlarm(updated);
  }

  /// Schedule an alarm using the alarm package
  Future<void> _scheduleAlarm(app_alarm.Alarm alarm) async {
    final now = DateTime.now();
    DateTime scheduledTime;

    if (alarm.repeatDays.isNotEmpty) {
      // Repeating alarm: Find next matching occurrence
      scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      );

      while (scheduledTime.isBefore(now) || !alarm.repeatDays.contains(scheduledTime.weekday)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      // Check if this date is skipped
      final scheduledDateOnly = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
      if (alarm.skippedDates.any((d) => d.year == scheduledDateOnly.year && d.month == scheduledDateOnly.month && d.day == scheduledDateOnly.day)) {
        debugPrint('Skipping alarm ${alarm.title} for $scheduledDateOnly');
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        while (!alarm.repeatDays.contains(scheduledTime.weekday)) {
           scheduledTime = scheduledTime.add(const Duration(days: 1));
        }
      }
    } else {
      // One-time alarm
      scheduledTime = alarm.time;
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    }

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: alarm.id.hashCode.abs(),
      dateTime: scheduledTime,
      assetAudioPath: alarm.soundPath ?? 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      volumeSettings: const alarm_pkg.VolumeSettings.fixed(
        volume: 0.8,
        volumeEnforced: true,
      ),
      notificationSettings: alarm_pkg.NotificationSettings(
        title: '⏰ Alarm',
        body: alarm.title,
        stopButton: 'Durdur',
      ),
    );

    debugPrint('Scheduling alarm: ${alarm.title} for $scheduledTime (ID: ${alarmSettings.id})');
    
    try {
      await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);
      debugPrint('Alarm scheduled successfully');
    } catch (e) {
      debugPrint('CRITICAL ERROR: Failed to schedule alarm: $e');
      throw Exception('Failed to schedule alarm: $e');
    }
  }

  /// Cancel an alarm
  Future<void> _cancelAlarm(app_alarm.Alarm alarm) async {
    final alarmId = alarm.id.hashCode.abs();
    debugPrint('Cancelling alarm ID: $alarmId');
    await alarm_pkg.Alarm.stop(alarmId);
  }

  /// Stop a ringing alarm
  Future<void> stopRingingAlarm(int alarmId) async {
    await alarm_pkg.Alarm.stop(alarmId);
    
    // Explicitly check and deactivate if it's a one-time alarm
    // This is a safety fallback in case the ring stream listener didn't catch it
    try {
      // Find the alarm in our list (handle if list is empty or not found)
      if (_alarms.isEmpty) {
        await loadAlarms();
      }
      
      final alarmIndex = _alarms.indexWhere((a) => a.id.hashCode.abs() == alarmId);
      if (alarmIndex != -1) {
        final alarm = _alarms[alarmIndex];
        if (alarm.repeatDays.isEmpty && alarm.isActive) {
          debugPrint('Stopping one-time alarm manually, deactivating: ${alarm.title}');
          final deactivated = alarm.copyWith(isActive: false);
          await _db.updateAlarm(deactivated);
          await loadAlarms();
        }
      }
    } catch (e) {
      debugPrint('Error deactivating alarm on stop: $e');
    }
  }

  /// Get all active alarms from the alarm package
  Future<List<alarm_pkg.AlarmSettings>> getActiveAlarms() async {
    return alarm_pkg.Alarm.getAlarms();
  }

  /// Check if there are any scheduled alarms
  Future<bool> hasScheduledAlarms() async {
    final alarms = await alarm_pkg.Alarm.getAlarms();
    return alarms.isNotEmpty;
  }
}
