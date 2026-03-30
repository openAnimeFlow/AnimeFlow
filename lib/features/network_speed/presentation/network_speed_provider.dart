import 'dart:async';

import 'package:anime_flow/features/network_speed/data/network_speed_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_speed_provider.g.dart';

/// 用于依赖注入：每次调用都创建一个独立实例。
@riverpod
NetworkSpeedService Function() networkSpeedServiceFactory(Ref ref) {
  return () => NetworkSpeedService();
}

/// Riverpod 托管 start/stop 生命周期。
/// - 首次 watch 时自动 start
/// - autoDispose 时自动 stop
@riverpod
Stream<NetworkSpeed> networkSpeedStream(Ref ref, int intervalMs) async* {
  final service = ref.read(networkSpeedServiceFactoryProvider)();
  final stream = service.start(interval: intervalMs);
  ref.onDispose(() {
    unawaited(service.stop());
  });
  yield* stream;
}
