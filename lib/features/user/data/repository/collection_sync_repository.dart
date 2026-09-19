import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/shared/models/flow/collection_conflict_item.dart';

final collectionSyncRepositoryProvider =
    Provider((ref) => CollectionSyncRepository());

class CollectionSyncRepository {
  Future<BgmCollectionSyncStatusItem> status() =>
      FlowApi.getBgmCollectionSyncStatusService();
  Future<BgmCollectionSyncStatusItem> trigger(
          int subjectType, String requestId) =>
      FlowApi.triggerBgmCollectionSyncService(
          subjectType: subjectType, requestId: requestId);
  Future<List<CollectionConflictItem>> conflicts(
          int taskId, int offset, int limit) =>
      FlowApi.getCollectionConflictsService(
          taskId: taskId, offset: offset, limit: limit);
  Future<BgmCollectionSyncStatusItem> resolve(
          int taskId, List<Map<String, dynamic>> items) =>
      FlowApi.resolveCollectionConflictsService(taskId: taskId, items: items);
}
