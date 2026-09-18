// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawler_config_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CrawlConfigItemAdapter extends TypeAdapter<CrawlConfigItem> {
  @override
  final typeId = 12;

  @override
  CrawlConfigItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CrawlConfigItem(
      version: fields[0] as String,
      name: fields[1] as String,
      iconUrl: fields[2] as String,
      baseUrl: fields[3] as String,
      searchUrl: fields[4] as String,
      searchList: fields[5] as String,
      searchName: fields[6] as String,
      searchLink: fields[7] as String,
      lineNames: fields[8] as String,
      lineList: fields[9] as String,
      episode: fields[10] as String,
      antiCrawlerConfig: fields[11] as AntiCrawlerConfig?,
    );
  }

  @override
  void write(BinaryWriter writer, CrawlConfigItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.version)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconUrl)
      ..writeByte(3)
      ..write(obj.baseUrl)
      ..writeByte(4)
      ..write(obj.searchUrl)
      ..writeByte(5)
      ..write(obj.searchList)
      ..writeByte(6)
      ..write(obj.searchName)
      ..writeByte(7)
      ..write(obj.searchLink)
      ..writeByte(8)
      ..write(obj.lineNames)
      ..writeByte(9)
      ..write(obj.lineList)
      ..writeByte(10)
      ..write(obj.episode)
      ..writeByte(11)
      ..write(obj.antiCrawlerConfig);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrawlConfigItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
