import 'dart:async';

import 'package:anime_flow/features/play/domain/player/video_validation_exception.dart';
import 'package:media_kit/media_kit.dart';

/// mpv 的 open 只提交加载命令；必须在提交前监听轨道和解码输出。
Future<void> openMediaKitVideo({
  required Stream<Tracks> tracks,
  required Stream<VideoParams> videoParams,
  required Future<void> Function() open,
  Duration timeout = VideoValidationException.timeout,
}) async {
  final ready = Completer<void>();
  var hasVideo = false;
  var hasVideoOutput = false;
  bool isRealTrack(String id) => id != 'auto' && id != 'no';
  void checkReady() {
    if (hasVideo && hasVideoOutput && !ready.isCompleted) ready.complete();
  }

  final tracksSubscription = tracks.listen((value) {
    hasVideo = value.video.any((track) =>
        isRealTrack(track.id) && track.image != true && track.albumart != true);
    final hasTracks = value.video.any((track) => isRealTrack(track.id)) ||
        value.audio.any((track) => isRealTrack(track.id)) ||
        value.subtitle.any((track) => isRealTrack(track.id));
    if (!hasVideo && hasTracks && !ready.isCompleted) {
      ready.completeError(const VideoValidationException.noVideo());
    }
    checkReady();
  }, onError: (Object error, StackTrace stack) {
    if (!ready.isCompleted) ready.completeError(error, stack);
  });
  final paramsSubscription = videoParams.listen((value) {
    hasVideoOutput = (value.w ?? 0) > 0 && (value.h ?? 0) > 0;
    checkReady();
  }, onError: (Object error, StackTrace stack) {
    if (!ready.isCompleted) ready.completeError(error, stack);
  });
  try {
    // 不把 mpv 的每条 error 日志都视作致命错误：硬件解码失败后可能软件回退。
    // 无视频输出的文件最终超时失败，避免误报已加载成功或无限等待。
    await Future.wait<void>([ready.future, Future.sync(open)], eagerError: true)
        .timeout(timeout,
            onTimeout: () => throw const VideoValidationException.timedOut());
  } finally {
    await tracksSubscription.cancel();
    await paramsSubscription.cancel();
  }
}
