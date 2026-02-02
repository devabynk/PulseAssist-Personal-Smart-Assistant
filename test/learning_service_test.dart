import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/learning_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // Basic instantiation test (Mocking DB is hard without overrides,
  // so this acts as a placeholder or we can implement a mock-friendly version later).
  // For now, checks if imports work and class exists.
  test('LearningService instance exists', () {
    final service = LearningService.instance;
    expect(service, isNotNull);
  });
}
