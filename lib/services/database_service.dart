import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';


import '../models/conversation.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../models/message.dart';
import '../models/user_habit.dart';
import '../models/notification_log.dart';
import '../models/user_location.dart';

import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._init();

  DatabaseService._init();

  late Box<Message> _messagesBox;
  late Box<Conversation> _conversationsBox;
  late Box<Alarm> _alarmsBox;
  late Box<Note> _notesBox;
  late Box<Reminder> _remindersBox;
  late Box<NotificationLog> _notificationLogsBox;
  late Box<UserHabit> _userHabitsBox;
  late Box<UserLocation> _userLocationBox;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // EXPLICIT PATH: Ensure data persists across restarts
    final appDocumentDir = await getApplicationDocumentsDirectory();
    debugPrint('📂 Hive DB Directory: ${appDocumentDir.path}');
    await Hive.initFlutter(appDocumentDir.path);
    // await Hive.initFlutter(); // OLD MIGRATION: might default to temp on some configs

    
    // Register Adapters
    Hive.registerAdapter(ConversationAdapter());
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(AlarmAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ReminderAdapter());
    Hive.registerAdapter(SubtaskAdapter()); // Reminder uses Subtask
    Hive.registerAdapter(NotificationLogAdapter());
    Hive.registerAdapter(UserHabitAdapter());
    Hive.registerAdapter(UserLocationAdapter());

    // Open Boxes
    _messagesBox = await Hive.openBox<Message>('messages');
    debugPrint('📦 Hive Box Opened: messages at ${_messagesBox.path}');
    
    _conversationsBox = await Hive.openBox<Conversation>('conversations');
    _alarmsBox = await Hive.openBox<Alarm>('alarms');
    debugPrint('📦 Hive Box Opened: alarms at ${_alarmsBox.path} (Count: ${_alarmsBox.length})');
    
    _notesBox = await Hive.openBox<Note>('notes');
    debugPrint('📦 Hive Box Opened: notes (Count: ${_notesBox.length})');
    
    _remindersBox = await Hive.openBox<Reminder>('reminders');
    debugPrint('📦 Hive Box Opened: reminders (Count: ${_remindersBox.length})');
    
    _notificationLogsBox = await Hive.openBox<NotificationLog>('notification_logs');
    _userHabitsBox = await Hive.openBox<UserHabit>('user_habits');
    _userLocationBox = await Hive.openBox<UserLocation>('user_location');

    _isInitialized = true;
    debugPrint('✅ DatabaseService Initialized Successfully');
  }
  
  // Helper to ensure init is called if accessed lazily (though explicit init is better)
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // Messages
  Future<void> insertMessage(Message message) async {
    await _ensureInitialized();
    await _messagesBox.put(message.id, message);
    await _messagesBox.flush();
  }

  Future<List<Message>> getMessages() async {
    await _ensureInitialized();
    final messages = _messagesBox.values.toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<void> clearMessages() async {
    await _ensureInitialized();
    await _messagesBox.clear();
    await _messagesBox.flush();
  }

  Future<void> deleteMessage(String id) async {
    await _ensureInitialized();
    await _messagesBox.delete(id);
    await _messagesBox.flush();
  }

  // Conversations
  Future<void> insertConversation(Conversation conversation) async {
    await _ensureInitialized();
    await _conversationsBox.put(conversation.id, conversation);
    await _conversationsBox.flush();
  }

  Future<void> updateConversation(Conversation conversation) async {
    await _ensureInitialized();
    await _conversationsBox.put(conversation.id, conversation);
    await _conversationsBox.flush();
  }

  Future<List<Conversation>> getConversations() async {
    await _ensureInitialized();
    final conversations = _conversationsBox.values.toList();
    conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return conversations;
  }

  Future<void> deleteConversation(String id) async {
    await _ensureInitialized();
    await _conversationsBox.delete(id);
    
    // Also delete messages for this conversation
    final messagesToDelete = _messagesBox.values
        .where((m) => m.conversationId == id)
        .map((m) => m.id)
        .toList();
    await _messagesBox.deleteAll(messagesToDelete);
    
    // Flush both boxes
    await _conversationsBox.flush();
    await _messagesBox.flush();
  }

  Future<List<Message>> getMessagesForConversation(String conversationId) async {
    await _ensureInitialized();
    final messages = _messagesBox.values
        .where((m) => m.conversationId == conversationId)
        .toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // Alarms
  Future<void> insertAlarm(Alarm alarm) async {
    await _ensureInitialized();
    await _alarmsBox.put(alarm.id, alarm);
    await _alarmsBox.flush();
    debugPrint('💾 Inserted Alarm: ${alarm.id} (Title: ${alarm.title}). Total: ${_alarmsBox.length}');
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _ensureInitialized();
    await _alarmsBox.put(alarm.id, alarm);
    await _alarmsBox.flush();
    debugPrint('💾 Updated Alarm: ${alarm.id}');
  }

  Future<void> deleteAlarm(String id) async {
    await _ensureInitialized();
    if (_alarmsBox.containsKey(id)) {
       await _alarmsBox.delete(id);
       await _alarmsBox.flush();
       debugPrint('🗑️ Deleted Alarm: $id. Remaining: ${_alarmsBox.length}');
    } else {
       debugPrint('⚠️ Delete Failed: Alarm ID $id not found in box.');
       // Dump keys
       debugPrint('Keys available: ${_alarmsBox.keys.toList()}');
    }
  }

  Future<List<Alarm>> getAlarms() async {
    await _ensureInitialized();
    final alarms = _alarmsBox.values.toList();
    alarms.sort((a, b) => a.time.compareTo(b.time));
    return alarms;
  }

  // Notes
  Future<void> insertNote(Note note) async {
    await _ensureInitialized();
    await _notesBox.put(note.id, note);
    await _notesBox.flush();
  }

  Future<void> updateNote(Note note) async {
    await _ensureInitialized();
    await _notesBox.put(note.id, note);
    await _notesBox.flush();
  }

  Future<void> deleteNote(String id) async {
    await _ensureInitialized();
    await _notesBox.delete(id);
    await _notesBox.flush();
  }

  Future<List<Note>> getNotes() async {
    await _ensureInitialized();
    final notes = _notesBox.values.toList();
    // Sort by orderIndex ASC, then updatedAt DESC
    notes.sort((a, b) {
      int comparison = a.orderIndex.compareTo(b.orderIndex);
      if (comparison != 0) return comparison;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<void> updateNoteOrder(List<Note> notes) async {
    await _ensureInitialized();
    for (int i = 0; i < notes.length; i++) {
        final note = notes[i].copyWith(orderIndex: i);
        await _notesBox.put(note.id, note);
    }
    await _notesBox.flush();
  }

  // Reminders
  Future<void> insertReminder(Reminder reminder) async {
    await _ensureInitialized();
    await _remindersBox.put(reminder.id, reminder);
    await _remindersBox.flush();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await _ensureInitialized();
    await _remindersBox.put(reminder.id, reminder);
    await _remindersBox.flush();
  }

  Future<void> deleteReminder(String id) async {
    await _ensureInitialized();
    await _remindersBox.delete(id);
    await _remindersBox.flush();
  }

  Future<List<Reminder>> getReminders() async {
    await _ensureInitialized();
    final reminders = _remindersBox.values.toList();
    // Sort by orderIndex ASC, then dateTime ASC
    reminders.sort((a, b) {
      int comparison = a.orderIndex.compareTo(b.orderIndex);
      if (comparison != 0) return comparison;
      return a.dateTime.compareTo(b.dateTime);
    });
    return reminders;
  }

  Future<void> updateReminderOrder(List<Reminder> reminders) async {
    await _ensureInitialized();
    for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i].copyWith(orderIndex: i);
        await _remindersBox.put(reminder.id, reminder);
    }
    await _remindersBox.flush();
  }

  // User Habits
  Future<void> insertHabit(UserHabit habit) async {
    await _ensureInitialized();
    await _userHabitsBox.put(habit.id, habit);
    await _userHabitsBox.flush();
  }

  Future<void> updateHabit(UserHabit habit) async {
    await _ensureInitialized();
    await _userHabitsBox.put(habit.id, habit);
    await _userHabitsBox.flush();
  }

  Future<List<UserHabit>> getHabitsForIntent(String intent) async {
    await _ensureInitialized();
    final habits = _userHabitsBox.values
        .where((h) => h.intent == intent)
        .toList();
    habits.sort((a, b) => b.frequency.compareTo(a.frequency)); // Most frequent first
    return habits;
  }

  Future<UserHabit?> getHabitByParams(String intent, String params) async {
    await _ensureInitialized();
    try {
      final habit = _userHabitsBox.values.firstWhere(
        (h) => h.intent == intent && h.parameters == params,
      );
      return habit;
    } catch (e) {
      return null;
    }
  }

  // Notification Log Operations
  Future<void> insertNotificationLog(NotificationLog log) async {
    await _ensureInitialized();
    await _notificationLogsBox.put(log.id, log);
    await _notificationLogsBox.flush();
  }

  Future<List<NotificationLog>> getNotificationLogs() async {
    await _ensureInitialized();
    final logs = _notificationLogsBox.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // DESC
    return logs;
  }

  Future<void> updateNotificationLog(NotificationLog log) async {
    await _ensureInitialized();
    await _notificationLogsBox.put(log.id, log);
    await _notificationLogsBox.flush();
  }

  Future<void> deleteNotificationLog(String id) async {
    await _ensureInitialized();
    await _notificationLogsBox.delete(id);
    await _notificationLogsBox.flush();
  }

  Future<void> deleteAllNotificationLogs() async {
    await _ensureInitialized();
    await _notificationLogsBox.clear();
    await _notificationLogsBox.flush();
  }

  // User Location Operations
  // Adapting to map format for compatibility with existing code
  Future<void> saveUserLocation(Map<String, dynamic> locationMap) async {
    await _ensureInitialized();
    final location = UserLocation(
      cityName: locationMap['city_name'],
      country: locationMap['country'],
      state: locationMap['state'],
      district: locationMap['district'],
      latitude: locationMap['latitude'] is double ? locationMap['latitude'] : (locationMap['latitude'] as num).toDouble(),
      longitude: locationMap['longitude'] is double ? locationMap['longitude'] : (locationMap['longitude'] as num).toDouble(),
      lastUpdated: DateTime.parse(locationMap['last_updated']),
    );
    // Using key 'current' since we only allow one location
    await _userLocationBox.put('current', location);
    await _userLocationBox.flush();
  }

  Future<Map<String, dynamic>?> getUserLocation() async {
    await _ensureInitialized();
    final location = _userLocationBox.get('current');
    if (location != null) {
      return {
        'city_name': location.cityName,
        'country': location.country,
        'state': location.state,
        'district': location.district,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'last_updated': location.lastUpdated.toIso8601String(),
      };
    }
    return null;
  }

  Future<void> deleteUserLocation() async {
    await _ensureInitialized();
    await _userLocationBox.delete('current');
    await _userLocationBox.flush();
  }

  Future<void> close() async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
    }
  }
}
