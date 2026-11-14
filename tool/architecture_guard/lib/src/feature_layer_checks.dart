import 'model.dart';

const _play = 'lib/features/play/';
const _downloadDomain = 'lib/features/download/domain/';
const _nativePackages = {
  'dio',
  'hive_ce',
  'hive_ce_flutter',
  'flutter_secure_storage',
  'media_kit',
  'media_kit_video',
  'video_player',
  'fvp',
  'window_manager',
  'wakelock_plus',
  'battery_plus',
  'screen_brightness_platform_interface',
  'flutter_opencc_plus',
  'path_provider',
  'flutter_volume_controller',
};
bool _externalRuntime(String uri) =>
    uri == 'dart:io' ||
    uri == 'dart:ui' ||
    uri == 'dart:ffi' ||
    uri == 'dart:html' ||
    uri == 'dart:js_interop';
String? _featureLayer(String uri) =>
    uri.startsWith('lib/features/') ? uri.split('/').elementAtOrNull(3) : null;

bool _outerLayer(String uri) => const {
  'presentation',
  'data',
  'infrastructure',
  'composition',
}.contains(_featureLayer(uri));

bool _blocked(String layer, String target) {
  if (layer == 'domain' || layer == 'application') {
    return _externalRuntime(target) ||
        target.startsWith('package:') ||
        _outerLayer(target) ||
        (layer == 'domain' && target.contains('/application/'));
  }
  if (layer == 'infrastructure') {
    return target.startsWith('${_play}presentation/') ||
        target.startsWith('${_play}application/') ||
        target.startsWith('${_play}composition/');
  }
  return target.startsWith('${_play}infrastructure/') ||
      target.startsWith('${_play}composition/') ||
      const {'data', 'infrastructure'}.contains(_featureLayer(target)) ||
      target.startsWith('lib/core/network/api/') ||
      target.startsWith('lib/core/network/clients/') ||
      const {
        'lib/core/settings/storage.dart',
        'lib/core/settings/app_settings.dart',
        'lib/core/utils/system_util.dart',
        'lib/core/crawler/rule_engine.dart',
        'lib/core/logger/logger.dart',
      }.contains(target) ||
      target == 'dart:io' ||
      target == 'dart:ffi' ||
      (target.startsWith('package:') &&
          _nativePackages.contains(target.substring(8).split('/').first));
}

/// Check imports including conditional branches. Inner layers must remain pure
/// through local helpers. For UI and adapters, follow exports to catch barrels.
Iterable<ArchitectureViolation> checkFeatureLayers(
  DependencyGraph graph,
) sync* {
  final outgoing = <String, List<DependencyEdge>>{};
  for (final edge in graph.edges) {
    outgoing.putIfAbsent(edge.source, () => []).add(edge);
  }
  for (final source in outgoing.keys.where(
    (path) => path.startsWith(_play) || path.startsWith(_downloadDomain),
  )) {
    final feature = source.split('/')[2];
    final layer = _featureLayer(source)!;
    if (!const {
      'domain',
      'application',
      'presentation',
      'infrastructure',
    }.contains(layer)) {
      continue;
    }
    final transitive = layer == 'domain' || layer == 'application';
    for (final first in outgoing[source]!) {
      final pending = [first.target];
      final seen = <String>{};
      while (pending.isNotEmpty) {
        final target = pending.removeLast();
        if (!seen.add(target)) continue;
        if (_blocked(layer, target)) {
          yield ArchitectureViolation(
            'R11',
            source,
            target,
            first.kind,
            first.line,
            '$feature/$layer 越过依赖边界，经 ${first.target} 引入 $target。',
          );
          continue;
        }
        for (final next in outgoing[target] ?? const <DependencyEdge>[]) {
          if (transitive || next.kind == 'export') pending.add(next.target);
        }
      }
    }
  }
}
