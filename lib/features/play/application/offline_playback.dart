import 'package:anime_flow/features/play/domain/play_request.dart';
import 'package:anime_flow/features/play/domain/episodes_data.dart';
import 'package:anime_flow/features/play/application/play_history_service.dart';

class OfflinePlayback {
  OfflinePlayback(this.history, this.open);
  final PlayHistoryService history;
  final Future<void> Function(PlayRequest) open;
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
      final offset =
          await history.resumePosition(subjectId, episodes.episodeId);
      if (revision != _revision) return;
      await open(PlayRequest(
          videoUrl: path,
          offset: offset,
          subjectId: subjectId,
          subjectName: name,
          subjectCover: cover,
          episodeIndex: episodes.episodeIndex,
          episodeSort: episodes.episodeSort.toInt(),
          episodeId: episodes.episodeId,
          alias: aliases,
          localDanmakuPath: danmakuPath,
          isLocalPlayback: true));
    } catch (_) {
      if (revision != _revision) return;
      _selectedEpisode = null;
      rethrow;
    }
  }

  void dispose() => _revision++;
}
