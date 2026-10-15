import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:flutter/services.dart';

import 'flow_endpoint_cache.dart';
import 'flow_endpoint_cache_repository.dart';
import 'flow_endpoint_candidates.dart';

/// Phase 1 loads candidates/cache hints only; it does not change HTTP routing.
class FlowEndpointPool {
  FlowEndpointPool({
    AssetBundle? assetBundle,
    FlowEndpointCacheRepository? cacheRepository,
    Uri? endpoint,
    void Function(String)? onWarning,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _cacheRepository = cacheRepository ?? FlowEndpointCacheRepository(),
        endpoint = endpoint ?? Uri.parse(AnimeFlowApi.animeFlowApi),
        _onWarning = onWarning ?? ((message) => LiggLogger().w(message));

  static final instance = FlowEndpointPool();
  static const assetPath = 'assets/network/ligg-candidates.txt';

  final Uri endpoint;
  final AssetBundle _assetBundle;
  final FlowEndpointCacheRepository _cacheRepository;
  final void Function(String) _onWarning;
  FlowEndpointCandidates _candidates = FlowEndpointCandidates.parse('');
  FlowEndpointCache? _cachedForRevalidation;
  Future<void>? _initialization;

  FlowEndpointCandidates get candidates => _candidates;
  FlowEndpointCache? get cachedForRevalidation => _cachedForRevalidation;

  /// Cached addresses are tested first, never treated as already usable.
  List<String> get revalidationOrder => List.unmodifiable({
        ...?_cachedForRevalidation?.measurements.map((item) => item.address),
        ..._candidates.addresses,
      });

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      if (endpoint.scheme != 'https' || endpoint.host.isEmpty) {
        _onWarning('Flow IP 优选仅支持有效的 HTTPS 域名');
        return;
      }
      _candidates = FlowEndpointCandidates.parse(
        await _assetBundle.loadString(assetPath),
      );
      if (_candidates.rejectedLines.isNotEmpty) {
        _onWarning('Flow IP 资源已忽略无效行: '
            '${_candidates.rejectedLines.join(', ')}');
      }
      if (_candidates.addresses.isEmpty) {
        _onWarning('Flow IP 候选池为空，继续使用系统 DNS');
        return;
      }
      _cachedForRevalidation = await _cacheRepository.load(
        endpoint: endpoint,
        candidates: _candidates,
      );
      LiggLogger().d('Flow IP 资源已加载 ${_candidates.addresses.length} 个候选，'
          '历史复测候选 ${_cachedForRevalidation?.measurements.length ?? 0} 个');
    } catch (error) {
      _onWarning('加载 Flow IP 资源失败，继续使用系统 DNS (${error.runtimeType})');
    }
  }
}
