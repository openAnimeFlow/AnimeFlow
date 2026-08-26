import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/utils/utils.dart';
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
  static const _fileName = 'danmaku.json';

  @override
  Future<DownloadDanmakuResult?> download({
    required int subjectId,
    required DownloadEpisode episode,
  }) async {
    final directory = episode.downloadDirectory.trim();
    if (directory.isEmpty || subjectId <= 0) {
      return null;
    }

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

    await Directory(directory).create(recursive: true);
    final filePath = p.join(directory, _fileName);
    await File(filePath).writeAsString(
      jsonEncode({
        'version': 1,
        'danDanBangumiID': bangumiId,
        'comments': danmakus.map(_danmakuToJson).toList(),
      }),
    );

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
