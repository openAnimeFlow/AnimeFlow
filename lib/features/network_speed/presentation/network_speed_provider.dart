import 'dart:async';
import 'package:anime_flow/features/network_speed/data/network_speed_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用于依赖注入：每次调用都创建一个独立实例。
final networkSpeedServiceFactoryProvider =
    Provider<NetworkSpeedService Function()>(
  (ref) => () => NetworkSpeedService(),
);

/// Riverpod 托管 start/stop 生命周期。
/// - 首次 watch 时自动 start
/// - autoDispose 时自动 stop
final networkSpeedStreamProvider =
    StreamProvider.autoDispose.family<NetworkSpeed, int>(
  (ref, intervalMs) {
    final service = ref.read(networkSpeedServiceFactoryProvider)();
    final stream = service.start(interval: intervalMs);
    ref.onDispose(() {
      unawaited(service.stop());
    });
    return stream;
  },
);
