import 'package:anime_flow/features/play/domain/play_request.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/episodes_data.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';

class OfflinePlayback {
  OfflinePlayback(this.history, this.replacePlayback);
  final PlayHistoryService history;
  final Future<bool> Function(
    PlayRequest Function() resolveRequest, {
    bool Function()? shouldUseResult,
  }) replacePlayback;
  int? _selectedEpisode;
  int _revision = 0;

  Future<void> select(
      {required EpisodesData episodes,
      required String? path,
      required String? danmakuPath,
      required int subjectId,
      required String name,
      required String cover,
      required List<String> aliases}) async {
    if (episodes.episodes == null ||
        episodes.episodeIndex <= 0 ||
        _selectedEpisode == episodes.episodeId ||
        path == null ||
        path.isEmpty) {
      return;
    }
    _selectedEpisode = episodes.episodeId;
    final revision = ++_revision;
    try {
      // 历史记录按番剧保存，先读取目标剧集的进度，再保存旧剧集。
      final offset =
          await history.resumePosition(subjectId, episodes.episodeId);
      if (revision != _revision) return;
      final request = PlayRequest(
          source: PlaybackSource.localFile(path),
          offset: offset,
          subjectId: subjectId,
          subjectName: name,
          subjectCover: cover,
          episodeIndex: episodes.episodeIndex,
          episodeSort: episodes.episodeSort.toInt(),
          episodeId: episodes.episodeId,
          alias: aliases,
          localDanmakuPath: danmakuPath);
      final opened = await replacePlayback(() => request,
          shouldUseResult: () => revision == _revision);
      if (!opened && revision == _revision) _selectedEpisode = null;
    } catch (_) {
      if (revision != _revision) return;
      _selectedEpisode = null;
      rethrow;
    }
  }

  void dispose() => _revision++;
}
