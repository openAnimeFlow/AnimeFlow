import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown server status is not mistaken for idle', () {
    expect(BgmCollectionSyncStatus.fromJson('FUTURE_STATE'),
        BgmCollectionSyncStatus.unknown);
    expect(
        BgmCollectionSyncStatus.fromJson('IDLE'), BgmCollectionSyncStatus.idle);
  });
  test('部分失败状态仍保留任务和待处理冲突数量', () {
    final item = BgmCollectionSyncStatusItem.fromJson({
      'status': 'PARTIAL_FAILED',
      'taskId': 2,
      'pendingConflictCount': 3,
    });
    expect(item.isRunning, isFalse);
    expect(item.taskId, 2);
    expect(item.pendingConflictCount, 3);
  });

  test('旧同步进度字段缺失时扫描计数默认为零', () {
    final item = BgmCollectionSyncStatusItem.fromJson({
      'status': 'RUNNING',
      'phase': 'SCANNING',
    });
    expect(item.scannedCount, 0);
  });
}
