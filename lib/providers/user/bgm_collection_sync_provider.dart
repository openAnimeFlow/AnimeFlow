import 'dart:async';

import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/models/item/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgm_collection_sync_provider.g.dart';

@Riverpod(keepAlive: true)
class BgmCollectionSync extends _$BgmCollectionSync {
  Timer? _pollTimer;
  bool _refreshInFlight = false;

  @override
  Future<BgmCollectionSyncStatusItem?> build() async {
    ref.onDispose(_stopPolling);

    final bind = await ref.watch(bangumiBindProvider.future);
    if (bind?.bound != true) {
      return null;
    }

    final status = await FlowApi.getBgmCollectionSyncStatusService();
    _ensurePolling(status);
    return status;
  }

  Future<void> triggerSync({int subjectType = 2}) async {
    final status = await FlowApi.triggerBgmCollectionSyncService(
      subjectType: subjectType,
    );
    state = AsyncData(status);
    _ensurePolling(status);
  }

  Future<void> refreshStatus() async {
    if (_refreshInFlight) {
      return;
    }
    _refreshInFlight = true;
    try {
      final bind = await ref.read(bangumiBindProvider.future);
      if (bind?.bound != true) {
        state = const AsyncData(null);
        _stopPolling();
        return;
      }

      final previous = state.value;
      final status = await FlowApi.getBgmCollectionSyncStatusService();
      state = AsyncData(status);
      if (previous?.isRunning == true &&
          status.status == BgmCollectionSyncStatus.success) {
        ref.invalidate(currentUserInfoProvider);
      }
      _ensurePolling(status);
    } finally {
      _refreshInFlight = false;
    }
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
