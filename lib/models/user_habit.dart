class UserHabit {
  final String id;
  final String intent; // e.g., 'alarm', 'reminder'
  final String parameters; // JSON string
  final int frequency;
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
