import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:hive_ce/hive.dart';

import 'flow_endpoint_cache.dart';
import 'flow_endpoint_candidates.dart';

abstract interface class FlowEndpointCacheStore {
  Future<Object?> read();
  Future<void> write(Map<String, Object?> value);
}

class HiveFlowEndpointCacheStore implements FlowEndpointCacheStore {
  HiveFlowEndpointCacheStore({Box<dynamic> Function()? box})
      : _box = box ?? (() => Storage.setting);

  final Box<dynamic> Function() _box;

  @override
  Future<Object?> read() async => _box().get(StorageKey.flowEndpointPool);

  @override
  Future<void> write(Map<String, Object?> value) =>
      _box().put(StorageKey.flowEndpointPool, value);
}

/// Storage failures are optional-cache misses and never block normal DNS access.
class FlowEndpointCacheRepository {
  FlowEndpointCacheRepository({
    FlowEndpointCacheStore? store,
    DateTime Function()? now,
    void Function(String)? onWarning,
  })  : _store = store ?? HiveFlowEndpointCacheStore(),
        _now = now ?? DateTime.now,
        _onWarning = onWarning ?? ((message) => LiggLogger().w(message));

  final FlowEndpointCacheStore _store;
  final DateTime Function() _now;
  final void Function(String) _onWarning;
  Future<void> _writeTail = Future<void>.value();

  Future<FlowEndpointCache?> load({
    required Uri endpoint,
    required FlowEndpointCandidates candidates,
  }) async {
    try {
      final raw = await _store.read();
      final cache = FlowEndpointCache.fromMap(raw)?.validatedFor(
        endpoint: endpoint,
        candidates: candidates,
        now: _now(),
      );
      if (raw != null && cache == null) {
        _onWarning('Flow IP 缓存已失效，忽略历史结果');
      }
      return cache;
    } catch (error) {
      _onWarning('读取 Flow IP 缓存失败 (${error.runtimeType})');
      return null;
    }
  }

  /// Serialize writes and prevent an older verification overwriting a newer one.
  Future<bool> save(
    FlowEndpointCache cache, {
    required Uri endpoint,
    required FlowEndpointCandidates candidates,
    bool Function()? isCurrent,
  }) {
    final operation = _writeTail.then((_) async {
      try {
        if (isCurrent != null && !isCurrent()) return false;
        // Round-trip validation also rejects invalid caller-created models.
        final valid = FlowEndpointCache.fromMap(cache.toMap())?.validatedFor(
          endpoint: endpoint,
          candidates: candidates,
          now: _now(),
        );
        if (valid == null) return false;
        final current =
            FlowEndpointCache.fromMap(await _store.read())?.validatedFor(
          endpoint: endpoint,
          candidates: candidates,
          now: _now(),
        );
        if (current != null && current.verifiedAt.isAfter(valid.verifiedAt)) {
          return false;
        }
        if (isCurrent != null && !isCurrent()) return false;
        await _store.write(valid.toMap());
        return true;
      } catch (error) {
        _onWarning('保存 Flow IP 缓存失败 (${error.runtimeType})');
        return false;
      }
    });
    _writeTail = operation.then<void>((_) {});
    return operation;
  }
}
