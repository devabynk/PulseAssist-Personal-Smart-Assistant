import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 2)
class Alarm {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime time;

  @HiveField(3)
  final bool isActive;

  @HiveField(4)
  final List<int> repeatDays; // 0=Sunday, 1=Monday, ... 6=Saturday

  @HiveField(5)
  final List<DateTime> skippedDates; // Dates where the alarm instance was skipped

  @HiveField(6)
  final String? soundPath; // Path to the alarm sound (asset or file)

  @HiveField(7)
  final String? soundName; // Display name of the sound

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isActive = true,
    this.repeatDays = const [],
    this.skippedDates = const [],
    this.soundPath, // optional
    this.soundName, // optional
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'repeatDays': repeatDays.join(','),
      'skippedDates': skippedDates.map((d) => d.toIso8601String()).join(','),
      'soundPath': soundPath,
      'soundName': soundName,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      title: map['title'],
      time: DateTime.parse(map['time']),
      isActive: map['isActive'] == 1,
      repeatDays: map['repeatDays'].toString().isEmpty 
          ? [] 
          : map['repeatDays'].toString().split(',').map((e) => int.parse(e)).toList(),
      skippedDates: (map['skippedDates'] == null || map['skippedDates'].toString().isEmpty)
          ? []
          : map['skippedDates'].toString().split(',').map((e) => DateTime.parse(e)).toList(),
      soundPath: map['soundPath'],
      soundName: map['soundName'],
    );
  }

  Alarm copyWith({
    String? id,
    String? title,
    DateTime? time,
    bool? isActive,
    List<int>? repeatDays,
    List<DateTime>? skippedDates,
    String? soundPath,
    String? soundName,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      isActive: isActive ?? this.isActive,
      repeatDays: repeatDays ?? this.repeatDays,
      skippedDates: skippedDates ?? this.skippedDates,
      soundPath: soundPath ?? this.soundPath,
      soundName: soundName ?? this.soundName,
    );
  }
}
