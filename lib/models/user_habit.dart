import 'package:hive_ce/hive.dart';

part 'user_habit.g.dart';

@HiveType(typeId: 7)
class UserHabit {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String intent; // e.g., 'alarm', 'reminder'

  @HiveField(2)
  final String parameters; // JSON string

  @HiveField(3)
  final int frequency;

  @HiveField(4)
  final DateTime lastUsed;

  UserHabit({
    required this.id,
    required this.intent,
    required this.parameters,
    required this.frequency,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intent': intent,
      'parameters': parameters,
      'frequency': frequency,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory UserHabit.fromMap(Map<String, dynamic> map) {
    return UserHabit(
      id: map['id'],
      intent: map['intent'],
      parameters: map['parameters'],
      frequency: map['frequency'],
      lastUsed: DateTime.parse(map['lastUsed']),
    );
  }
}
