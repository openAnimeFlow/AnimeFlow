import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown server status is not mistaken for idle', () {
    expect(BgmCollectionSyncStatus.fromJson('FUTURE_STATE'),
        BgmCollectionSyncStatus.unknown);
    expect(
        BgmCollectionSyncStatus.fromJson('IDLE'), BgmCollectionSyncStatus.idle);
  });
  test('后台可恢复或等待决议的任务继续刷新，终态停止刷新', () {
    for (final status in BgmCollectionSyncStatus.values) {
      final item = BgmCollectionSyncStatusItem(status: status);
      expect(
          item.shouldPoll,
          {
            BgmCollectionSyncStatus.queued,
            BgmCollectionSyncStatus.running,
            BgmCollectionSyncStatus.partialFailed,
            BgmCollectionSyncStatus.waitingConflict,
          }.contains(status),
          reason: status.name);
    }
  });

  test('失败状态仍保留任务和冲突数量，且不禁用手动重试', () {
    final item = BgmCollectionSyncStatusItem.fromJson({
      'status': 'PARTIAL_FAILED',
      'taskId': 2,
      'pendingConflictCount': 3,
    });
    expect(item.shouldPoll, isTrue);
    expect(item.isRunning, isFalse);
    expect(item.taskId, 2);
    expect(item.pendingConflictCount, 3);
  });
}
