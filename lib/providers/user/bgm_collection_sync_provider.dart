import 'dart:async';

import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgm_collection_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class BgmCollectionSync extends _$BgmCollectionSync {
  Timer? _pollTimer;

  @override
  Future<BgmCollectionSyncStatusItem?> build() async {
    ref.onDispose(_stopPolling);

    final bind = await ref.watch(bangumiBindProvider.future);
    if (bind?.bound != true) {
      return null;
    }

    final status = await FlowRequest.getBgmCollectionSyncStatusService();
    _ensurePolling(status);
    return status;
  }

  Future<void> triggerSync({int subjectType = 2}) async {
    final status = await FlowRequest.triggerBgmCollectionSyncService(
      subjectType: subjectType,
    );
    state = AsyncData(status);
    _ensurePolling(status);
  }

  Future<void> refreshStatus() async {
    final bind = await ref.read(bangumiBindProvider.future);
    if (bind?.bound != true) {
      state = const AsyncData(null);
      _stopPolling();
      return;
    }

    final status = await FlowRequest.getBgmCollectionSyncStatusService();
    state = AsyncData(status);
    _ensurePolling(status);
  }

  void _ensurePolling(BgmCollectionSyncStatusItem? status) {
    _stopPolling();
    if (status == null || !status.isRunning) {
      return;
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      refreshStatus();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
