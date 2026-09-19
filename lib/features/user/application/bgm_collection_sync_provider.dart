import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'dart:async';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgm_collection_sync_provider.g.dart';

// Page leases survive notifier rebuilds caused by login/binding changes.
final collectionSyncPollingOwnersProvider =
    Provider<Set<Object>>((ref) => <Object>{});

@Riverpod(keepAlive: true)
class BgmCollectionSync extends _$BgmCollectionSync {
  Timer? _pollTimer;
  Future<void>? _refresh;
  Object _generation = Object();
  bool _foreground = true;

  bool _current(Object generation) =>
      ref.mounted && identical(generation, _generation);

  @override
  Future<BgmCollectionSyncStatusItem?> build() async {
    _stopPolling();
    final generation = _generation = Object();
    _refresh = null;
    ref.onDispose(() {
      _generation = Object();
      _stopPolling();
    });
    final token = await ref.watch(currentFlowTokenProvider.future);
    if (!_current(generation) || token == null) return null;
    final bind = await ref.watch(bangumiBindProvider.future);
    if (!_current(generation) || bind?.bound != true) return null;
    final status = await ref.read(collectionSyncRepositoryProvider).status();
    if (!_current(generation)) return null;
    _ensurePolling(status);
    if (status.syncedCount > 0) {
      scheduleMicrotask(() {
        if (_current(generation)) _refreshCollections();
      });
    }
    return status;
  }

  Future<void> triggerSync({int subjectType = 2}) async {
    final generation = _generation;
    final status = await ref.read(collectionSyncRepositoryProvider).trigger(
        subjectType, 'desktop-${DateTime.now().microsecondsSinceEpoch}');
    if (!_current(generation)) return;
    _accept(status);
  }

  Future<void> refreshStatus() {
    if (_refresh != null) return _refresh!;
    final generation = _generation;
    final future = _loadStatus(generation);
    _refresh = future;
    return future.whenComplete(() {
      if (_current(generation)) _refresh = null;
    });
  }

  Future<void> _loadStatus(Object generation) async {
    final bind = await ref.read(bangumiBindProvider.future);
    if (!_current(generation)) return;
    if (bind?.bound != true) {
      state = const AsyncData(null);
      _stopPolling();
      return;
    }
    final status = await ref.read(collectionSyncRepositoryProvider).status();
    if (_current(generation)) _accept(status);
  }

  void _accept(BgmCollectionSyncStatusItem status) {
    final previous = state.value;
    state = AsyncData(status);
    if (status.syncedCount > 0 &&
        (previous?.taskId != status.taskId ||
            previous?.syncedCount != status.syncedCount ||
            (previous?.status != status.status &&
                status.status == BgmCollectionSyncStatus.success))) {
      _refreshCollections();
    }
    _ensurePolling(status);
  }

  void _refreshCollections() {
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(userCollectionsProvider);
    ref.read(collectionRevisionProvider.notifier).changed();
  }

  void setPagePolling(Object owner, bool enabled) {
    final owners = ref.read(collectionSyncPollingOwnersProvider);
    if (enabled) {
      owners.add(owner);
    } else {
      owners.remove(owner);
    }
    _ensurePolling(state.value);
  }

  void setForeground(bool value) {
    _foreground = value;
    if (!value) {
      _stopPolling();
    } else {
      _ensurePolling(state.value);
    }
  }

  void _ensurePolling(BgmCollectionSyncStatusItem? status) {
    _stopPolling();
    if (!_foreground ||
        ref.read(collectionSyncPollingOwnersProvider).isEmpty ||
        status == null ||
        !status.shouldPoll) {
      return;
    }
    _pollTimer =
        Timer.periodic(Duration(seconds: status.isRunning ? 2 : 10), (_) async {
      try {
        await refreshStatus();
      } catch (_) {/* Retain state and retry next tick. */}
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
