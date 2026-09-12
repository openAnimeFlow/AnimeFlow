import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';

import '../domain/recording_backend.dart';
import 'recording_service.dart';

enum RecordingMarkerStatus { idle, preparing, marking }

class RecordingMarker {
  const RecordingMarker(
      {this.status = RecordingMarkerStatus.idle,
      this.start = Duration.zero,
      this.end = Duration.zero,
      this.message});
  final RecordingMarkerStatus status;
  final Duration start;
  final Duration end;
  final String? message;
}

/// One marker per playback session. Freezing transfers its lease to the queue.
class RecordingController extends ValueNotifier<RecordingMarker> {
  RecordingController({this.serviceFactory = sharedRecordingService})
      : super(const RecordingMarker());
  final Future<RecordingService> Function() serviceFactory;
  int _revision = 0;
  bool _disposed = false;
  RecordingService? _service;
  RecordingInput? _input;
  String _title = '';
  int _video = 0;
  int? _audio;
  Duration _latest = Duration.zero;
  bool get active => value.status != RecordingMarkerStatus.idle;

  Future<void> start(
      {required String title,
      required Duration position,
      HlsCacheSession? cache,
      String? localPath}) async {
    if (_disposed || active) return;
    final revision = ++_revision;
    _latest = position;
    value = RecordingMarker(
        status: RecordingMarkerStatus.preparing,
        start: position,
        end: position);
    RecordingInput? input;
    RecordingService? service;
    var reserved = false;
    var transferred = false;
    try {
      // Acquire before any asynchronous preparation or playback owner release.
      if (cache != null) {
        if (position >= cache.timeline.duration) throw StateError('视频已结束');
        input = CachedRecordingInput(cache.retainRange(position, position));
      } else if (localPath != null) {
        input = LocalRecordingInput(localPath);
      } else {
        throw StateError('请先启用共享媒体缓存并重新打开支持的视频');
      }
      service = await serviceFactory();
      if (_disposed || revision != _revision) return;
      service.reserve();
      reserved = true;
      final media = await service.backend.probeInput(input);
      if (_disposed || revision != _revision) return;
      final videos = media.streams.where((s) => s.type == 'video').toList();
      final audios = media.streams.where((s) => s.type == 'audio').toList();
      // Player track IDs are not FFprobe indices. Until a track mapping exists,
      // accept only an unambiguous video and at most one audio stream.
      if (videos.length != 1 || audios.length > 1) {
        throw StateError('当前仅支持单视频轨和至多一条音轨');
      }
      if (input is LocalRecordingInput && position >= media.duration) {
        throw StateError('视频已结束');
      }
      _service = service;
      _input = input;
      _title = title;
      _video = videos.single.index;
      _audio = audios.isEmpty ? null : audios.single.index;
      transferred = true;
      value = RecordingMarker(
          status: RecordingMarkerStatus.marking,
          start: position,
          end: position);
      updatePosition(_latest);
    } catch (error) {
      if (!_disposed && revision == _revision) {
        value = RecordingMarker(
            message:
                error is StateError ? error.message : '录制准备失败，当前视频无法录制');
      }
    } finally {
      if (!transferred) {
        if (reserved) service!.releaseReservation();
        if (input is CachedRecordingInput) await input.lease.release();
      }
    }
  }

  void updatePosition(Duration position) {
    _latest = position;
    if (_disposed || value.status != RecordingMarkerStatus.marking) return;
    if (position < value.end) {
      // An unexpected backwards position must never shrink or join intervals.
      freeze();
      return;
    }
    final input = _input;
    try {
      if (input is CachedRecordingInput) {
        if (position > input.lease.session.timeline.duration) {
          position = input.lease.session.timeline.duration;
        }
        input.lease.extend(position);
      }
      value = RecordingMarker(
          status: RecordingMarkerStatus.marking,
          start: value.start,
          end: position);
    } catch (_) {
      freeze();
    }
  }

  /// Uses the last position from the OLD timeline. No native IO is awaited.
  RecordingTask? freeze() {
    _revision++;
    if (_disposed) return null;
    final marker = value;
    final input = _input;
    final service = _service;
    _input = null;
    _service = null;
    value = const RecordingMarker();
    if (input == null || service == null) return null;
    if (marker.end - marker.start < const Duration(milliseconds: 500)) {
      service.releaseReservation();
      if (input is CachedRecordingInput) unawaited(input.lease.release());
      value = const RecordingMarker(message: '片段不足半秒，未生成视频');
      return null;
    }
    return service.enqueue(
        title: _title,
        input: input,
        start: marker.start,
        end: marker.end,
        videoIndex: _video,
        audioIndex: _audio);
  }

  @override
  void dispose() {
    freeze();
    _disposed = true;
    super.dispose();
  }
}
