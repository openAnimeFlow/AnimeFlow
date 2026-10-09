import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/features/download/application/download_directory/download_directory_platform.dart';
import 'package:anime_flow/features/download/application/download_directory/restore_download_directory_access.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';
import 'package:path/path.dart' as p;

class DownloadDanmakuResult {
  const DownloadDanmakuResult({
    required this.danDanBangumiId,
    required this.localPath,
    required this.hasDanmaku,
  });

  final int danDanBangumiId;
  final String localPath;
  final bool hasDanmaku;
}

abstract interface class IDownloadDanmakuService {
  Future<DownloadDanmakuResult?> download({
    required int subjectId,
    required DownloadEpisode episode,
  });
}

class DownloadDanmakuService implements IDownloadDanmakuService {
  DownloadDanmakuService({DownloadDirectoryPlatform? directoryPlatform})
      : _directoryPlatform =
            directoryPlatform ?? DownloadDirectoryPlatformFactory.create();

  final DownloadDirectoryPlatform _directoryPlatform;
  static const _fileName = 'danmaku.json';

  @override
  Future<DownloadDanmakuResult?> download({
    required int subjectId,
    required DownloadEpisode episode,
  }) async {
    final recordedDirectory = episode.downloadDirectory.trim();
    if (recordedDirectory.isEmpty || subjectId <= 0) {
      return null;
    }
    final directory =
        await _directoryPlatform.requireWritableDirectory(recordedDirectory);
    episode
      ..downloadDirectory = directory
      ..localMediaPath = remapDownloadPath(
        episode.localMediaPath,
        {recordedDirectory: directory},
      )
      ..localDanmakuPath = remapDownloadPath(
        episode.localDanmakuPath,
        {recordedDirectory: directory},
      );

    final bangumiId = await FlowApi.getDanDanBangumiIDByBgmBangumiID(subjectId);
    if (bangumiId == null || bangumiId <= 0) {
      return null;
    }

    final danmakus = await FlowApi.getDanDanmaku(
      bangumiId,
      _episodeNumber(episode),
    );
    if (danmakus.isEmpty) {
      return DownloadDanmakuResult(
        danDanBangumiId: bangumiId,
        localPath: '',
        hasDanmaku: false,
      );
    }

    final filePath = p.join(directory, _fileName);
    Directory? staging;
    try {
      // A failed retry must not truncate an existing offline danmaku cache.
      staging = await Directory(directory).createTemp('.anime_flow_danmaku_');
      final pendingFile = File(p.join(staging.path, _fileName));
      await pendingFile.writeAsString(
        jsonEncode({
          'version': 1,
          'danDanBangumiID': bangumiId,
          'comments': danmakus.map(_danmakuToJson).toList(),
        }),
        flush: true,
      );
      await pendingFile.rename(filePath);
    } on FileSystemException {
      throw const DownloadDirectoryNotWritableException();
    } finally {
      if (staging != null) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          // A revoked grant or disconnected disk can also prevent cleanup.
        }
      }
    }

    return DownloadDanmakuResult(
      danDanBangumiId: bangumiId,
      localPath: filePath,
      hasDanmaku: true,
    );
  }

  int _episodeNumber(DownloadEpisode episode) {
    if (episode.episodeIndex > 0) {
      return episode.episodeIndex;
    }
    return episode.episodeSort.toInt();
  }

  Map<String, String> _danmakuToJson(Danmaku danmaku) {
    final parts = [
      danmaku.time.toStringAsFixed(2),
      danmaku.type.toString(),
      Utils.colorToDecimalRgb(danmaku.color).toString(),
      danmaku.source,
      if (danmaku.bgmUserId != null) danmaku.bgmUserId.toString(),
    ];
    return {
      'm': danmaku.message,
      'p': parts.join(','),
    };
  }
}
