// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadRecordAdapter extends TypeAdapter<DownloadRecord> {
  @override
  final typeId = 10;

  @override
  DownloadRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadRecord(
      subjectId: (fields[0] as num).toInt(),
      subjectName: fields[1] as String,
      subjectCover: fields[2] as String,
      sourceName: fields[3] as String,
      sourceBaseUrl: fields[4] as String,
      episodes: (fields[5] as Map).cast<String, DownloadEpisode>(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.subjectId)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.subjectCover)
      ..writeByte(3)
      ..write(obj.sourceName)
      ..writeByte(4)
      ..write(obj.sourceBaseUrl)
      ..writeByte(5)
      ..write(obj.episodes)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
