import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/play/domain/danmaku_repository.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_module.dart';

class FlowDanmakuRepository implements DanmakuRepository {
  @override
  Future<List<Danmaku>> loadEpisode(
          {required int subjectId, required int episodeId}) =>
      FlowApi.getDanmaku(subjectId: subjectId, episodeId: episodeId);
  @override
  Future<List<Danmaku>> loadAlternative(int episodeId) =>
      FlowApi.getDanDanmakuByEpisodeID(episodeId);
  @override
  Future<void> send(int subjectId, int episodeId, Danmaku item) async {
    await FlowApi.sendDanmaku(
        subjectId: subjectId,
        episodeId: episodeId,
        message: item.message,
        time: item.time,
        type: item.type,
        color: item.color);
  }

  @override
  Future<List<Danmaku>> loadLocal(String? path) async {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) return const [];
    final file = File(trimmed);
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      final items = switch (decoded) {
        List<dynamic> value => value,
        {'data': final List<dynamic> value} => value,
        {'comments': final List<dynamic> value} => value,
        _ => const <dynamic>[],
      };
      return items
          .whereType<Map<String, dynamic>>()
          .map(Danmaku.fromJson)
          .toList();
    } catch (error) {
      LiggLogger().e('加载本地弹幕失败: $error');
      return const [];
    }
  }
}
