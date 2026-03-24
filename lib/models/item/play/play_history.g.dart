// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayHistoryAdapter extends TypeAdapter<PlayHistory> {
  @override
  final typeId = 2;

  @override
  PlayHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayHistory(
      subjectId: (fields[0] as num).toInt(),
      episodeId: (fields[1] as num).toInt(),
      episodeSort: (fields[2] as num).toInt(),
      subjectName: fields[3] as String,
      cover: fields[4] as String,
      updateAt: fields[5] as DateTime,
      position: (fields[6] as num).toInt(),
      duration: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.subjectId)
      ..writeByte(1)
      ..write(obj.episodeId)
      ..writeByte(2)
      ..write(obj.episodeSort)
      ..writeByte(3)
      ..write(obj.subjectName)
      ..writeByte(4)
      ..write(obj.cover)
      ..writeByte(5)
      ..write(obj.updateAt)
      ..writeByte(6)
      ..write(obj.position)
      ..writeByte(7)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
