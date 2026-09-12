import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../domain/recording_backend.dart';
import 'ffmpeg_kit_runner.dart';

/// Local-file technical baseline. Does not imply network recording or gallery
/// support. A successful result has passed probe, frame counts and full decode.
class FfmpegRecordingBackend implements RecordingBackend {
  const FfmpegRecordingBackend({this.runner = const FfmpegKitRunner()});

  final FfmpegRunner runner;

  @override
  Future<MediaProbeResult> probe(String localPath) async {
    _requireLocalPath(localPath);
    final command = await runner.start(_probeArguments(localPath), probe: true);
    final result = await command.completed;
    if (!result.succeeded) {
      throw const RecordingFailure(ExportStage.preparing, '无法探测本地媒体');
    }
    return parseProbe(result.output);
  }

  @override
  Future<ExportHandle> exportClip(ClipExportRequest request) async {
    _requireLocalPath(request.inputPath);
    _requireLocalPath(request.outputDirectory);
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(request.taskId) ||
        request.start < Duration.zero ||
        request.duration <= Duration.zero ||
        request.videoStreamIndex < 0 ||
        (request.audioStreamIndex != null && request.audioStreamIndex! < 0)) {
      throw ArgumentError('Invalid clip request');
    }
    final handle = _ExportTask(request, runner);
    unawaited(handle.run());
    return handle;
  }

  static void _requireLocalPath(String path) {
    if (!p.isAbsolute(path) ||
        path.contains('\u0000') ||
        path.startsWith('\\\\') ||
        path.startsWith('//')) {
      throw ArgumentError('An absolute local filesystem path is required');
    }
  }

  static List<String> _probeArguments(String path,
          {bool countFrames = false}) =>
      [
        '-v', 'error', '-protocol_whitelist', 'file',
        // Exclude playlists and indirect/network demuxers in this phase.
        '-format_whitelist', 'mov,matroska,webm,mpegts,avi',
        if (countFrames) '-count_frames',
        '-show_format', '-show_streams', '-of', 'json', '-i', path,
      ];

  static MediaProbeResult parseProbe(String output) {
    final data = jsonDecode(output) as Map<String, dynamic>;
    final format = data['format'] as Map<String, dynamic>;
    final seconds = double.tryParse('${format['duration']}');
    if (seconds == null || !seconds.isFinite || seconds <= 0) {
      throw const FormatException('Missing positive media duration');
    }
    return MediaProbeResult(
      duration: Duration(microseconds: (seconds * 1000000).round()),
      format: format['format_name'] as String,
      streams: (data['streams'] as List).map((item) {
        final stream = item as Map<String, dynamic>;
        return MediaStreamInfo(
          index: stream['index'] as int,
          type: stream['codec_type'] as String? ?? '',
          codec: stream['codec_name'] as String? ?? '',
          frames: int.tryParse('${stream['nb_read_frames']}'),
          colorTransfer: stream['color_transfer'] as String?,
        );
      }).toList(),
    );
  }
}

class _ExportTask implements ExportHandle {
  _ExportTask(this.request, this.runner);

  final ClipExportRequest request;
  final FfmpegRunner runner;
  final _progress = StreamController<ExportProgress>.broadcast();
  final _completion = Completer<ExportResult>();
  NativeCommand? _active;
  bool _cancelled = false;
  ExportStage _stage = ExportStage.preparing;
  File? _partial;
  Directory? _directory;

  @override
  Stream<ExportProgress> get progress => _progress.stream;
  @override
  Future<ExportResult> get completed => _completion.future;

  @override
  Future<void> cancel() async {
    if (_completion.isCompleted || _stage == ExportStage.saving) return;
    _cancelled = true;
    await _active?.cancel();
  }

  void _checkCancelled() {
    if (_cancelled) throw const _Cancelled();
  }

  void _setStage(ExportStage stage) {
    _stage = stage;
    _progress.add(ExportProgress(request.taskId, stage, Duration.zero));
  }

  Future<NativeCommandResult> _execute(List<String> args,
      {bool probe = false}) async {
    _checkCancelled();
    final command = await runner.start(args, probe: probe, onTime: (time) {
      if (!_completion.isCompleted && !_cancelled) {
        _progress.add(ExportProgress(request.taskId, _stage, time));
      }
    });
    _active = command;
    // Cancellation can arrive while native session creation is pending.
    try {
      if (_cancelled) {
        try {
          await command.cancel();
        } catch (_) {
          // A rejected stop request does not mean the native writer stopped.
          // Still wait for completion before cleaning up its output.
        }
      }
      final result = await command.completed;
      _checkCancelled();
      if (result.cancelled) throw const _Cancelled();
      if (!result.succeeded) {
        throw RecordingFailure(_stage, 'FFmpeg 执行失败（返回码 ${result.returnCode}）');
      }
      return result;
    } finally {
      _active = null;
    }
  }

  Future<void> run() async {
    ExportResult result;
    try {
      _setStage(ExportStage.preparing);
      if (!await File(request.inputPath).exists()) {
        throw const RecordingFailure(ExportStage.preparing, '本地源文件不存在');
      }
      final input = FfmpegRecordingBackend.parseProbe((await _execute(
        FfmpegRecordingBackend._probeArguments(request.inputPath),
        probe: true,
      ))
          .output);
      final videos = input.streams.where(
          (s) => s.type == 'video' && s.index == request.videoStreamIndex);
      final audios = input.streams.where(
          (s) => s.type == 'audio' && s.index == request.audioStreamIndex);
      if (videos.length != 1 ||
          (input.hasAudio && audios.length != 1) ||
          (!input.hasAudio && request.audioStreamIndex != null)) {
        throw const RecordingFailure(ExportStage.preparing, '所选音视频轨道与源文件不匹配');
      }
      if (request.start + request.duration > input.duration) {
        throw const RecordingFailure(ExportStage.preparing, '录制区间超出源文件时长');
      }
      if (request.encoding == ClipEncoding.h264Aac &&
          ['smpte2084', 'arib-std-b67'].contains(videos.single.colorTransfer)) {
        throw const RecordingFailure(ExportStage.preparing, '准备阶段暂不支持 HDR 转码');
      }
      await Directory(request.outputDirectory).create(recursive: true);
      // Each task owns a unique directory, so concurrent tasks never overwrite.
      _directory = await Directory(request.outputDirectory)
          .createTemp('${request.taskId}_');
      final extension =
          request.encoding == ClipEncoding.streamCopy ? 'mkv' : 'mp4';
      _partial = File(p.join(_directory!.path, 'clip.partial.$extension'));
      _setStage(ExportStage.exporting);
      final copy = request.encoding == ClipEncoding.streamCopy;
      await _execute([
        '-hide_banner',
        '-v',
        'error',
        '-nostdin',
        '-n',
        '-protocol_whitelist',
        'file',
        '-format_whitelist',
        'mov,matroska,webm,mpegts,avi',
        '-ss',
        _seconds(request.start),
        '-i',
        request.inputPath,
        '-t',
        _seconds(request.duration),
        '-map',
        '0:${request.videoStreamIndex}',
        if (request.audioStreamIndex != null) ...[
          '-map',
          '0:${request.audioStreamIndex}'
        ],
        '-map_metadata',
        '-1',
        '-map_chapters',
        '-1',
        if (copy) ...[
          '-c',
          'copy'
        ] else ...[
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-crf',
          '20',
          '-vf',
          'scale=trunc(iw/2)*2:trunc(ih/2)*2',
          '-pix_fmt',
          'yuv420p',
          '-c:a',
          'aac',
          '-movflags',
          '+faststart',
        ],
        '-f',
        copy ? 'matroska' : 'mp4',
        _partial!.path,
      ]);
      _setStage(ExportStage.validating);
      final output = FfmpegRecordingBackend.parseProbe((await _execute(
        FfmpegRecordingBackend._probeArguments(_partial!.path,
            countFrames: true),
        probe: true,
      ))
          .output);
      final video = output.streams.where((s) => s.type == 'video').toList();
      final audio = output.streams.where((s) => s.type == 'audio').toList();
      if (video.length != 1 ||
          audio.length != (input.hasAudio ? 1 : 0) ||
          [...video, ...audio].any((s) => (s.frames ?? 0) <= 0) ||
          video.single.codec != (copy ? videos.single.codec : 'h264') ||
          (input.hasAudio &&
              audio.single.codec != (copy ? audios.single.codec : 'aac'))) {
        throw const RecordingFailure(ExportStage.validating, '成品音视频轨道或有效帧校验失败');
      }
      // Stream-copy boundaries can extend to preceding keyframes. No promise
      // of frame-exact cutting; the fixture suite checks its known GOP tolerance.
      await _execute([
        '-v',
        'error',
        '-nostdin',
        '-xerror',
        '-err_detect',
        'explode',
        '-protocol_whitelist',
        'file',
        '-i',
        _partial!.path,
        '-map',
        '0:v:0',
        if (input.hasAudio) ...['-map', '0:a:0'],
        '-f',
        'null',
        '-',
      ]);
      _checkCancelled();
      _setStage(ExportStage.saving);
      final saved =
          await _partial!.rename(p.join(_directory!.path, 'clip.$extension'));
      result = ExportResult(
          taskId: request.taskId,
          status: ExportStatus.savedLocal,
          localPath: saved.path,
          media: output);
    } on _Cancelled {
      result =
          ExportResult(taskId: request.taskId, status: ExportStatus.cancelled);
    } catch (error) {
      result = ExportResult(
          taskId: request.taskId,
          status: ExportStatus.failed,
          failure: error is RecordingFailure
              ? error
              : RecordingFailure(_stage, '录制处理失败（${error.runtimeType}）'));
    }
    // Only delete owned incomplete output after native execution has stopped.
    // A cleanup failure must not strand completion or misreport a saved file.
    if (result.status != ExportStatus.savedLocal) {
      try {
        if (await _partial?.exists() ?? false) await _partial!.delete();
        if (_directory != null) await _directory!.delete();
      } on FileSystemException {
        /* A remaining .partial is never a saved result. */
      }
    }
    _completion.complete(result);
    unawaited(_progress.close());
  }

  static String _seconds(Duration time) =>
      (time.inMicroseconds / 1000000).toStringAsFixed(6);
}

class _Cancelled implements Exception {
  const _Cancelled();
}
