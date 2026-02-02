import 'dart:convert';
import 'package:hive_ce/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 3)
class Note {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String color;

  @HiveField(6)
  final int orderIndex;

  // Enhanced features
  @HiveField(7)
  final bool isPinned;

  @HiveField(8)
  final bool isFullWidth;

  @HiveField(9)
  final List<String> imagePaths;

  @HiveField(10)
  final String? drawingData;

  @HiveField(11)
  final String? voiceNotePath;

  @HiveField(12)
  final List<String> tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.color = '#FFB74D',
    this.orderIndex = 0,
    this.isPinned = false,
    this.isFullWidth = false,
    this.imagePaths = const [],
    this.drawingData,
    this.voiceNotePath,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
      'orderIndex': orderIndex,
      'isPinned': isPinned ? 1 : 0,
      'isFullWidth': isFullWidth ? 1 : 0,
      'imagePaths': jsonEncode(imagePaths),
      'drawingData': drawingData,
      'voiceNotePath': voiceNotePath,
      'tags': jsonEncode(tags),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      color: map['color'] ?? '#FFB74D',
      orderIndex: map['orderIndex'] ?? 0,
      isPinned: (map['isPinned'] ?? 0) == 1,
      isFullWidth: (map['isFullWidth'] ?? 0) == 1,
      imagePaths: map['imagePaths'] != null
          ? List<String>.from(jsonDecode(map['imagePaths']))
          : [],
      drawingData: map['drawingData'],
      voiceNotePath: map['voiceNotePath'],
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : [],
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    int? orderIndex,
    bool? isPinned,
    bool? isFullWidth,
    List<String>? imagePaths,
    String? drawingData,
    String? voiceNotePath,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      orderIndex: orderIndex ?? this.orderIndex,
      isPinned: isPinned ?? this.isPinned,
      isFullWidth: isFullWidth ?? this.isFullWidth,
      imagePaths: imagePaths ?? this.imagePaths,
      drawingData: drawingData ?? this.drawingData,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      tags: tags ?? this.tags,
    );
  }
}
