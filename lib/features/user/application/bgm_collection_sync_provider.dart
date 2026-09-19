import 'package:anime_flow/core/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'dart:async';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_collection_provider.dart';
import 'package:anime_flow/features/user/application/collection_revision_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgm_collection_sync_provider.g.dart';

// Page visibility survives notifier rebuilds caused by login/token changes.
class CollectionSyncConnectionScope {
  final owners = <Object>{};
  bool foreground = true;
}

final collectionSyncConnectionScopeProvider =
    Provider((ref) => CollectionSyncConnectionScope());

@Riverpod(keepAlive: true)
class BgmCollectionSync extends _$BgmCollectionSync {
  StreamSubscription<BgmCollectionSyncStatusItem?>? _subscription;
  CancelToken? _cancelToken;
  Timer? _retryTimer, _heartbeatTimer;
  int _connectionGeneration = 0, _retryAttempt = 0;
  bool _ready = false;
  Future<void>? _refresh;
  Object _generation = Object();

  bool _current(Object generation) =>
      ref.mounted && identical(generation, _generation);

  @override
  Future<BgmCollectionSyncStatusItem?> build() async {
    _ready = false;
    _stopConnection();
    final generation = _generation = Object();
    _refresh = null;
    ref.onDispose(() {
      _generation = Object();
      _stopConnection();
    });
    final token = await ref.watch(currentFlowTokenProvider.future);
    if (!_current(generation) || token == null) return null;
    final bind = await ref.watch(bangumiBindProvider.future);
    if (!_current(generation) || bind?.bound != true) return null;
    final status = await ref.read(collectionSyncRepositoryProvider).status();
    if (!_current(generation)) return null;
    _ready = true;
    scheduleMicrotask(() {
      if (_current(generation)) _ensureConnection();
    });
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
      _ready = false;
      state = const AsyncData(null);
      _stopConnection();
      return;
    }
    final status = await ref.read(collectionSyncRepositoryProvider).status();
    if (_current(generation)) {
      _ready = true;
      _accept(status);
    }
  }

  void _accept(BgmCollectionSyncStatusItem status) {
    final previous = state.value;
    if (previous?.taskId != null && status.taskId == null) return;
    if (previous?.taskId != null && status.taskId != null) {
      if (status.taskId! < previous!.taskId!) return;
      if (status.taskId == previous.taskId &&
          status.statusVersion != null &&
          previous.statusVersion != null &&
          status.statusVersion! < previous.statusVersion!) {
        return;
      }
    }
    state = AsyncData(status);
    if (status.syncedCount > 0 &&
        (previous?.taskId != status.taskId ||
            previous?.syncedCount != status.syncedCount ||
            (previous?.status != status.status &&
                status.status == BgmCollectionSyncStatus.success))) {
      _refreshCollections();
    }
    _ensureConnection();
  }

  void _refreshCollections() {
    ref.invalidate(currentUserInfoProvider);
    ref.invalidate(userCollectionsProvider);
    ref.read(collectionRevisionProvider.notifier).changed();
  }

  void setPageSubscription(Object owner, bool enabled) {
    final scope = ref.read(collectionSyncConnectionScopeProvider);
    if (enabled) {
      scope.owners.add(owner);
    } else {
      scope.owners.remove(owner);
    }
    _ensureConnection();
  }

  void setForeground(bool value) {
    ref.read(collectionSyncConnectionScopeProvider).foreground = value;
    _ensureConnection();
  }

  bool get _shouldConnect {
    final scope = ref.read(collectionSyncConnectionScopeProvider);
    return _ready && scope.foreground && scope.owners.isNotEmpty;
  }

  void _ensureConnection() {
    if (!_shouldConnect) {
      _stopConnection();
      _retryAttempt = 0;
      return;
    }
    if (_cancelToken != null || _retryTimer != null) return;
    final generation = _generation;
    final connection = ++_connectionGeneration;
    final cancelToken = _cancelToken = CancelToken();
    bool current() =>
        _current(generation) && connection == _connectionGeneration;

    void disconnected() {
      if (!current()) return;
      _stopConnection();
      if (!_shouldConnect) return;
      final seconds = (1 << _retryAttempt.clamp(0, 5)).clamp(1, 30);
      _retryAttempt++;
      _retryTimer = Timer(Duration(seconds: seconds), () {
        _retryTimer = null;
        if (_current(generation)) _ensureConnection();
      });
    }

    void heartbeat() {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer(const Duration(seconds: 60), disconnected);
    }

    heartbeat(); // Also bounds a handshake that never produces an event.
    _subscription =
        ref.read(collectionSyncRepositoryProvider).events(cancelToken).listen(
      (status) {
        if (!current()) return;
        _retryAttempt = 0;
        heartbeat();
        if (status != null) _accept(status);
      },
      onError: (Object error, StackTrace stack) {
        if (!current()) return;
        // Keep credentials and response bodies out of connection diagnostics.
        final detail = error is DioException
            ? '${error.type.name}, HTTP ${error.response?.statusCode ?? "—"}'
            : error is FormatException
                ? error.message
                : error.runtimeType.toString();
        LiggLogger().w('收藏同步 SSE 连接异常，将重试：$detail');
        disconnected();
      },
      onDone: disconnected,
    );
  }

  void _stopConnection() {
    // Invalidate callbacks before cancellation, so an intentional close never reconnects.
    _connectionGeneration++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    final token = _cancelToken;
    _cancelToken = null;
    if (token != null && !token.isCancelled) {
      token.cancel('collection status subscription closed');
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
  }
}
