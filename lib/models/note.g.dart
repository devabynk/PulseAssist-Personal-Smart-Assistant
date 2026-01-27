// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 3;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      color: fields[5] as String,
      orderIndex: fields[6] as int,
      isPinned: fields[7] as bool,
      isFullWidth: fields[8] as bool,
      imagePaths: (fields[9] as List).cast<String>(),
      drawingData: fields[10] as String?,
      voiceNotePath: fields[11] as String?,
      tags: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.orderIndex)
      ..writeByte(7)
      ..write(obj.isPinned)
      ..writeByte(8)
      ..write(obj.isFullWidth)
      ..writeByte(9)
      ..write(obj.imagePaths)
      ..writeByte(10)
      ..write(obj.drawingData)
      ..writeByte(11)
      ..write(obj.voiceNotePath)
      ..writeByte(12)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
