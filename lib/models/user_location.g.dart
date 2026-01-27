// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserLocationAdapter extends TypeAdapter<UserLocation> {
  @override
  final int typeId = 8;

  @override
  UserLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserLocation(
      cityName: fields[0] as String,
      country: fields[1] as String,
      state: fields[2] as String?,
      district: fields[3] as String?,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      lastUpdated: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserLocation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.cityName)
      ..writeByte(1)
      ..write(obj.country)
      ..writeByte(2)
      ..write(obj.state)
      ..writeByte(3)
      ..write(obj.district)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
