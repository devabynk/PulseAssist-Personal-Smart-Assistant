import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_assistant/services/ai/groq_provider.dart';
import 'package:smart_assistant/services/ai/ai_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Groq API Tests', () {
    test('Groq Provider Initialization', () async {
      final groq = GroqProvider();
      await groq.initialize();
      
      expect(groq.isAvailable, true, reason: 'Groq should be initialized');
    });
    
    test('Groq Chat Test - English', () async {
      final groq = GroqProvider();
      await groq.initialize();
      
      if (!groq.isAvailable) {
        print('Groq not available, skipping test');
        return;
      }
      
      final response = await groq.chat(
        message: 'Hello, test message',
        isTurkish: false,
      );
      
      print('Groq Response (EN): $response');
      expect(response, isNotNull, reason: 'Groq should return a response');
    });
    
    test('Groq Chat Test - Turkish', () async {
      final groq = GroqProvider();
      await groq.initialize();
      
      if (!groq.isAvailable) {
        print('Groq not available, skipping test');
        return;
      }
      
      final response = await groq.chat(
        message: 'Merhaba, test mesajı',
        isTurkish: true,
      );
      
      print('Groq Response (TR): $response');
      expect(response, isNotNull, reason: 'Groq should return a response');
    });
    
    test('AI Manager Initialization', () async {
      await AiManager.instance.initialize();
      
      final status = AiManager.instance.getProvidersStatus();
      print('AI Manager Status: $status');
      
      expect(status['Groq'], true, reason: 'Groq should be available');
    });
  });
}
