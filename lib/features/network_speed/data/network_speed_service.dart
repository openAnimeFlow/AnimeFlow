import 'dart:async';
import 'package:flutter/services.dart';

/// Native 端通过 MethodChannel 提供累计上/下行字节，
/// Flutter 端使用 Timer.periodic 轮询 `get`，把“字节增量/时间”换算成速率。
class NetworkSpeedService {
  final MethodChannel _channel;

  Timer? _timer;
  StreamController<NetworkSpeed>? _controller;

  NetworkSpeedService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('network_speed_monitor');

  /// 开始监听网络速度（bytes/s）。
  Stream<NetworkSpeed> start({int interval = 1000}) {
    _timer?.cancel();
    _timer = null;

    final oldController = _controller;
    _controller = StreamController<NetworkSpeed>.broadcast();
    oldController?.close();

    final controller = _controller!;

    _channel.invokeMethod('start', {'interval': interval});

    _timer = Timer.periodic(Duration(milliseconds: interval), (timer) async {
      final result = await _channel.invokeMethod<Map>('get');
      if (result == null) return;
      final down = result['download'];
      final up = result['upload'];
      if (down is num && up is num && !controller.isClosed) {
        controller.add(NetworkSpeed(download: down, upload: up));
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

class NetworkSpeed {
  final num download;
  final num upload;

  NetworkSpeed({required this.download, required this.upload});
}
