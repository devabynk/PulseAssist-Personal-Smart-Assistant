class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
    };
  }

  static Conversation fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
      lastMessageAt: DateTime.parse(map['lastMessageAt']),
    );
  }
}
