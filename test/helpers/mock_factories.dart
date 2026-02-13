import 'package:smart_assistant/models/alarm.dart';
import 'package:smart_assistant/models/conversation.dart';
import 'package:smart_assistant/models/message.dart';
import 'package:smart_assistant/models/note.dart';
import 'package:smart_assistant/models/reminder.dart';

/// Factory class for creating mock data objects for testing

class MockDataFactory {
  MockDataFactory._();

  /// Create a mock conversation
  static Conversation createMockConversation({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return Conversation(
      id: id ?? 'conv_123',
      title: title ?? 'Test Conversation',
      createdAt: createdAt ?? DateTime.now(),
      lastMessageAt: lastMessageAt ?? DateTime.now(),
    );
  }

  /// Create multiple mock conversations
  static List<Conversation> createMockConversations(int count) {
    return List.generate(
      count,
      (index) => createMockConversation(
        id: 'conv_$index',
        title: 'Conversation $index',
      ),
    );
  }

  /// Create a mock message
  static Message createMockMessage({
    String? id,
    String? conversationId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? 'msg_123',
      conversationId: conversationId ?? 'conv_123',
      content: content ?? 'Test message content',
      isUser: isUser ?? true,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create multiple mock messages
  static List<Message> createMockMessages(int count, {String? conversationId}) {
    return List.generate(
      count,
      (index) => createMockMessage(
        id: 'msg_$index',
        conversationId: conversationId ?? 'conv_123',
        content: 'Message $index',
        isUser: index % 2 == 0,
      ),
    );
  }

  /// Create a mock alarm
  static Alarm createMockAlarm({
    String? id,
    String? title,
    DateTime? time,
    bool? isActive,
    List<int>? repeatDays,
    String? soundPath,
    String? soundName,
  }) {
    return Alarm(
      id: id ?? 'alarm_123',
      title: title ?? 'Test Alarm',
      time: time ?? DateTime.now(),
      isActive: isActive ?? true,
      repeatDays: repeatDays ?? [],
      soundPath: soundPath,
      soundName: soundName,
    );
  }

  /// Create multiple mock alarms
  static List<Alarm> createMockAlarms(int count) {
    return List.generate(
      count,
      (index) => createMockAlarm(
        id: 'alarm_$index',
        title: 'Alarm $index',
        time: DateTime.now().add(Duration(hours: index)),
      ),
    );
  }

  /// Create a mock note
  static Note createMockNote({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return Note(
      id: id ?? 'note_123',
      title: title ?? 'Test Note',
      content: content ?? 'Test note content',
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      color: color ?? '#FFB74D', // Provide default value for non-nullable field
    );
  }

  /// Create multiple mock notes
  static List<Note> createMockNotes(int count) {
    return List.generate(
      count,
      (index) => createMockNote(
        id: 'note_$index',
        title: 'Note $index',
        content: 'Content for note $index',
      ),
    );
  }

  /// Create a mock reminder
  static Reminder createMockReminder({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    String? priority,
  }) {
    return Reminder(
      id: id ?? 'reminder_123',
      title: title ?? 'Test Reminder',
      description: description ?? 'Test reminder description',
      dateTime: dateTime ?? DateTime.now(),
      isCompleted: isCompleted ?? false,
      priority: priority ?? 'medium',
    );
  }

  /// Create multiple mock reminders
  static List<Reminder> createMockReminders(int count) {
    return List.generate(
      count,
      (index) => createMockReminder(
        id: 'reminder-$index',
        title: 'Reminder $index',
        dateTime: DateTime.now().add(Duration(days: index + 1)),
      ),
    );
  }
}
