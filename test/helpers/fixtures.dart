import 'dart:convert';
import 'dart:io';

/// Helper class for loading test fixtures

class FixtureReader {
  /// Read a fixture file and return its contents as a string
  static String fixture(String name) {
    final file = File('test/fixtures/$name');
    if (!file.existsSync()) {
      throw Exception('Fixture file not found: test/fixtures/$name');
    }
    return file.readAsStringSync();
  }

  /// Read a JSON fixture and return it as a Map
  static Map<String, dynamic> jsonFixture(String name) {
    final jsonString = fixture('json/$name');
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Read a JSON fixture and return it as a List
  static List<dynamic> jsonListFixture(String name) {
    final jsonString = fixture('json/$name');
    return json.decode(jsonString) as List<dynamic>;
  }
}

/// Common test data constants
class TestData {
  TestData._();

  // Test API Keys
  static const String testGroqApiKey = 'test-groq-api-key';
  static const String testWeatherApiKey = 'test-weather-api-key';
  static const String testPharmacyApiKey = 'test-pharmacy-api-key';
  static const String testEventApiKey = 'test-event-api-key';

  // Test User Data
  static const String testUserId = 'test-user-id';
  static const String testUserName = 'Test User';
  static const String testUserEmail = 'test@example.com';

  // Test Conversation Data
  static const String testConversationId = 'test-conversation-id';
  static const String testConversationTitle = 'Test Conversation';

  // Test Message Data
  static const String testMessageId = 'test-message-id';
  static const String testMessageContent = 'Test message content';

  // Test Alarm Data
  static const String testAlarmId = 'test-alarm-id';
  static const String testAlarmTitle = 'Test Alarm';

  // Test Note Data
  static const String testNoteId = 'test-note-id';
  static const String testNoteTitle = 'Test Note';
  static const String testNoteContent = 'Test note content';

  // Test Reminder Data
  static const String testReminderId = 'test-reminder-id';
  static const String testReminderTitle = 'Test Reminder';
  static const String testReminderDescription = 'Test reminder description';

  // Test Dates
  static DateTime get testDateTime => DateTime(2026, 2, 13, 15, 30);
  static DateTime get testDateTimeFuture => DateTime(2026, 12, 31, 23, 59);
  static DateTime get testDateTimePast => DateTime(2025, 1, 1, 0, 0);
}
