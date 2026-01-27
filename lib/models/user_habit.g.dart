// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHabitAdapter extends TypeAdapter<UserHabit> {
  @override
  final int typeId = 7;

  @override
  UserHabit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHabit(
      id: fields[0] as String,
      intent: fields[1] as String,
      parameters: fields[2] as String,
      frequency: fields[3] as int,
      lastUsed: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserHabit obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.intent)
      ..writeByte(2)
      ..write(obj.parameters)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.lastUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
