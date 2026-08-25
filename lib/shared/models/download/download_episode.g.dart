// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_episode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadEpisodeAdapter extends TypeAdapter<DownloadEpisode> {
  @override
  final typeId = 11;

  @override
  DownloadEpisode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadEpisode(
      episodeUrl: fields[0] as String,
      bangumiEpisodeId: (fields[1] as num).toInt(),
      episodeSort: (fields[2] as num).toDouble(),
      episodeIndex: (fields[3] as num).toInt(),
      episodeTitle: fields[4] as String,
      lineIndex: (fields[5] as num).toInt(),
      sourceName: fields[6] as String,
      status: (fields[7] as num).toInt(),
      progressPercent: fields[8] == null ? 0 : (fields[8] as num).toDouble(),
      totalSegments: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      downloadedSegments: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      totalBytes: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      networkMediaUrl: fields[12] == null ? '' : fields[12] as String,
      localMediaPath: fields[13] == null ? '' : fields[13] as String,
      mediaType: fields[14] == null ? '' : fields[14] as String,
      downloadDirectory: fields[15] == null ? '' : fields[15] as String,
      completedAt: fields[16] as DateTime?,
      errorMessage: fields[17] == null ? '' : fields[17] as String,
      danmakuDownloaded: fields[18] == null ? false : fields[18] as bool,
      localDanmakuPath: fields[19] == null ? '' : fields[19] as String,
      danDanBangumiID: fields[20] == null ? 0 : (fields[20] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DownloadEpisode obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.episodeUrl)
      ..writeByte(1)
      ..write(obj.bangumiEpisodeId)
      ..writeByte(2)
      ..write(obj.episodeSort)
      ..writeByte(3)
      ..write(obj.episodeIndex)
      ..writeByte(4)
      ..write(obj.episodeTitle)
      ..writeByte(5)
      ..write(obj.lineIndex)
      ..writeByte(6)
      ..write(obj.sourceName)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.progressPercent)
      ..writeByte(9)
      ..write(obj.totalSegments)
      ..writeByte(10)
      ..write(obj.downloadedSegments)
      ..writeByte(11)
      ..write(obj.totalBytes)
      ..writeByte(12)
      ..write(obj.networkMediaUrl)
      ..writeByte(13)
      ..write(obj.localMediaPath)
      ..writeByte(14)
      ..write(obj.mediaType)
      ..writeByte(15)
      ..write(obj.downloadDirectory)
      ..writeByte(16)
      ..write(obj.completedAt)
      ..writeByte(17)
      ..write(obj.errorMessage)
      ..writeByte(18)
      ..write(obj.danmakuDownloaded)
      ..writeByte(19)
      ..write(obj.localDanmakuPath)
      ..writeByte(20)
      ..write(obj.danDanBangumiID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadEpisodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
