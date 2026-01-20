
class NotificationLog {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? type; // 'alarm', 'reminder', 'system'
  final String? payload;

  NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    this.type,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'type': type,
      'payload': payload,
    };
  }

  factory NotificationLog.fromMap(Map<String, dynamic> map) {
    return NotificationLog(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] == 1,
      type: map['type'],
      payload: map['payload'],
    );
  }

  NotificationLog copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? payload,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      payload: payload ?? this.payload,
    );
  }
}
