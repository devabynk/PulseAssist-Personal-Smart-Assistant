import 'dart:convert';
import 'package:hive_ce/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 5)
class Subtask {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool isCompleted;

  Subtask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'isCompleted': isCompleted};
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Subtask copyWith({String? id, String? title, bool? isCompleted}) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@HiveType(typeId: 4)
class Reminder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String priority; // low, medium, high, urgent

  @HiveField(6)
  final int orderIndex;

  @HiveField(7)
  final bool isPinned;

  @HiveField(8)
  final String? voiceNotePath;

  @HiveField(9)
  final List<Subtask> subtasks;

  Reminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    this.isCompleted = false,
    this.priority = 'medium',
    this.orderIndex = 0,
    this.isPinned = false,
    this.voiceNotePath,
    this.subtasks = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'orderIndex': orderIndex,
      'isPinned': isPinned ? 1 : 0,
      'voiceNotePath': voiceNotePath,
      'subtasks': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    var subtasksList = <Subtask>[];
    if (map['subtasks'] != null && map['subtasks'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['subtasks']);
        if (decoded is List) {
          subtasksList = decoded.map((s) => Subtask.fromMap(s)).toList();
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Reminder(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      isCompleted: map['isCompleted'] == 1,
      priority: map['priority'] ?? 'medium',
      orderIndex: map['orderIndex'] ?? 0,
      isPinned: map['isPinned'] == 1,
      voiceNotePath: map['voiceNotePath'],
      subtasks: subtasksList,
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? isCompleted,
    String? priority,
    int? orderIndex,
    bool? isPinned,
    String? voiceNotePath,
    List<Subtask>? subtasks,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      orderIndex: orderIndex ?? this.orderIndex,
      isPinned: isPinned ?? this.isPinned,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;
  int get totalSubtasksCount => subtasks.length;
  double get subtasksProgress => totalSubtasksCount > 0
      ? completedSubtasksCount / totalSubtasksCount
      : 0.0;
}
