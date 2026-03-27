import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native 端通过 `MethodChannel('network_speed_monitor')` 提供累计上/下行字节，
/// Flutter 端使用 `Timer.periodic` 轮询 `get`，把“字节增量/时间”换算成速率。
class NetworkSpeedService {
  final MethodChannel _channel;

  Timer? _timer;
  StreamController<NetworkSpeed>? _controller;

  NetworkSpeedService({MethodChannel? channel})
      : _channel = channel ?? MethodChannel('network_speed_monitor');

  ///开始监听网络速度
  Stream<NetworkSpeed> start({int interval = 1000}) {
    // 同步取消旧 timer，避免并发轮询回调继续向旧 controller 写入。
    _timer?.cancel();
    _timer = null;

    // 替换 controller：旧 controller 进行 best-effort 关闭（不等待 close 完成）。
    final oldController = _controller;
    _controller = StreamController<NetworkSpeed>.broadcast();
    oldController?.close();

    final controller = _controller!;

    // 重置 native 侧累计字节/时间基准。
    _channel.invokeMethod('start', {'interval': interval});

    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) async {
      final result = await _channel.invokeMethod<Map>('get');
      if (result == null) return;
      final down = result['download'];
      final up = result['upload'];
      if (down is num && up is num) {
        if (!controller.isClosed) {
          controller.add(NetworkSpeed(download: down, upload: up));
        }
      }
    });

    return controller.stream;
  }

  Future<void> stop() async {
    try {
      _timer?.cancel();
      _timer = null;

      await _channel.invokeMethod('stop');
    } finally {
      final controller = _controller;
      _controller = null;
      await controller?.close();
    }
  }
}

/// 用于依赖注入：每次调用都创建一个“独立实例”，避免多处 UI 共用同一个 timer/controller。
final networkSpeedServiceFactoryProvider =
    Provider<NetworkSpeedService Function()>(
  (ref) {
    return () => NetworkSpeedService();
  },
);

/// provider 持有 start/stop 生命周期。
///
/// - 第一次被 watch 时自动 start
/// - 最后一个监听者销毁时 autoDispose，自动 stop
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

class NetworkSpeed {
  final num download;
  final num upload;

  NetworkSpeed({required this.download, required this.upload});
}
