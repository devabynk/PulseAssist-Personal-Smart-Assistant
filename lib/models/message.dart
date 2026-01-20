class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final String? attachmentPath;
  final String? attachmentType; // 'image', 'audio', 'file'

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
    this.attachmentPath,
    this.attachmentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'conversation_id': conversationId,
      'attachmentPath': attachmentPath,
      'attachmentType': attachmentType,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      conversationId: map['conversation_id'],
      attachmentPath: map['attachmentPath'],
      attachmentType: map['attachmentType'],
    );
  }
}
