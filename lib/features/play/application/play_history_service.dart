import 'package:anime_flow/core/async/serial_operation_queue.dart';
import 'package:anime_flow/features/play/domain/play_history_repository.dart';

class PlayHistoryService {
  PlayHistoryService(this.repository);
  final PlayHistoryRepository repository;

  final _queue = SerialOperationQueue(ensureReady: () {});
  Future<void>? _synchronizing;
  Future<PlayHistorySyncResult> syncPending() =>
      _queue.run(repository.syncPending);
  Future<void> clearLocal() => _queue.run(repository.clearLocal);
  Future<List<PlaybackRecord>> records() async => (await repository.getAll())
    ..sort((a, b) => b.updateAt.compareTo(a.updateAt));
  Stream<void> get changes => repository.changes;

  Future<int> resumePosition(int subjectId, int episodeId) async {
    final record = await repository.getBySubjectId(subjectId);
    return record != null &&
            record.episodeId == episodeId &&
            record.position > 0
        ? record.position
        : 0;
  }

  Future<void> synchronize({required bool Function() active}) =>
      _synchronizing ??= _queue
          .run(() => _synchronize(active))
          .whenComplete(() => _synchronizing = null);

  Future<void> _synchronize(bool Function() active) async {
    for (var attempt = 1; attempt <= 3 && active(); attempt++) {
      try {
        await repository.syncPending();
        if (active()) await repository.syncFromServer();
        return;
      } catch (_) {
        if (!active()) return;
        if (attempt == 3) rethrow;
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }
}
