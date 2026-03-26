import 'dart:async';
import 'package:flutter/services.dart';

/// 网络速度服务
///
/// Native 端通过 `MethodChannel('network_speed_monitor')` 提供累计上/下行字节，
/// Flutter 端使用 `Timer.periodic` 轮询 `get`，把“字节增量/时间”换算成速率。
class NetworkSpeedService {
  static const MethodChannel _channel = MethodChannel('network_speed_monitor');

  static Timer? _timer;
  static StreamController<NetworkSpeed>? _controller;

  ///开始监听网络速度
  static Stream<NetworkSpeed> start({int interval = 1000}) {
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

  static Future stop() async {
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

class NetworkSpeed {
  final num download;
  final num upload;

  NetworkSpeed({required this.download, required this.upload});
}
