// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationLogAdapter extends TypeAdapter<NotificationLog> {
  @override
  final int typeId = 6;

  @override
  NotificationLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationLog(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      timestamp: fields[3] as DateTime,
      isRead: fields[4] as bool,
      type: fields[5] as String?,
      payload: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
