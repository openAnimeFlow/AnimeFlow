import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/settings/app_settings.dart';

import 'flow_endpoint_cache.dart';
import 'flow_endpoint_candidates.dart';

/// 存储失败按缓存未命中处理，不阻断正常的 DNS 访问。
class FlowEndpointCacheRepository {
  FlowEndpointCacheRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Future<void> _writeTail = Future<void>.value();

  Future<FlowEndpointCache?> load({
    required Uri endpoint,
    required FlowEndpointCandidates candidates,
  }) async {
    try {
      final raw = AppSettings.getSetting<Object?>(StorageKey.flowEndpointPool);
      final cache = FlowEndpointCache.fromMap(raw)?.validatedFor(
        endpoint: endpoint,
        candidates: candidates,
        now: _now(),
      );
      if (raw != null && cache == null) {
        LiggLogger().w('Flow IP 缓存已失效，忽略历史结果');
      }
      return cache;
    } catch (error) {
      LiggLogger().w('读取 Flow IP 缓存失败 (${error.runtimeType})');
      return null;
    }
  }

  /// 串行写入，防止较旧的验证结果覆盖较新的结果。
  Future<bool> save(
    FlowEndpointCache cache, {
    required Uri endpoint,
    required FlowEndpointCandidates candidates,
    bool Function()? isCurrent,
  }) {
    final operation = _writeTail.then((_) async {
      try {
        if (isCurrent != null && !isCurrent()) return false;
        // 通过序列化后再解析校验，同时拒绝调用方构造的无效模型。
        final valid = FlowEndpointCache.fromMap(cache.toMap())?.validatedFor(
          endpoint: endpoint,
          candidates: candidates,
          now: _now(),
        );
        if (valid == null) return false;
        final current = FlowEndpointCache.fromMap(
          AppSettings.getSetting<Object?>(StorageKey.flowEndpointPool),
        )?.validatedFor(
          endpoint: endpoint,
          candidates: candidates,
          now: _now(),
        );
        if (current != null && current.verifiedAt.isAfter(valid.verifiedAt)) {
          return false;
        }
        await AppSettings.setSetting(
            StorageKey.flowEndpointPool, valid.toMap());
        return true;
      } catch (error) {
        LiggLogger().w('保存 Flow IP 缓存失败 (${error.runtimeType})');
        return false;
      }
    });
    _writeTail = operation.then<void>((_) {});
    return operation;
  }
}
