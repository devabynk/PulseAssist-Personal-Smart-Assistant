import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String color;
  final int orderIndex;
  
  // Enhanced features
  final bool isPinned;
  final bool isFullWidth;
  final List<String> imagePaths;
  final String? drawingData;
  final String? voiceNotePath;
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
