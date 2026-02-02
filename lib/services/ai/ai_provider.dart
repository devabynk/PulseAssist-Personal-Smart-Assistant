/// Base interface for AI providers
abstract class AiProvider {
  /// Provider name for logging
  String get name;

  /// Check if this provider is available
  bool get isAvailable;

  /// Initialize the provider
  Future<void> initialize({String? apiKey});

  /// Send a message with context
  Future<String?> chat({
    required String message,
    required bool isTurkish,
    String? userName,
    List<ChatMessage>? conversationHistory,
  });

  /// Clear session
  void clearSession();
}

/// Chat message for context
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? attachmentPath;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachmentPath,
  });

  @override
  String toString() =>
      '${isUser ? "User" : "Assistant"}: $content ${attachmentPath != null ? "[Attachment]" : ""}';
}
