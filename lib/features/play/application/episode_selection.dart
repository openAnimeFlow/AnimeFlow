import 'package:anime_flow/features/play/domain/episodes_data.dart';
import 'package:anime_flow/features/subject_episodes/domain/subject_episodes_state.dart';
import 'package:anime_flow/shared/models/player/bangumi/episodes_item.dart';

typedef OfflineEpisode = ({
  int lineIndex,
  int episodeIndex,
  double episodeSort,
  String episodeUrl,
  int bangumiEpisodeId,
  String episodeTitle,
  String localMediaPath,
  String localDanmakuPath
});

class PlayEpisodeSelection {
  List<OfflineEpisode> _offlineEpisodes = const [];
  OfflineEpisode? offlineMediaFor(EpisodesData selected) {
    for (final file in _offlineEpisodes) {
      if (file.bangumiEpisodeId == selected.episodeId) return file;
    }
    final index = selected.episodeIndex - 1;
    return index >= 0 && index < _offlineEpisodes.length
        ? _offlineEpisodes[index]
        : null;
  }

  int? _selectedSubjectId;
  int? _selectedEpisodeId;
  int? _lastRequestedEpisodeId;
  void request(int subjectId, int? requestedEpisodeId) {
    if (_selectedSubjectId != subjectId) {
      _selectedSubjectId = null;
      _selectedEpisodeId = null;
      _lastRequestedEpisodeId = null;
    }
    if (requestedEpisodeId != null &&
        requestedEpisodeId != _lastRequestedEpisodeId) {
      _selectedSubjectId = subjectId;
      _selectedEpisodeId = requestedEpisodeId;
      _lastRequestedEpisodeId = requestedEpisodeId;
    }
  }

  EpisodesData offlineEpisodes(
      {required int subjectId,
      required Iterable<OfflineEpisode> availableEpisodes,
      required int? requestedEpisodeId,
      required String? offlineEpisodeUrl}) {
    final completedEpisodes = availableEpisodes.toList()
      ..sort(_compareOfflineEpisodes);

    _offlineEpisodes = completedEpisodes;
    if (completedEpisodes.isEmpty) {
      return EpisodesData(subjectId: subjectId);
    }

    final episodeData = <EpisodeData>[
      for (var i = 0; i < completedEpisodes.length; i++)
        _downloadEpisodeToEpisodeData(
          completedEpisodes[i],
          subjectId: subjectId,
          fallbackId: i + 1,
        ),
    ];
    final episodes = EpisodesItem(
      data: episodeData,
      total: episodeData.length,
    );
    final selectedIndex = _findOfflineEpisodeIndex(
      completedEpisodes,
      offlineEpisodeUrl: offlineEpisodeUrl,
      requestedEpisodeId: requestedEpisodeId,
    );
    final selectedEpisode = completedEpisodes[selectedIndex];
    final selectedData = episodeData[selectedIndex];

    _selectedSubjectId = subjectId;
    _selectedEpisodeId = selectedData.id;
    _lastRequestedEpisodeId = requestedEpisodeId;

    return EpisodesData(
      subjectId: subjectId,
      episodes: episodes,
      episodeTitle: _offlineEpisodeTitle(selectedEpisode),
      episodeSort: selectedEpisode.episodeSort,
      episodeIndex: selectedIndex + 1,
      episodeId: selectedData.id,
      isLoadingMore: false,
      hasMore: false,
    );
  }

  EpisodesData onlineEpisodes(
    int subjectId,
    SubjectEpisodesState subjectEpisodes,
    int? continueEpisodeId,
    EpisodesData? current,
  ) {
    final episodes = subjectEpisodes.episodes;
    final data = EpisodesData(
      subjectId: subjectId,
      episodes: episodes,
      isLoadingMore: subjectEpisodes.isLoadingMore,
      hasMore: subjectEpisodes.hasMore,
      loadMoreError: subjectEpisodes.loadMoreError,
    );
    final selectedEpisodeId =
        _selectedSubjectId == subjectId ? _selectedEpisodeId : null;

    if (episodes.data.isEmpty) {
      return data;
    }

    final selection = current != null && current.subjectId == subjectId
        ? subjectEpisodes.findSelectionById(current.episodeId) ??
            _findSelectedEpisode(
              subjectEpisodes,
              selectedEpisodeId: selectedEpisodeId,
            ) ??
            _selectionForContinueEpisode(
              subjectEpisodes,
              continueEpisodeId: continueEpisodeId,
            )
        : _findSelectedEpisode(
              subjectEpisodes,
              selectedEpisodeId: selectedEpisodeId,
            ) ??
            _selectionForContinueEpisode(
              subjectEpisodes,
              continueEpisodeId: continueEpisodeId,
            );
    if (selection == null) {
      return data;
    }

    _selectedSubjectId = subjectId;
    _selectedEpisodeId = selection.id;

    return data.copyWith(
      episodeTitle: selection.title,
      episodeSort: selection.sort,
      episodeIndex: selection.index,
      episodeId: selection.id,
    );
  }

  EpisodeSelection? _findSelectedEpisode(
    SubjectEpisodesState subjectEpisodes, {
    required int? selectedEpisodeId,
  }) {
    if (selectedEpisodeId == null) {
      return null;
    }
    return subjectEpisodes.findSelectionById(selectedEpisodeId);
  }

  EpisodeSelection? _selectionForContinueEpisode(
    SubjectEpisodesState subjectEpisodes, {
    required int? continueEpisodeId,
  }) {
    if (continueEpisodeId != null) {
      return subjectEpisodes.findSelectionById(continueEpisodeId);
    }
    return subjectEpisodes.selectionForContinueEpisode();
  }

  /// 在线模式下判断下一集是否已到播出日期，离线模式下判断本地是否有下一集。
  bool hasNextEpisode(EpisodesData? current, {required bool offline}) {
    final episodesData = current?.episodes;
    if (current == null || episodesData == null || episodesData.data.isEmpty) {
      return false;
    }
    return SubjectEpisodesState(episodes: episodesData).hasNextEpisode(
      current.episodeIndex,
      requireAired: !offline,
    );
  }

  /// 从当前播放会话的剧集列表中选集，兼容离线播放。
  EpisodesData selectEpisode(EpisodesData? current, int episodeId) {
    final episodes = current?.episodes;
    if (current == null || episodes == null) {
      throw StateError('剧集尚未加载');
    }
    final selection =
        SubjectEpisodesState(episodes: episodes).findSelectionById(episodeId);
    if (selection == null) {
      throw StateError('当前播放会话中没有可播放的该剧集');
    }
    if (current.episodeId == selection.id) return current;
    _selectedSubjectId = current.subjectId;
    _selectedEpisodeId = selection.id;
    return current.copyWith(
      episodeSort: selection.sort,
      episodeIndex: selection.index,
      episodeId: selection.id,
      episodeTitle: selection.title,
    );
  }

  /// 切换到下一集
  EpisodesData? nextEpisode(EpisodesData? current, {required bool offline}) {
    final episodesData = current?.episodes;
    if (current == null || episodesData == null || episodesData.data.isEmpty) {
      return null;
    }
    final selection = SubjectEpisodesState(episodes: episodesData)
        .nextEpisodeSelection(current.episodeIndex, requireAired: !offline);
    return selection == null ? null : selectEpisode(current, selection.id);
  }
}

int _compareOfflineEpisodes(OfflineEpisode a, OfflineEpisode b) {
  final lineComparison = a.lineIndex.compareTo(b.lineIndex);
  if (lineComparison != 0) {
    return lineComparison;
  }
  final sortComparison = a.episodeSort.compareTo(b.episodeSort);
  if (sortComparison != 0) {
    return sortComparison;
  }
  return a.episodeUrl.compareTo(b.episodeUrl);
}

EpisodeData _downloadEpisodeToEpisodeData(
  OfflineEpisode episode, {
  required int subjectId,
  required int fallbackId,
}) {
  final title = _offlineEpisodeTitle(episode);
  final id =
      episode.bangumiEpisodeId > 0 ? episode.bangumiEpisodeId : fallbackId;
  return EpisodeData(
    id: id,
    subjectID: subjectId,
    sort: episode.episodeSort,
    type: 0,
    disc: 0,
    name: title,
    nameCN: title,
    duration: '',
    airdate: '',
    comment: 0,
    desc: '',
  );
}

int _findOfflineEpisodeIndex(
  List<OfflineEpisode> episodes, {
  required String? offlineEpisodeUrl,
  required int? requestedEpisodeId,
}) {
  if (offlineEpisodeUrl != null && offlineEpisodeUrl.isNotEmpty) {
    final byUrl = episodes
        .indexWhere((episode) => episode.episodeUrl == offlineEpisodeUrl);
    if (byUrl >= 0) {
      return byUrl;
    }
  }
  if (requestedEpisodeId != null) {
    final byId = episodes.indexWhere(
      (episode) => episode.bangumiEpisodeId == requestedEpisodeId,
    );
    if (byId >= 0) {
      return byId;
    }
  }
  return 0;
}

String _offlineEpisodeTitle(OfflineEpisode episode) {
  final title = episode.episodeTitle.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return episode.episodeIndex.toString();
}
