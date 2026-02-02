import 'package:hive_ce/hive.dart';

part 'notification_log.g.dart';

@HiveType(typeId: 6)
class NotificationLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final bool isRead;

  @HiveField(5)
  final String? type; // 'alarm', 'reminder', 'system'

  @HiveField(6)
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
