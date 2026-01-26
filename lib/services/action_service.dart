import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import 'database_service.dart';
import 'nlp/nlp_engine.dart';
import 'nlp/intent_classifier.dart';
import 'nlp/entity_extractor.dart';
// Providers
import '../providers/alarm_provider.dart';
import '../providers/note_provider.dart';
import '../providers/reminder_provider.dart';
import '../l10n/app_localizations.dart';

import '../services/learning_service.dart';
// IntentType

class ActionService {
  static final ActionService instance = ActionService._init();
  final DatabaseService _db = DatabaseService.instance;
  final LearningService _learning = LearningService.instance;
  final Uuid _uuid = const Uuid();

  ActionService._init();

  Future<String?> executeAction(NlpResponse response, {
      required AppLocalizations l10n, 
      AlarmProvider? alarmProvider, 
      NoteProvider? noteProvider,
      ReminderProvider? reminderProvider,
      bool isTurkish = true,
  }) async {
    switch (response.intent.type) {
      case IntentType.alarm:
        return await _createAlarm(response.entities, l10n, alarmProvider);
      case IntentType.reminder:
        return await _createReminder(response.entities, l10n, reminderProvider);
      case IntentType.note:
        return await _createNote(response.entities, l10n, noteProvider);
      case IntentType.listAlarms:
        return await _listAlarms(isTurkish);
      case IntentType.listNotes:
        return await _listNotes(isTurkish);
      case IntentType.listReminders:
        return await _listReminders(isTurkish);
      default:
        return null; // No action needed
    }
  }

  Future<String> _createAlarm(Map<String, dynamic> entities, AppLocalizations l10n, AlarmProvider? provider) async {
    final time = entities['time'] as TimeEntity?;
    final days = entities['days'] as DayEntity?;
    final relativeDate = entities['relativeDate'] as RelativeDateEntity?;

    if (time == null) return l10n.alarmTimeNotSpecified;

    // Calculate Alarm DateTime
    final now = DateTime.now();
    DateTime alarmDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If specific date requested (e.g. "Tomorrow")
    if (relativeDate != null) {
        alarmDate = alarmDate.add(Duration(days: relativeDate.daysFromNow));
    } else if (days == null || days.isEmpty) {
        // If no date AND no repeat, and time has passed, move to tomorrow
        if (alarmDate.isBefore(now)) {
            alarmDate = alarmDate.add(const Duration(days: 1));
        }
    }
    
    // If repeat days are set, the specific date matters less for the logic, 
    // but we usually set it to the next occurrence of that day?
    // The current Alarm model just holds 'time' and 'repeatDays'. 
    // If repeatDays is set, the day part of 'time' is ignored by UI/Logic usually, just HH:MM used.
    // So current logic is fine for repeat.
    
    final alarm = Alarm(
      id: _uuid.v4(),
      title: 'Alarm',
      time: alarmDate,
      isActive: true,
      repeatDays: days?.days ?? [],
      soundPath: 'assets/alarm.mp3',
      soundName: 'Default',
    );

    if (provider != null) {
        await provider.addAlarm(alarm);
    } else {
        await _db.insertAlarm(alarm); 
    }
    
    // Record Habit
    await _learning.recordHabit(IntentType.alarm, entities);
    
    return l10n.alarmSet(time.formatted); // Assuming localize method exists or constructing string
  }

  Future<String> _createReminder(Map<String, dynamic> entities, AppLocalizations l10n, ReminderProvider? provider) async {
    final time = entities['time'] as TimeEntity?;
    final relativeDate = entities['relativeDate'] as RelativeDateEntity?;
    final content = entities['content'] as String? ?? l10n.reminder;
    final priority = entities['priority'] as PriorityEntity?;

    // Calculate actual DateTime
    DateTime scheduledDate = DateTime.now();
    
    if (relativeDate != null) {
      scheduledDate = scheduledDate.add(Duration(days: relativeDate.daysFromNow));
    }
    
    if (time != null) {
      // Parse if needed or use time object
      scheduledDate = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        time.hour,
        time.minute,
      );
      
      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(DateTime.now()) && relativeDate == null) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    } else {
        // Default to 9 AM
         scheduledDate = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        9,
        0,
      );
    }

    final reminder = Reminder(
      id: _uuid.v4(),
      title: content,
      dateTime: scheduledDate,
      priority: priority?.level ?? 'medium',
    );

    if (provider != null) {
      await provider.addReminder(reminder);
    } else {
      await _db.insertReminder(reminder);
    }
    return l10n.reminderSet(content);
  }
  
  Future<String> _createNote(Map<String, dynamic> entities, AppLocalizations l10n, NoteProvider? provider) async {
    final title = entities['title'] as String?;
    final content = entities['content'] as String?;
    final color = entities['color'] as String?;
    
    if (content == null && (title == null || title.isEmpty)) {
      return l10n.noteContentEmpty;
    }

    final note = Note(
      id: _uuid.v4(),
      title: title ?? l10n.newNote,
      content: content ?? '', 
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: color ?? '#FFB74D', // Default Orange if no color specified
      orderIndex: 0
    );

    if (provider != null) {
        await provider.addNote(note);
    } else {
        await _db.insertNote(note);
    }
    return l10n.noteSaved;
  }
  
  // === LIST METHODS ===
  
  Future<String> _listAlarms(bool isTurkish) async {
    final alarms = await _db.getAlarms();
    if (alarms.isEmpty) {
      return isTurkish ? "Kayıtlı alarm bulunmuyor." : "No alarms found.";
    }
    
    final buffer = StringBuffer();
    buffer.writeln(isTurkish ? "📢 **Alarmlarınız:**" : "📢 **Your Alarms:**");
    
    for (int i = 0; i < alarms.length; i++) {
      final a = alarms[i];
      final timeStr = "${a.time.hour.toString().padLeft(2,'0')}:${a.time.minute.toString().padLeft(2,'0')}";
      final status = a.isActive ? "✅" : "❌";
      buffer.writeln("${i+1}. $status $timeStr - ${a.title}");
    }
    
    return buffer.toString();
  }
  
  Future<String> _listNotes(bool isTurkish) async {
    final notes = await _db.getNotes();
    if (notes.isEmpty) {
      return isTurkish ? "Kayıtlı not bulunmuyor." : "No notes found.";
    }
    
    final buffer = StringBuffer();
    buffer.writeln(isTurkish ? "📝 **Notlarınız:**" : "📝 **Your Notes:**");
    
    for (int i = 0; i < notes.length && i < 10; i++) {
      final n = notes[i];
      final preview = n.content.length > 30 ? "${n.content.substring(0, 30)}..." : n.content;
      buffer.writeln("${i+1}. **${n.title}** - $preview");
    }
    
    if (notes.length > 10) {
      buffer.writeln("... ${isTurkish ? 've ${notes.length - 10} not daha' : 'and ${notes.length - 10} more'}");
    }
    
    return buffer.toString();
  }
  
  Future<String> _listReminders(bool isTurkish) async {
    final reminders = await _db.getReminders();
    final upcoming = reminders.where((r) => !r.isCompleted).toList();
    
    if (upcoming.isEmpty) {
      return isTurkish ? "Bekleyen hatırlatıcı bulunmuyor." : "No pending reminders.";
    }
    
    final buffer = StringBuffer();
    buffer.writeln(isTurkish ? "🔔 **Hatırlatıcılarınız:**" : "🔔 **Your Reminders:**");
    
    for (int i = 0; i < upcoming.length && i < 10; i++) {
      final r = upcoming[i];
      final dateStr = "${r.dateTime.day}/${r.dateTime.month} ${r.dateTime.hour.toString().padLeft(2,'0')}:${r.dateTime.minute.toString().padLeft(2,'0')}";
      buffer.writeln("${i+1}. **${r.title}** - $dateStr");
    }
    
    if (upcoming.length > 10) {
      buffer.writeln("... ${isTurkish ? 've ${upcoming.length - 10} hatırlatıcı daha' : 'and ${upcoming.length - 10} more'}");
    }
    
    return buffer.toString();
  }
}
