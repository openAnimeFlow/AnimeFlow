import 'package:anime_flow/core/storage/storage.dart';
import 'package:anime_flow/shared/models/download/download_episode.dart';
import 'package:anime_flow/shared/models/download/download_record.dart';
import 'package:anime_flow/shared/models/download/download_status.dart';
import 'package:hive_ce/hive.dart';

abstract interface class IDownloadRepository {
  List<DownloadRecord> getAllRecords();

  DownloadRecord? getRecord(String key);

  Future<void> putRecord(DownloadRecord record);

  Future<void> updateEpisode(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode,
  );

  Future<void> deleteEpisode(String recordKey, String episodeUrl);

  List<DownloadEpisode> getCompletedEpisodes(
    int subjectId,
    String sourceName,
  );

  DownloadEpisode? getEpisode(
    int subjectId,
    String sourceName,
    String episodeUrl,
  );
}

class DownloadRepository implements IDownloadRepository {
  DownloadRepository({Box<DownloadRecord>? storage})
      : _storage = storage ?? Storage.downloads;

  final Box<DownloadRecord> _storage;
  final Map<String, Map<String, DownloadEpisode>> _progressCache = {};
  final Map<String, int> _lastPersistedStatus = {};

  @override
  List<DownloadRecord> getAllRecords() {
    final records = _storage.values.toList();
    for (final record in records) {
      _mergeProgressCache(record);
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  DownloadRecord? getRecord(String key) {
    final record = _storage.get(key);
    if (record != null) {
      _mergeProgressCache(record);
    }
    return record;
  }

  @override
  Future<void> putRecord(DownloadRecord record) async {
    await _storage.put(record.key, record);
    for (final entry in record.episodes.entries) {
      _lastPersistedStatus[_statusKey(record.key, entry.key)] =
          entry.value.status;
    }
  }

  @override
  Future<void> updateEpisode(
    String recordKey,
    String episodeUrl,
    DownloadEpisode episode,
  ) async {
    final record = getRecord(recordKey);
    if (record == null) {
      return;
    }

    _progressCache.putIfAbsent(recordKey, () => {})[episodeUrl] = episode;
    final statusKey = _statusKey(recordKey, episodeUrl);
    final lastStatus = _lastPersistedStatus[statusKey];
    if (lastStatus == episode.status) {
      return;
    }

    record.episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..[episodeUrl] = episode;
    await _storage.put(recordKey, record);
    _lastPersistedStatus[statusKey] = episode.status;
  }

  @override
  Future<void> deleteEpisode(String recordKey, String episodeUrl) async {
    final record = getRecord(recordKey);
    if (record == null) {
      return;
    }

    final episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..remove(episodeUrl);
    if (episodes.isEmpty) {
      await _storage.delete(recordKey);
      _progressCache.remove(recordKey);
      _lastPersistedStatus.removeWhere((key, _) {
        return key.startsWith('$recordKey|');
      });
      return;
    }

    record.episodes = episodes;
    await _storage.put(recordKey, record);
    _progressCache[recordKey]?.remove(episodeUrl);
    _lastPersistedStatus.remove(_statusKey(recordKey, episodeUrl));
  }

  @override
  List<DownloadEpisode> getCompletedEpisodes(
    int subjectId,
    String sourceName,
  ) {
    final record = getRecord(
      DownloadRecord.buildKey(sourceName: sourceName, subjectId: subjectId),
    );
    if (record == null) {
      return const [];
    }

    final episodes = record.episodes.values
        .where((episode) => episode.status == DownloadStatus.completed)
        .toList();
    episodes.sort((a, b) {
      final lineCompare = a.lineIndex.compareTo(b.lineIndex);
      if (lineCompare != 0) {
        return lineCompare;
      }
      return a.episodeSort.compareTo(b.episodeSort);
    });
    return episodes;
  }

  @override
  DownloadEpisode? getEpisode(
    int subjectId,
    String sourceName,
    String episodeUrl,
  ) {
    final record = getRecord(
      DownloadRecord.buildKey(sourceName: sourceName, subjectId: subjectId),
    );
    return record?.episodes[episodeUrl];
  }

  void _mergeProgressCache(DownloadRecord record) {
    final cachedEpisodes = _progressCache[record.key];
    if (cachedEpisodes == null || cachedEpisodes.isEmpty) {
      return;
    }
    record.episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..addAll(cachedEpisodes);
  }

  String _statusKey(String recordKey, String episodeUrl) {
    return '$recordKey|$episodeUrl';
  }
}
