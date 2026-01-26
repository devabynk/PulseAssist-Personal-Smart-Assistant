import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation.dart';
import '../models/alarm.dart';
import '../models/note.dart';
import '../models/reminder.dart';
import '../models/message.dart';
import '../models/user_habit.dart';
import '../models/notification_log.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_assistant.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 13, // v13: Sound name for alarms
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        conversation_id TEXT,
        attachmentPath TEXT,
        attachmentType TEXT,
        FOREIGN KEY(conversation_id) REFERENCES conversations(id)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastMessageAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        time TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        repeatDays TEXT,
        skippedDates TEXT,
        soundPath TEXT,
        soundName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        color TEXT NOT NULL,
        orderIndex INTEGER NOT NULL,
        isPinned INTEGER DEFAULT 0,
        isFullWidth INTEGER DEFAULT 0,
        imagePaths TEXT,
        drawingData TEXT,
        voiceNotePath TEXT,
        tags TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        priority TEXT,
        orderIndex INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0,
        voiceNotePath TEXT,
        subtasks TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_logs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL,
        type TEXT,
        payload TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_location (
        id INTEGER PRIMARY KEY,
        city_name TEXT NOT NULL,
        country TEXT NOT NULL,
        state TEXT,
        district TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN orderIndex INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE reminders ADD COLUMN orderIndex INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE messages ADD COLUMN conversation_id TEXT');
      await db.execute('''
        CREATE TABLE conversations (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          lastMessageAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE user_habits (
           id TEXT PRIMARY KEY,
           intent TEXT NOT NULL,
           parameters TEXT NOT NULL,
           frequency INTEGER DEFAULT 1,
           lastUsed TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Enhanced notes features
      await db.execute('ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN isFullWidth INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN imagePaths TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN drawingData TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN voiceNotePath TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT');
    }
    if (oldVersion < 6) {
      // Enhanced reminders features
      await db.execute('ALTER TABLE reminders ADD COLUMN isPinned INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE reminders ADD COLUMN voiceNotePath TEXT');
      await db.execute('ALTER TABLE reminders ADD COLUMN subtasks TEXT');
    }
    if (oldVersion < 7) {
      // Add skippedDates to alarms table
      await db.execute('ALTER TABLE alarms ADD COLUMN skippedDates TEXT');
    }

    if (oldVersion < 8) {
      // Add notification_logs table
      await db.execute('''
        CREATE TABLE notification_logs (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          isRead INTEGER NOT NULL,
          type TEXT,
          payload TEXT
        )
      ''');
    }

    if (oldVersion < 9) {
      // Add attachments to messages
      await db.execute('ALTER TABLE messages ADD COLUMN attachmentPath TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN attachmentType TEXT');
    }

    if (oldVersion < 10) {
      // Add user_location table
      await db.execute('''
        CREATE TABLE user_location (
          id INTEGER PRIMARY KEY,
          city_name TEXT NOT NULL,
          country TEXT NOT NULL,
          state TEXT,
          district TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          last_updated TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 11) {
      // Add district column to user_location table
      await db.execute('ALTER TABLE user_location ADD COLUMN district TEXT');
    }

    if (oldVersion < 12) {
      // Add soundPath to alarms table
      await db.execute('ALTER TABLE alarms ADD COLUMN soundPath TEXT');
    }
    
    if (oldVersion < 13) {
      // Add soundName to alarms table
      await db.execute('ALTER TABLE alarms ADD COLUMN soundName TEXT');
    }
  }

  // Messages
  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessages() async {
    final db = await database;
    final maps = await db.query('messages', orderBy: 'timestamp ASC');
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // Conversations
  Future<void> insertConversation(Conversation conversation) async {
    final db = await database;
    await db.insert('conversations', conversation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db.update('conversations', conversation.toMap(), where: 'id = ?', whereArgs: [conversation.id]);
  }

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final maps = await db.query('conversations', orderBy: 'lastMessageAt DESC');
    return maps.map((map) => Conversation.fromMap(map)).toList();
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
  }

  Future<List<Message>> getMessagesForConversation(String conversationId) async {
    final db = await database;
    final maps = await db.query(
      'messages', 
      where: 'conversation_id = ?', 
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC'
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  // Alarms
  Future<void> insertAlarm(Alarm alarm) async {
    final db = await database;
    await db.insert('alarms', alarm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await database;
    await db.update('alarms', alarm.toMap(), where: 'id = ?', whereArgs: [alarm.id]);
  }

  Future<void> deleteAlarm(String id) async {
    final db = await database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Alarm>> getAlarms() async {
    final db = await database;
    final maps = await db.query('alarms', orderBy: 'time ASC');
    return maps.map((map) => Alarm.fromMap(map)).toList();
  }

  // Notes
  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'orderIndex ASC, updatedAt DESC');
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> updateNoteOrder(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < notes.length; i++) {
        final note = notes[i].copyWith(orderIndex: i);
        batch.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
    }
    await batch.commit(noResult: true);
  }

  // Reminders
  Future<void> insertReminder(Reminder reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await database;
    await db.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final maps = await db.query('reminders', orderBy: 'orderIndex ASC, dateTime ASC');
    return maps.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<void> updateReminderOrder(List<Reminder> reminders) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < reminders.length; i++) {
        final reminder = reminders[i].copyWith(orderIndex: i);
        batch.update('reminders', reminder.toMap(), where: 'id = ?', whereArgs: [reminder.id]);
    }
    await batch.commit(noResult: true);
  }

  // User Habits
  Future<void> insertHabit(UserHabit habit) async {
    final db = await database;
    await db.insert('user_habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHabit(UserHabit habit) async {
    final db = await database;
    await db.update('user_habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<List<UserHabit>> getHabitsForIntent(String intent) async {
    final db = await database;
    final maps = await db.query(
      'user_habits', 
      where: 'intent = ?', 
      whereArgs: [intent],
      orderBy: 'frequency DESC' // Most frequent first
    );
    return maps.map((map) => UserHabit.fromMap(map)).toList();
  }

  Future<UserHabit?> getHabitByParams(String intent, String params) async {
    final db = await database;
    final maps = await db.query(
      'user_habits',
      where: 'intent = ? AND parameters = ?',
      whereArgs: [intent, params],
    );
    if (maps.isNotEmpty) {
      return UserHabit.fromMap(maps.first);
    }
    return null;
  }
  // Notification Log Operations
  Future<void> insertNotificationLog(NotificationLog log) async {
    final db = await database;
    await db.insert(
      'notification_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationLog>> getNotificationLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notification_logs',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => NotificationLog.fromMap(maps[i]));
  }

  Future<void> updateNotificationLog(NotificationLog log) async {
    final db = await database;
    await db.update(
      'notification_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteNotificationLog(String id) async {
    final db = await database;
    await db.delete(
      'notification_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllNotificationLogs() async {
    final db = await database;
    await db.delete('notification_logs');
  }

  // User Location Operations
  Future<void> saveUserLocation(Map<String, dynamic> location) async {
    final db = await database;
    // Delete existing location (only one location allowed)
    await db.delete('user_location');
    // Insert new location
    await db.insert('user_location', location, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserLocation() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_location', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> deleteUserLocation() async {
    final db = await database;
    await db.delete('user_location');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
