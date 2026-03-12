import 'dart:async';
import 'dart:io';

import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/alarm.dart' as app_alarm;
import '../models/notification_log.dart';
import '../services/database_service.dart';
import '../services/widget_service.dart';

class AlarmProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  List<app_alarm.Alarm> _alarms = [];
  bool _isLoading = true;

  List<app_alarm.Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;

  /// Converts a UUID string to a stable, positive 32-bit int for use as the
  /// system alarm ID. Uses the first 8 hex digits of the UUID to produce a
  /// deterministic value that fits within Android's int32 ID range, avoiding
  /// the instability and potential 64-bit overflow of String.hashCode.
  static int _alarmSystemId(String uuid) {
    final hex = uuid.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16) & 0x7FFFFFFF;
  }

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
        final hasOverlap = newAlarm.repeatDays.any(
          (day) => existing.repeatDays.contains(day),
        );
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
  Future<void> snoozeAlarm(
    int alarmId,
    Duration duration,
    String? title,
    String? body,
  ) async {
    // Stop the ringing alarm
    await stopRingingAlarm(alarmId);

    // Schedule a new one-time alarm
    final now = DateTime.now();
    final snoozeTime = now.add(duration);

    final source = _alarms.firstWhereOrNull(
      (a) => _alarmSystemId(a.id) == alarmId,
    );
    if (source == null) {
      return;
    }

    final snoozedAlarm = app_alarm.Alarm(
      id: _uuid.v4(),
      title: title != null && title.isNotEmpty
          ? '$title (Erte)'
          : 'Ertelenmiş Alarm',
      time: snoozeTime,
      isActive: true,
      repeatDays: [],
      soundPath: source.soundPath,
      soundName: source.soundName,
    );

    await addAlarm(snoozedAlarm);
  }

  /// Skip the next occurrence of a repeating alarm without disabling it entirely
  Future<void> skipNextAlarm(app_alarm.Alarm alarm) async {
    if (alarm.repeatDays.isEmpty) return; // Cannot skip non-repeating

    // Find next valid occurrence
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If today's time passed, start checking from tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    // Find next valid repeating day (max 7 iterations — one full week)
    var skipIter = 0;
    while (!alarm.repeatDays.contains(next.weekday) && skipIter < 7) {
      next = next.add(const Duration(days: 1));
      skipIter++;
    }

    // Add date only (normlized to midnight) to skippedDates to avoid time confusion
    final dateToSkip = DateTime(next.year, next.month, next.day);
    final updatedSkipped = List<DateTime>.from(alarm.skippedDates)
      ..add(dateToSkip);

    // Clean up old skipped dates (older than yesterday)
    updatedSkipped.removeWhere(
      (d) => d.isBefore(DateTime(now.year, now.month, now.day - 1)),
    );

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

    // Find the alarm in our list by matching the ID
    try {
      final alarm = _alarms.firstWhere(
        (a) => _alarmSystemId(a.id) == alarmSettings.id,
      );

      // Log notification
      try {
        final now = DateTime.now();
        await _db.insertNotificationLog(
          NotificationLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple ID
            title: 'Alarm',
            body: '${alarm.title.isNotEmpty ? alarm.title : 'Alarm'} çalıyor!',
            timestamp: now,
            isRead: false,
            type: 'alarm',
            payload: alarm.id,
          ),
        );
      } catch (e) {
      }

      // If it's a one-time alarm (no repeat days), deactivate it
      if (alarm.repeatDays.isEmpty) {
        final deactivated = alarm.copyWith(isActive: false);
        await _db.updateAlarm(deactivated);
        await loadAlarms(); // Refresh the list
      } else {
        // Repeating alarms stay active and will reschedule automatically
      }
    } catch (e) {
    }
  }

  Future<void> loadAlarms() async {
    _isLoading = true;
    notifyListeners();
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
      // 1. Load alarms from DB first to have a base
      await loadAlarms();

      final dbAlarms = _alarms;
      final systemAlarms = await alarm_pkg.Alarm.getAlarms();

      // Create a set of system alarm IDs for quick lookup
      final systemAlarmIds = systemAlarms.map((a) => a.id).toSet();

      // 2. Reschedule any DB alarms that match system alarms but might be missing in system (re-ensure)
      // OR remove alarms from DB that are definitely gone from system is risky if system alarm cleared on reboot?
      // Actually Android AlarmManager might persist across reboots but alarm_pkg handles it.
      // If alarm_pkg says it's gone, it's probably gone.

      // However, to be safe against data loss:
      // If DB has alarm but System doesn't:
      // - If it's active and future, reschedule it! (Don't delete)
      // - If it's past, then maybe delete or deactivate.

      final now = DateTime.now();

      for (var dbAlarm in dbAlarms) {
        final alarmId = _alarmSystemId(dbAlarm.id);

        if (!systemAlarmIds.contains(alarmId)) {
          // Alarm is in DB but not in System.
          if (dbAlarm.isActive) {
            // It should be running. Check if it's in the future or repeating.
            var shouldReschedule = false;
            if (dbAlarm.repeatDays.isNotEmpty) {
              shouldReschedule = true;
            } else if (dbAlarm.time.isAfter(now)) {
              shouldReschedule = true;
            }

            if (shouldReschedule) {
              await _scheduleAlarm(dbAlarm);
            } else {
              // It's old and one-time, simple deactivate
              final deactivated = dbAlarm.copyWith(isActive: false);
              await _db.updateAlarm(deactivated);
            }
          }
        }
      }

      // Reload alarms after cleanup/reschedule
      await loadAlarms();
    } catch (e) {
    }
  }

  Future<void> addAlarm(app_alarm.Alarm alarm) async {
    try {
      await _db.insertAlarm(alarm);
      await _scheduleAlarm(alarm);
      await loadAlarms();
    } catch (e) {
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

      // Cap iterations at 14 days (2 weeks) to prevent infinite loop on bad state
      var mainIter = 0;
      while ((scheduledTime.isBefore(now) ||
              !alarm.repeatDays.contains(scheduledTime.weekday)) &&
          mainIter < 14) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        mainIter++;
      }

      // Check if this date is skipped
      final scheduledDateOnly = DateTime(
        scheduledTime.year,
        scheduledTime.month,
        scheduledTime.day,
      );
      if (alarm.skippedDates.any(
        (d) =>
            d.year == scheduledDateOnly.year &&
            d.month == scheduledDateOnly.month &&
            d.day == scheduledDateOnly.day,
      )) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        var skipFallbackIter = 0;
        while (!alarm.repeatDays.contains(scheduledTime.weekday) &&
            skipFallbackIter < 7) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
          skipFallbackIter++;
        }
      }
    } else {
      // One-time alarm
      scheduledTime = alarm.time;
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    }

    // Final safety check: if time passed during async processing, push 1 minute ahead
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = DateTime.now().add(const Duration(minutes: 1));
    }

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: _alarmSystemId(alarm.id),
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


    try {
      await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);
    } catch (e) {
      throw Exception('Failed to schedule alarm: $e');
    }
  }

  /// Cancel an alarm
  Future<void> _cancelAlarm(app_alarm.Alarm alarm) async {
    final alarmId = _alarmSystemId(alarm.id);
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

      final alarmIndex = _alarms.indexWhere(
        (a) => _alarmSystemId(a.id) == alarmId,
      );
      if (alarmIndex != -1) {
        final alarm = _alarms[alarmIndex];
        if (alarm.repeatDays.isEmpty && alarm.isActive) {
          final deactivated = alarm.copyWith(isActive: false);
          await _db.updateAlarm(deactivated);
          await loadAlarms();
        }
      }
    } catch (e) {
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
