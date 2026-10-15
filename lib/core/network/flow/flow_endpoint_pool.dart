import 'dart:async';
import 'dart:math';

import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/core/network/api_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flow_endpoint_cache.dart';
import 'flow_endpoint_cache_repository.dart';
import 'flow_endpoint_candidates.dart';
import 'flow_endpoint_probe.dart';

class FlowEndpointPool extends ChangeNotifier {
  FlowEndpointPool({
    AssetBundle? assetBundle,
    FlowEndpointCacheRepository? cacheRepository,
    Uri? endpoint,
    void Function(String)? onWarning,
    DateTime Function()? now,
    FlowProbeSession Function(Uri)? probeFactory,
    Random? random,
    this.roundTimeout = const Duration(seconds: 15),
  })  : _assetBundle = assetBundle ?? rootBundle,
        _cacheRepository = cacheRepository ?? FlowEndpointCacheRepository(),
        endpoint = endpoint ?? Uri.parse(AnimeFlowApi.animeFlowApi),
        _onWarning = onWarning ?? ((message) => LiggLogger().w(message)),
        _now = now ?? DateTime.now,
        _probeFactory =
            probeFactory ?? ((uri) => FlowEndpointProbe(endpoint: uri)),
        _random = random ?? Random();

  static final instance = FlowEndpointPool();
  static const assetPath = 'assets/network/ligg-candidates.txt';

  final Uri endpoint;
  final AssetBundle _assetBundle;
  final FlowEndpointCacheRepository _cacheRepository;
  final void Function(String) _onWarning;
  FlowEndpointCandidates _candidates = FlowEndpointCandidates.parse('');
  FlowEndpointCache? _cachedForRevalidation;
  Future<void>? _initialization;
  final DateTime Function() _now;
  final FlowProbeSession Function(Uri) _probeFactory;
  final Random _random;
  final Duration roundTimeout;
  final _revalidationRequests = StreamController<void>.broadcast(sync: true);
  final Map<String?, _EndpointStats> _stats = {};
  final Map<String, (int, DateTime)> _cooldowns = {};
  List<String> _preferredAddresses = const [];
  List<String> _probeOrder = const [];
  int _cursor = 0;
  int _networkGeneration = 0;
  int _routeVersion = 0;
  int _roundToken = 0;
  DateTime? _routeExpiresAt;
  Future<void>? _probing;
  FlowProbeSession? _activeProbe;
  bool _disposed = false;

  int get networkGeneration => _networkGeneration;
  int get routeVersion => _routeVersion;
  List<String> get preferredAddresses => _preferredAddresses;
  Stream<void> get revalidationRequests => _revalidationRequests.stream;

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
      final shuffled = _candidates.addresses.toList()..shuffle(_random);
      _probeOrder = List.unmodifiable({
        ...?_cachedForRevalidation?.measurements.map((item) => item.address),
        ...shuffled,
      });
      LiggLogger().d('Flow IP 资源已加载 ${_candidates.addresses.length} 个候选，'
          '历史复测候选 ${_cachedForRevalidation?.measurements.length ?? 0} 个');
    } catch (error) {
      _onWarning('加载 Flow IP 资源失败，继续使用系统 DNS (${error.runtimeType})');
    }
  }

  bool isAddressAvailable(String address) {
    final cooldown = _cooldowns[address];
    return _candidates.contains(address) &&
        (cooldown == null || !_now().isBefore(cooldown.$2));
  }

  void requestRevalidation() {
    if (!_disposed) _revalidationRequests.add(null);
  }

  void reportConnectionFailure(String address, int generation) {
    if (_disposed ||
        generation != _networkGeneration ||
        !_candidates.contains(address)) {
      return;
    }
    final failures = (_cooldowns[address]?.$1 ?? 0) + 1;
    final minutes = min(10, 1 << min(failures - 1, 4));
    _cooldowns[address] = (failures, _now().add(Duration(minutes: minutes)));
    _stats.remove(address);
    _setRoute(_preferredAddresses.where((ip) => ip != address).toList());
    requestRevalidation();
  }

  void expireRoute() {
    if (_routeExpiresAt != null && !_now().isBefore(_routeExpiresAt!)) {
      _stats.clear();
      _setRoute(const [], force: true);
      _routeExpiresAt = null;
      requestRevalidation();
    }
  }

  void networkChanged() {
    if (_disposed) return;
    _networkGeneration++;
    cancelProbe();
    _stats.clear();
    _cooldowns.clear();
    _routeExpiresAt = null;
    _setRoute(const [], force: true);
  }

  void cancelProbe() {
    _roundToken++;
    _activeProbe?.cancel();
  }

  Future<void> probe() {
    if (_disposed) return Future<void>.value();
    return _probing ??= _runProbe().whenComplete(() => _probing = null);
  }

  Future<void> _runProbe() async {
    final beforeInitialization = _roundToken;
    await initialize();
    if (_disposed ||
        beforeInitialization != _roundToken ||
        _probeOrder.isEmpty) {
      return;
    }
    final token = ++_roundToken;
    final generation = _networkGeneration;
    final session = _activeProbe = _probeFactory(endpoint);
    final samples = <String?, _EndpointStats>{};
    var deadlineReached = false;
    final timer = Timer(roundTimeout, () {
      deadlineReached = true;
      session.cancel();
    });
    bool current() =>
        !_disposed && token == _roundToken && generation == _networkGeneration;

    Future<void> measure(List<String?> targets) async {
      var index = 0;
      Future<void> worker() async {
        while (current() && !deadlineReached && index < targets.length) {
          final address = targets[index++];
          final latency = await session.probe(address);
          if (!current() || deadlineReached) return;
          (samples[address] ??= _EndpointStats()).add(latency);
        }
      }

      await Future.wait(List.generate(min(3, targets.length), (_) => worker()));
    }

    try {
      final selected = <String>[];
      for (var count = 0;
          count < _probeOrder.length && selected.length < 12;
          count++) {
        final ip = _probeOrder[_cursor++ % _probeOrder.length];
        if (isAddressAvailable(ip)) selected.add(ip);
      }
      await measure([null, ...selected]);
      if (!current()) return;
      final successful = selected
          .where((ip) => samples[ip]?.latencies.isNotEmpty ?? false)
          .toList()
        ..sort((a, b) => samples[a]!.average.compareTo(samples[b]!.average));
      // Confirm DNS and the fastest three IPs using fresh TLS connections.
      await measure([null, ...successful.take(3)]);
      if (!current()) return;
      for (final entry in samples.entries) {
        final stats = _stats[entry.key] ??= _EndpointStats();
        stats.merge(entry.value);
        if (entry.key != null && entry.value.latencies.isNotEmpty) {
          _cooldowns.remove(entry.key);
        }
      }
      _chooseRoute();
      final eligible = _eligibleAddresses();
      if (eligible.isNotEmpty) {
        final ordered = <String>{..._preferredAddresses, ...eligible}.take(3);
        await _cacheRepository.save(
            FlowEndpointCache(
              host: endpoint.host,
              port: endpoint.port,
              candidateHash: _candidates.hash,
              verifiedAt: _now(),
              measurements: ordered
                  .map((ip) => FlowEndpointMeasurement(
                      address: ip,
                      latency: _stats[ip]!.average,
                      successCount: _stats[ip]!.latencies.length))
                  .toList(),
            ),
            endpoint: endpoint,
            candidates: _candidates,
            isCurrent: current);
      }
      LiggLogger().d('Flow IP 测速完成，网络代次 $generation，'
          '可用候选 ${eligible.length}，当前路径 '
          '${_preferredAddresses.isEmpty ? 'DNS' : _preferredAddresses.first}');
    } catch (error) {
      _onWarning('Flow IP 测速失败 (${error.runtimeType})');
    } finally {
      timer.cancel();
      session.cancel();
      if (identical(_activeProbe, session)) _activeProbe = null;
    }
  }

  List<String> _eligibleAddresses() => _stats.keys
      .whereType<String>()
      .where((ip) =>
          isAddressAvailable(ip) &&
          _stats[ip]!.lastSucceeded &&
          _stats[ip]!.latencies.length >= 2)
      .toList()
    ..sort((a, b) => _compare(_stats[a]!, _stats[b]!));

  int _compare(_EndpointStats a, _EndpointStats b) {
    final reliability = b.successRate.compareTo(a.successRate);
    if (reliability != 0) return reliability;
    final latency = a.average.compareTo(b.average);
    return latency != 0 ? latency : a.jitter.compareTo(b.jitter);
  }

  void _chooseRoute() {
    final eligible = _eligibleAddresses();
    if (eligible.isEmpty) {
      _setRoute(const []);
      return;
    }
    final dns = _stats[null];
    // An unmeasured baseline is not evidence that normal DNS is worse.
    if (dns == null || dns.attempts == 0) return;
    String? best = eligible.first;
    if (dns.latencies.isNotEmpty && _compare(dns, _stats[best]!) <= 0) {
      best = null;
    }
    final old = _preferredAddresses.isEmpty ? null : _preferredAddresses.first;
    final oldStats = _stats[old];
    final newStats = _stats[best];
    if (best != old &&
        (old == null || eligible.contains(old)) &&
        oldStats != null &&
        oldStats.lastSucceeded &&
        oldStats.latencies.isNotEmpty &&
        newStats != null &&
        newStats.latencies.isNotEmpty) {
      final improvement = oldStats.average - newStats.average;
      if (improvement < const Duration(milliseconds: 100) ||
          newStats.average.inMicroseconds >
              oldStats.average.inMicroseconds * .8) {
        best = old;
      }
    }
    _setRoute(best == null
        ? const []
        : [best, ...eligible.where((ip) => ip != best).take(2)]);
    _routeExpiresAt = _now().add(FlowEndpointCache.lifetime);
  }

  void _setRoute(List<String> addresses, {bool force = false}) {
    if (_disposed || (!force && listEquals(addresses, _preferredAddresses))) {
      return;
    }
    _preferredAddresses = List.unmodifiable(addresses);
    _routeVersion++;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    cancelProbe();
    _disposed = true;
    unawaited(_revalidationRequests.close());
    super.dispose();
  }
}

class _EndpointStats {
  final List<Duration?> _samples = [];
  int get attempts => _samples.length;
  List<Duration> get latencies => _samples.whereType<Duration>().toList();
  bool get lastSucceeded => _samples.isNotEmpty && _samples.last != null;
  double get successRate => attempts == 0 ? 0 : latencies.length / attempts;
  Duration get average => latencies.isEmpty
      ? Duration.zero
      : Duration(
          microseconds:
              latencies.fold<int>(0, (sum, d) => sum + d.inMicroseconds) ~/
                  latencies.length);
  Duration get jitter => latencies.length < 2
      ? Duration.zero
      : (latencies.reduce((a, b) => a > b ? a : b) -
          latencies.reduce((a, b) => a < b ? a : b));
  void add(Duration? latency) {
    _samples.add(latency);
    _trim();
  }

  void merge(_EndpointStats other) {
    _samples.addAll(other._samples);
    _trim();
  }

  void _trim() {
    // Bound historical influence and memory on long-running clients.
    if (_samples.length > 12) {
      _samples.removeRange(0, _samples.length - 12);
    }
  }
}
