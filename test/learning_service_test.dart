import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/services/learning_service.dart';

void main() {
  test('LearningService instance exists', () {
    final service = LearningService.instance;
    expect(service, isNotNull);
  });
}
