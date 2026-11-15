import 'playback_phase.dart';

/// 内核加载本地文件后的校验结果，不根据扩展名推断解码能力。
class VideoValidationException implements Exception {
  static const timeout = Duration(seconds: 20);

  const VideoValidationException.noVideo()
      : notice = PlaybackNotice.localVideoNoTrack;

  const VideoValidationException.timedOut()
      : notice = PlaybackNotice.localVideoValidationTimedOut;

  final PlaybackNotice notice;

  @override
  String toString() => 'VideoValidationException(${notice.name})';
}
