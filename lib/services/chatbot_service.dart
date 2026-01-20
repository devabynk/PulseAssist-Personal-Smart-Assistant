import 'package:uuid/uuid.dart';
import '../models/message.dart';
import 'nlp/nlp_engine.dart';

/// ChatbotService - Main interface for chatbot functionality
/// Uses NLP Engine for intelligent response generation
class ChatbotService {
  static final ChatbotService instance = ChatbotService._init();
  final Uuid _uuid = const Uuid();
  final NlpEngine _nlpEngine = NlpEngine.instance;

  ChatbotService._init();

  /// Generate a response based on user input
  String generateResponse(String userMessage, {bool isTurkish = true}) {
    final response = _nlpEngine.process(userMessage, isTurkish: isTurkish);
    return response.text;
  }

  /// Create a bot message
  Message createBotMessage(String content) {
    return Message(
      id: _uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  /// Create a user message
  Message createUserMessage(String content) {
    return Message(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  /// Reset conversation context
  void resetContext() {
    _nlpEngine.resetContext();
  }
}
