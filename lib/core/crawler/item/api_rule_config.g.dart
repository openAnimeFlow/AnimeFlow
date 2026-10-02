// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_rule_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiRequestConfigAdapter extends TypeAdapter<ApiRequestConfig> {
  @override
  final typeId = 14;

  @override
  ApiRequestConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiRequestConfig(
      method: fields[0] as String?,
      url: fields[1] as String?,
      headers: (fields[2] as Map?)?.cast<String, dynamic>(),
      query: (fields[3] as Map?)?.cast<String, dynamic>(),
      bodyType: fields[4] as String?,
      body: fields[5] as dynamic,
    );
  }

  @override
  void write(BinaryWriter writer, ApiRequestConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.headers)
      ..writeByte(3)
      ..write(obj.query)
      ..writeByte(4)
      ..write(obj.bodyType)
      ..writeByte(5)
      ..write(obj.body);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRequestConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ApiSearchConfigAdapter extends TypeAdapter<ApiSearchConfig> {
  @override
  final typeId = 15;

  @override
  ApiSearchConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiSearchConfig(
      request: fields[0] as ApiRequestConfig?,
      listPath: fields[1] as String?,
      namePath: fields[2] as String?,
      sourcePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiSearchConfig obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.request)
      ..writeByte(1)
      ..write(obj.listPath)
      ..writeByte(2)
      ..write(obj.namePath)
      ..writeByte(3)
      ..write(obj.sourcePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSearchConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ApiEpisodePageConfigAdapter extends TypeAdapter<ApiEpisodePageConfig> {
  @override
  final typeId = 16;

  @override
  ApiEpisodePageConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiEpisodePageConfig(
      url: fields[0] as String?,
      query: (fields[1] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ApiEpisodePageConfig obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.query);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiEpisodePageConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ApiChapterConfigAdapter extends TypeAdapter<ApiChapterConfig> {
  @override
  final typeId = 17;

  @override
  ApiChapterConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiChapterConfig(
      request: fields[0] as ApiRequestConfig?,
      format: fields[1] as String?,
      roadsPath: fields[2] as String?,
      roadNamePath: fields[3] as String?,
      episodesPath: fields[4] as String?,
      episodeNamePath: fields[5] as String?,
      episodeUrlPath: fields[6] as String?,
      roadNamesPath: fields[7] as String?,
      roadEpisodesPath: fields[8] as String?,
      roadSeparator: fields[9] as String?,
      episodeSeparator: fields[10] as String?,
      fieldSeparator: fields[11] as String?,
      variables: (fields[12] as Map?)?.cast<String, String>(),
      episodePage: fields[13] as ApiEpisodePageConfig?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiChapterConfig obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.request)
      ..writeByte(1)
      ..write(obj.format)
      ..writeByte(2)
      ..write(obj.roadsPath)
      ..writeByte(3)
      ..write(obj.roadNamePath)
      ..writeByte(4)
      ..write(obj.episodesPath)
      ..writeByte(5)
      ..write(obj.episodeNamePath)
      ..writeByte(6)
      ..write(obj.episodeUrlPath)
      ..writeByte(7)
      ..write(obj.roadNamesPath)
      ..writeByte(8)
      ..write(obj.roadEpisodesPath)
      ..writeByte(9)
      ..write(obj.roadSeparator)
      ..writeByte(10)
      ..write(obj.episodeSeparator)
      ..writeByte(11)
      ..write(obj.fieldSeparator)
      ..writeByte(12)
      ..write(obj.variables)
      ..writeByte(13)
      ..write(obj.episodePage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiChapterConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
