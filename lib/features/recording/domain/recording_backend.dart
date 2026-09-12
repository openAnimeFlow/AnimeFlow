import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';

/// A cache input requires a live application-owned lease, never an arbitrary URL.
sealed class RecordingInput {
  const RecordingInput();
  String get location;
}

class LocalRecordingInput extends RecordingInput {
  const LocalRecordingInput(this.location);
  @override
  final String location;
}

class CachedRecordingInput extends RecordingInput {
  const CachedRecordingInput(this.lease);
  final HlsCacheLease lease;
  @override
  String get location => lease.playlistUri.toString();
}

enum ClipEncoding { streamCopy, h264Aac }

enum ExportStage { preparing, exporting, validating, saving }

enum ExportStatus { savedLocal, cancelled, failed }

class ClipExportRequest {
  const ClipExportRequest({
    required this.taskId,
    required this.input,
    required this.outputDirectory,
    required this.start,
    required this.duration,
    required this.videoStreamIndex,
    required this.audioStreamIndex,
    this.encoding = ClipEncoding.streamCopy,
    this.fileName = 'clip',
  });

  final String taskId;
  final RecordingInput input;
  final String fileName;
  final String outputDirectory;
  final Duration start;
  final Duration duration;
  // Absolute stream indices from probe, not player-specific track IDs.
  final int videoStreamIndex;
  // Null is allowed only when the input has no audio streams.
  final int? audioStreamIndex;
  final ClipEncoding encoding;
}

class MediaStreamInfo {
  const MediaStreamInfo({
    required this.index,
    required this.type,
    required this.codec,
    this.frames,
    this.colorTransfer,
  });

  final int index;
  final String type;
  final String codec;
  final int? frames;
  final String? colorTransfer;
}

class MediaProbeResult {
  MediaProbeResult({
    required this.duration,
    required this.format,
    required List<MediaStreamInfo> streams,
  }) : streams = List.unmodifiable(streams);

  final Duration duration;
  final String format;
  final List<MediaStreamInfo> streams;

  bool get hasAudio => streams.any((stream) => stream.type == 'audio');
}

class ExportProgress {
  const ExportProgress(this.taskId, this.stage, this.mediaTime);

  final String taskId;
  final ExportStage stage;
  final Duration mediaTime;
}

class RecordingFailure implements Exception {
  const RecordingFailure(this.stage, this.message);

  final ExportStage stage;
  final String message;

  @override
  String toString() => 'RecordingFailure(${stage.name}): $message';
}

class ExportResult {
  const ExportResult({
    required this.taskId,
    required this.status,
    this.localPath,
    this.media,
    this.failure,
  });

  final String taskId;
  final ExportStatus status;
  final String? localPath;
  final MediaProbeResult? media;
  final RecordingFailure? failure;
}

abstract interface class ExportHandle {
  Stream<ExportProgress> get progress;
  Future<ExportResult> get completed;

  /// Requests cancellation of this task only. Await [completed] for cleanup.
  Future<void> cancel();
}

abstract interface class RecordingBackend {
  Future<ExportHandle> exportClip(ClipExportRequest request);
  Future<MediaProbeResult> probe(String localPath);
  Future<MediaProbeResult> probeInput(RecordingInput input);
}
