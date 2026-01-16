// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayHistoryAdapter extends TypeAdapter<PlayHistory> {
  @override
  final typeId = 1;

  @override
  PlayHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final playIdValue = fields[0];
    final playId = playIdValue is int 
        ? playIdValue.toString() 
        : playIdValue as String;
    return PlayHistory(
      playId: playId,
      position: fields[1] as int,
      duration: fields[2] as int,
      updateAt: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.playId)
      ..writeByte(1)
      ..write(obj.position)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.updateAt);
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
