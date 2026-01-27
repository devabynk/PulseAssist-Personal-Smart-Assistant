import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:ui';
import '../models/note.dart';
import '../models/alarm.dart';
import '../models/reminder.dart';

class WidgetService {
  static const String _groupId = 'group.com.abynk.smart_assistant';
  
  // Widget names for Android
  static const String _noteWidgetName = 'NoteWidgetProvider';
  static const String _notesListWidgetName = 'NotesListWidgetProvider';
  static const String _singleNoteWidgetName = 'SingleNoteWidgetProvider';
  static const String _alarmsListWidgetName = 'AlarmsListWidgetProvider';
  static const String _singleAlarmWidgetName = 'SingleAlarmWidgetProvider';
  static const String _remindersListWidgetName = 'RemindersListWidgetProvider';
  static const String _singleReminderWidgetName = 'SingleReminderWidgetProvider';
  static const String _weatherWidgetName = 'WeatherWidgetProvider';

  // iOS widget names
  static const String _iosNoteWidgetName = 'NoteWidget';
  static const String _iosNotesListWidgetName = 'NotesListWidget';
  static const String _iosSingleNoteWidgetName = 'SingleNoteWidget';
  static const String _iosAlarmsListWidgetName = 'AlarmsListWidget';
  static const String _iosSingleAlarmWidgetName = 'SingleAlarmWidget';
  static const String _iosRemindersListWidgetName = 'RemindersListWidget';
  static const String _iosSingleReminderWidgetName = 'SingleReminderWidget';
  static const String _iosWeatherWidgetName = 'WeatherWidget';

  /// Get current locale (simplified - returns 'tr' or 'en')
  static String _getCurrentLocale() {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode == 'tr' ? 'tr' : 'en';
  }

  /// Get localized strings for widgets
  static Map<String, String> _getLocalizedStrings() {
    final locale = _getCurrentLocale();
    
    if (locale == 'tr') {
      return {
        'notesListTitle': 'Notlarım',
        'noNotes': 'Henüz not yok',
        'tapToOpen': 'Açmak için dokun',
        'singleNoteTitle': 'Son Not',
        'updated': 'Güncellendi',
        'alarmsListTitle': 'Alarmlar',
        'noAlarms': 'Alarm kurulmamış',
        'nextAlarm': 'Sonraki Alarm',
        'alarmIn': '{time} sonra',
        'active': 'Aktif',
        'inactive': 'Pasif',
        'remindersListTitle': 'Hatırlatıcılar',
        'noReminders': 'Hatırlatıcı yok',
        'nextReminder': 'Sonraki Hatırlatıcı',
        'dueIn': '{time} sonra',
        'overdue': 'Gecikmiş',
        'dueToday': 'Bugün',
      };
    } else {
      return {
        'notesListTitle': 'My Notes',
        'noNotes': 'No notes yet',
        'tapToOpen': 'Tap to open',
        'singleNoteTitle': 'Latest Note',
        'updated': 'Updated',
        'alarmsListTitle': 'Alarms',
        'noAlarms': 'No alarms set',
        'nextAlarm': 'Next Alarm',
        'alarmIn': 'in {time}',
        'active': 'Active',
        'inactive': 'Inactive',
        'remindersListTitle': 'Reminders',
        'noReminders': 'No reminders',
        'nextReminder': 'Next Reminder',
        'dueIn': 'Due in {time}',
        'overdue': 'Overdue',
        'dueToday': 'Due today',
      };
    }
  }

  /// Format time difference for display
  static String _formatTimeDifference(DateTime target) {
    final now = DateTime.now();
    final difference = target.difference(now);
    
    if (difference.isNegative) {
      return _getLocalizedStrings()['overdue']!;
    }
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Update legacy single note widget (backward compatibility)
  static Future<void> updateWidget(List<Note> notes) async {
    final strings = _getLocalizedStrings();
    
    if (notes.isEmpty) {
      await HomeWidget.saveWidgetData<String>('title', strings['notesListTitle']!);
      await HomeWidget.saveWidgetData<String>('content', strings['noNotes']!);
    } else {
      final note = notes.first;
      await HomeWidget.saveWidgetData<String>('title', note.title);
      String content = note.content;
      if (content.startsWith('[')) {
        content = strings['tapToOpen']!;
      }
      await HomeWidget.saveWidgetData<String>('content', content);
    }
    
    await HomeWidget.updateWidget(
      name: _noteWidgetName,
      iOSName: _iosNoteWidgetName,
    );
  }

  /// Update Notes List Widget
  static Future<void> updateNotesListWidget(List<Note> notes) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'notes_list');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['notesListTitle']!);
    
    if (notes.isEmpty) {
      await HomeWidget.saveWidgetData<String>('empty_message', strings['noNotes']!);
      await HomeWidget.saveWidgetData<String>('notes_data', '[]');
    } else {
      // Take up to 5 most recent notes
      final recentNotes = notes.take(5).toList();
      final notesData = recentNotes.map((note) {
        return {
          'id': note.id,
          'title': note.title.isEmpty ? 'Untitled' : note.title,
          'content': note.content.startsWith('[') ? strings['tapToOpen']! : note.content.substring(0, note.content.length > 50 ? 50 : note.content.length),
          'color': note.color,
          'updated': DateFormat('MMM d').format(note.updatedAt),
        };
      }).toList();
      
      await HomeWidget.saveWidgetData<String>('notes_data', jsonEncode(notesData));
    }
    
    await HomeWidget.updateWidget(
      name: _notesListWidgetName,
      iOSName: _iosNotesListWidgetName,
    );
  }

  /// Update Single Note Widget
  static Future<void> updateSingleNoteWidget(List<Note> notes) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'single_note');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['singleNoteTitle']!);
    
    if (notes.isEmpty) {
      await HomeWidget.saveWidgetData<String>('note_title', strings['noNotes']!);
      await HomeWidget.saveWidgetData<String>('note_content', strings['tapToOpen']!);
      await HomeWidget.saveWidgetData<String>('note_color', '#FFB74D');
      await HomeWidget.saveWidgetData<String>('note_updated', '');
    } else {
      final note = notes.first;
      await HomeWidget.saveWidgetData<String>('note_title', note.title.isEmpty ? 'Untitled' : note.title);
      await HomeWidget.saveWidgetData<String>('note_content', 
        note.content.startsWith('[') ? strings['tapToOpen']! : note.content);
      await HomeWidget.saveWidgetData<String>('note_color', note.color);
      await HomeWidget.saveWidgetData<String>('note_updated', 
        '${strings['updated']}: ${DateFormat('MMM d, HH:mm').format(note.updatedAt)}');
    }
    
    await HomeWidget.updateWidget(
      name: _singleNoteWidgetName,
      iOSName: _iosSingleNoteWidgetName,
    );
  }

  /// Update Alarms List Widget
  static Future<void> updateAlarmsListWidget(List<Alarm> alarms) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'alarms_list');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['alarmsListTitle']!);
    
    if (alarms.isEmpty) {
      await HomeWidget.saveWidgetData<String>('empty_message', strings['noAlarms']!);
      await HomeWidget.saveWidgetData<String>('alarms_data', '[]');
    } else {
      // Sort by time and take up to 5
      final sortedAlarms = List<Alarm>.from(alarms)
        ..sort((a, b) => a.time.compareTo(b.time));
      final upcomingAlarms = sortedAlarms.take(5).toList();
      
      final alarmsData = upcomingAlarms.map((alarm) {
        return {
          'id': alarm.id,
          'title': alarm.title,
          'time': DateFormat('HH:mm').format(alarm.time),
          'isActive': alarm.isActive,
          'repeatDays': alarm.repeatDays.join(','),
          'status': alarm.isActive ? strings['active']! : strings['inactive']!,
        };
      }).toList();
      
      await HomeWidget.saveWidgetData<String>('alarms_data', jsonEncode(alarmsData));
    }
    
    await HomeWidget.updateWidget(
      name: _alarmsListWidgetName,
      iOSName: _iosAlarmsListWidgetName,
    );
  }

  /// Update Single Alarm Widget
  static Future<void> updateSingleAlarmWidget(List<Alarm> alarms) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'single_alarm');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['nextAlarm']!);
    
    if (alarms.isEmpty) {
      await HomeWidget.saveWidgetData<String>('alarm_title', strings['noAlarms']!);
      await HomeWidget.saveWidgetData<String>('alarm_time', '--:--');
      await HomeWidget.saveWidgetData<String>('alarm_status', '');
      await HomeWidget.saveWidgetData<String>('alarm_in', '');
    } else {
      // Find next active alarm
      final activeAlarms = alarms.where((a) => a.isActive).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      
      if (activeAlarms.isEmpty) {
        await HomeWidget.saveWidgetData<String>('alarm_title', strings['noAlarms']!);
        await HomeWidget.saveWidgetData<String>('alarm_time', '--:--');
        await HomeWidget.saveWidgetData<String>('alarm_status', '');
        await HomeWidget.saveWidgetData<String>('alarm_in', '');
      } else {
        final nextAlarm = activeAlarms.first;
        final timeUntil = _formatTimeDifference(nextAlarm.time);
        
        await HomeWidget.saveWidgetData<String>('alarm_title', nextAlarm.title);
        await HomeWidget.saveWidgetData<String>('alarm_time', DateFormat('HH:mm').format(nextAlarm.time));
        await HomeWidget.saveWidgetData<String>('alarm_status', strings['active']!);
        await HomeWidget.saveWidgetData<String>('alarm_in', 
          strings['alarmIn']!.replaceAll('{time}', timeUntil));
      }
    }
    
    await HomeWidget.updateWidget(
      name: _singleAlarmWidgetName,
      iOSName: _iosSingleAlarmWidgetName,
    );
  }

  /// Update Reminders List Widget
  static Future<void> updateRemindersListWidget(List<Reminder> reminders) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'reminders_list');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['remindersListTitle']!);
    
    if (reminders.isEmpty) {
      await HomeWidget.saveWidgetData<String>('empty_message', strings['noReminders']!);
      await HomeWidget.saveWidgetData<String>('reminders_data', '[]');
    } else {
      // Filter incomplete and sort by date, take up to 5
      final incompleteReminders = reminders
        .where((r) => !r.isCompleted)
        .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final upcomingReminders = incompleteReminders.take(5).toList();
      
      final remindersData = upcomingReminders.map((reminder) {
        final now = DateTime.now();
        final isOverdue = reminder.dateTime.isBefore(now);
        final isToday = reminder.dateTime.year == now.year && 
                        reminder.dateTime.month == now.month && 
                        reminder.dateTime.day == now.day;
        
        String timeText;
        if (isOverdue) {
          timeText = strings['overdue']!;
        } else if (isToday) {
          timeText = strings['dueToday']!;
        } else {
          timeText = DateFormat('MMM d, HH:mm').format(reminder.dateTime);
        }
        
        return {
          'id': reminder.id,
          'title': reminder.title,
          'description': reminder.description,
          'dateTime': timeText,
          'priority': reminder.priority,
          'isOverdue': isOverdue,
        };
      }).toList();
      
      await HomeWidget.saveWidgetData<String>('reminders_data', jsonEncode(remindersData));
    }
    
    await HomeWidget.updateWidget(
      name: _remindersListWidgetName,
      iOSName: _iosRemindersListWidgetName,
    );
  }

  /// Update Single Reminder Widget
  static Future<void> updateSingleReminderWidget(List<Reminder> reminders) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('widget_type', 'single_reminder');
    await HomeWidget.saveWidgetData<String>('locale', _getCurrentLocale());
    await HomeWidget.saveWidgetData<String>('title', strings['nextReminder']!);
    
    if (reminders.isEmpty) {
      await HomeWidget.saveWidgetData<String>('reminder_title', strings['noReminders']!);
      await HomeWidget.saveWidgetData<String>('reminder_description', '');
      await HomeWidget.saveWidgetData<String>('reminder_datetime', '');
      await HomeWidget.saveWidgetData<String>('reminder_priority', 'medium');
      await HomeWidget.saveWidgetData<String>('reminder_overdue', 'false');
    } else {
      // Find next incomplete reminder
      final incompleteReminders = reminders
        .where((r) => !r.isCompleted)
        .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      if (incompleteReminders.isEmpty) {
        await HomeWidget.saveWidgetData<String>('reminder_title', strings['noReminders']!);
        await HomeWidget.saveWidgetData<String>('reminder_description', '');
        await HomeWidget.saveWidgetData<String>('reminder_datetime', '');
        await HomeWidget.saveWidgetData<String>('reminder_priority', 'medium');
        await HomeWidget.saveWidgetData<String>('reminder_overdue', 'false');
      } else {
        final nextReminder = incompleteReminders.first;
        final now = DateTime.now();
        final isOverdue = nextReminder.dateTime.isBefore(now);
        final timeUntil = _formatTimeDifference(nextReminder.dateTime);
        
        await HomeWidget.saveWidgetData<String>('reminder_title', nextReminder.title);
        await HomeWidget.saveWidgetData<String>('reminder_description', nextReminder.description);
        await HomeWidget.saveWidgetData<String>('reminder_datetime', 
          DateFormat('MMM d, HH:mm').format(nextReminder.dateTime));
        await HomeWidget.saveWidgetData<String>('reminder_priority', nextReminder.priority);
        await HomeWidget.saveWidgetData<String>('reminder_overdue', isOverdue.toString());
        await HomeWidget.saveWidgetData<String>('reminder_due_in', 
          isOverdue ? strings['overdue']! : strings['dueIn']!.replaceAll('{time}', timeUntil));
      }
    }
    
    await HomeWidget.updateWidget(
      name: _singleReminderWidgetName,
      iOSName: _iosSingleReminderWidgetName,
    );
  }

  /// Update all widgets at once
  static Future<void> updateAllWidgets({
    List<Note>? notes,
    List<Alarm>? alarms,
    List<Reminder>? reminders,
  }) async {
    if (notes != null) {
      await updateWidget(notes);
      await updateNotesListWidget(notes);
      await updateSingleNoteWidget(notes);
    }
    
    if (alarms != null) {
      await updateAlarmsListWidget(alarms);
      await updateSingleAlarmWidget(alarms);
    }
    
    if (reminders != null) {
      await updateRemindersListWidget(reminders);
      await updateSingleReminderWidget(reminders);
    }
  }

  /// Update Weather Widget
  static Future<void> updateWeatherWidget({
    required String city,
    required double temp,
    required String condition,
  }) async {
    final strings = _getLocalizedStrings();
    
    await HomeWidget.saveWidgetData<String>('weather_city', city);
    await HomeWidget.saveWidgetData<String>('weather_temp', '${temp.toStringAsFixed(1)}°');
    await HomeWidget.saveWidgetData<String>('weather_condition', condition);
    await HomeWidget.saveWidgetData<String>('weather_updated', 
      '${strings['updated']}: ${DateFormat('HH:mm').format(DateTime.now())}');
      
    await HomeWidget.updateWidget(
      name: _weatherWidgetName,
      iOSName: _iosWeatherWidgetName,
    );
  }

  /// Set Widget Theme (Transparent/Solid)
  static Future<void> setWidgetTheme({required bool isTransparent}) async {
    await HomeWidget.saveWidgetData<bool>('widget_theme_transparent', isTransparent);
    
    // Force update all widgets to apply theme
    // We don't send new data, just trigger update
    await HomeWidget.updateWidget(name: _noteWidgetName, iOSName: _iosNoteWidgetName);
    await HomeWidget.updateWidget(name: _singleNoteWidgetName, iOSName: _iosSingleNoteWidgetName);
    await HomeWidget.updateWidget(name: _notesListWidgetName, iOSName: _iosNotesListWidgetName);
    await HomeWidget.updateWidget(name: _singleAlarmWidgetName, iOSName: _iosSingleAlarmWidgetName);
    await HomeWidget.updateWidget(name: _alarmsListWidgetName, iOSName: _iosAlarmsListWidgetName);
    await HomeWidget.updateWidget(name: _singleReminderWidgetName, iOSName: _iosSingleReminderWidgetName);
    await HomeWidget.updateWidget(name: _remindersListWidgetName, iOSName: _iosRemindersListWidgetName);
    await HomeWidget.updateWidget(name: _weatherWidgetName, iOSName: _iosWeatherWidgetName);
  }
}
