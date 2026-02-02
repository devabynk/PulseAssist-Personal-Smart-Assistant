import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:smart_assistant/providers/chat_provider.dart';
import 'package:smart_assistant/services/ai/ai_manager.dart';
import 'package:smart_assistant/services/database_service.dart';
import 'package:smart_assistant/services/nlp/nlp_engine.dart';

import 'chat_provider_test.mocks.dart';

@GenerateMocks([DatabaseService, AiManager, NlpEngine])
void main() {
  late ChatProvider chatProvider;
  late MockDatabaseService mockDb;
  late MockAiManager mockAi;
  late MockNlpEngine mockNlp;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAi = MockAiManager();
    mockNlp = MockNlpEngine();

    // Default stubs to prevent null errors in constructor
    when(mockDb.getConversations()).thenAnswer((_) async => []);

    chatProvider = ChatProvider(db: mockDb, ai: mockAi, nlp: mockNlp);
  });

  group('ChatProvider Tests', () {
    test('Initial state should be empty', () {
      expect(chatProvider.messages, isEmpty);
      expect(chatProvider.activeConversation, isNull);
    });

    test(
      'startNewConversation creates a conversation and updates state',
      () async {
        // Arrange
        when(mockDb.insertConversation(any)).thenAnswer((_) async => {});
        when(mockDb.insertMessage(any)).thenAnswer((_) async => {});

        // Act
        await chatProvider.startNewConversation(
          isTurkish: true,
          addWelcomeMessage: false,
        );

        // Assert
        expect(chatProvider.activeConversation, isNotNull);
        verify(mockDb.insertConversation(any)).called(1);
      },
    );
  });
}
