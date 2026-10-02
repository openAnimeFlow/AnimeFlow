// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anti_crawler_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AntiCrawlerConfigAdapter extends TypeAdapter<AntiCrawlerConfig> {
  @override
  final typeId = 13;

  @override
  AntiCrawlerConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AntiCrawlerConfig(
      enabled: fields[0] as bool,
      captchaType: (fields[1] as num).toInt(),
      captchaImage: fields[2] as String,
      captchaInput: fields[3] as String,
      captchaButton: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AntiCrawlerConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.captchaType)
      ..writeByte(2)
      ..write(obj.captchaImage)
      ..writeByte(3)
      ..write(obj.captchaInput)
      ..writeByte(4)
      ..write(obj.captchaButton);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AntiCrawlerConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
