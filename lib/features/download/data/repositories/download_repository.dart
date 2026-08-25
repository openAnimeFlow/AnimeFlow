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

  @override
  List<DownloadRecord> getAllRecords() {
    final records = _storage.values.toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  DownloadRecord? getRecord(String key) {
    return _storage.get(key);
  }

  @override
  Future<void> putRecord(DownloadRecord record) async {
    await _storage.put(record.key, record);
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

    record.episodes = Map<String, DownloadEpisode>.from(record.episodes)
      ..[episodeUrl] = episode;
    await _storage.put(recordKey, record);
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
      return;
    }

    record.episodes = episodes;
    await _storage.put(recordKey, record);
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
}
