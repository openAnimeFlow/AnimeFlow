import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import '../domain/recording_backend.dart';
import '../infrastructure/ffmpeg_recording_backend.dart';

enum RecordingTaskStatus { queued, exporting, saved, failed, cancelled }

class RecordingTask {
  RecordingTask(
      {required this.id,
      required this.title,
      required this.start,
      required this.end,
      required this.created,
      this.input,
      this.videoIndex = 0,
      this.audioIndex});
  final String id;
  final String title;
  final Duration start;
  final Duration end;
  final DateTime created;
  RecordingInput? input;
  final int videoIndex;
  final int? audioIndex;
  RecordingTaskStatus status = RecordingTaskStatus.queued;
  ExportStage stage = ExportStage.preparing;
  Duration progress = Duration.zero;
  String? localPath;
  String? digest;
  String? error;
  String? persistenceError;
  ClipEncoding encoding = ClipEncoding.streamCopy;
  ExportHandle? _handle;
  bool _cancelRequested = false;
  bool get busy =>
      status == RecordingTaskStatus.queued ||
      status == RecordingTaskStatus.exporting;
  bool get canRetry => status == RecordingTaskStatus.failed && input != null;
  Duration get duration => end - start;
}

/// Application-owned queue. Playback pages own markers, never export lifetimes.
class RecordingService extends ChangeNotifier {
  RecordingService(
      {required this.directory,
      required this.backend,
      this.maxRetainedTasks = 3});
  final Directory directory;
  final RecordingBackend backend;
  final int maxRetainedTasks;
  final _tasks = <RecordingTask>[];
  final _writes = Lock();
  bool _running = false;
  int _reservations = 0;
  List<RecordingTask> get tasks => List.unmodifiable(_tasks);

  void reserve() {
    if (_reservations + _tasks.where((t) => t.input != null).length >=
        maxRetainedTasks) {
      throw StateError('最多保留 $maxRetainedTasks 个录制区间，请先完成或放弃已有任务');
    }
    _reservations++;
  }

  void releaseReservation() {
    _reservations--;
  }

  RecordingTask enqueue(
      {required String title,
      required RecordingInput input,
      required Duration start,
      required Duration end,
      required int videoIndex,
      required int? audioIndex}) {
    final task = RecordingTask(
        id: _id(),
        title: title,
        input: input,
        start: start,
        end: end,
        videoIndex: videoIndex,
        audioIndex: audioIndex,
        created: DateTime.now());
    _reservations--;
    _tasks.insert(0, task);
    notifyListeners();
    unawaited(_save(task).then((_) => _pump()));
    return task;
  }

  static String _id() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}_${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  static String safeFileName(String title, String id) {
    final clean =
        title.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_').trim();
    return '${String.fromCharCodes(clean.runes.take(40))}_$id';
  }

  void _pump() {
    if (_running) return;
    final queued = _tasks.where((t) => t.status == RecordingTaskStatus.queued);
    if (queued.isEmpty) return;
    _running = true;
    unawaited(_run(queued.last).whenComplete(() {
      _running = false;
      _pump();
    }));
  }

  Future<void> _run(RecordingTask task) async {
    StreamSubscription<ExportProgress>? subscription;
    task.status = RecordingTaskStatus.exporting;
    notifyListeners();
    try {
      await _save(task);
      if (task._cancelRequested) {
        task.status = RecordingTaskStatus.cancelled;
        return;
      }
      final input = task.input!;
      final relativeStart = input is CachedRecordingInput
          ? input.lease.relativeStart
          : task.start;
      final handle = await backend.exportClip(ClipExportRequest(
        taskId: task.id,
        input: input,
        outputDirectory: directory.path,
        fileName: safeFileName(task.title, task.id),
        start: relativeStart,
        duration: task.duration,
        videoStreamIndex: task.videoIndex,
        audioStreamIndex: task.audioIndex,
        encoding: task.encoding,
      ));
      task._handle = handle;
      subscription = handle.progress.listen((progress) {
        if (progress.taskId != task.id) return;
        task.stage = progress.stage;
        task.progress = progress.mediaTime;
        notifyListeners();
      });
      if (task._cancelRequested) {
        try {
          await handle.cancel();
        } catch (_) {/* Still await the native writer. */}
      }
      final result = await handle.completed;
      task.status = switch (result.status) {
        ExportStatus.savedLocal => RecordingTaskStatus.saved,
        ExportStatus.cancelled => RecordingTaskStatus.cancelled,
        ExportStatus.failed => task._cancelRequested
            ? RecordingTaskStatus.cancelled
            : RecordingTaskStatus.failed,
      };
      task.localPath = result.localPath;
      task.error = result.failure?.message;
      if (result.localPath != null) {
        // The hash records the bytes that passed the backend's full validation.
        task.digest =
            (await sha256.bind(File(result.localPath!).openRead()).first)
                .toString();
      }
    } catch (error) {
      if (task.status != RecordingTaskStatus.saved) {
        task.status = task._cancelRequested
            ? RecordingTaskStatus.cancelled
            : RecordingTaskStatus.failed;
      }
      task.error =
          error is RecordingFailure ? error.message : '生成视频失败，请重试或放弃此任务';
    } finally {
      await subscription?.cancel();
      task._handle = null;
      if (task.status != RecordingTaskStatus.failed) await _releaseInput(task);
      await _save(task);
      notifyListeners();
    }
  }

  Future<void> cancel(RecordingTask task) async {
    if (!task.busy) return;
    task._cancelRequested = true;
    if (task.status == RecordingTaskStatus.queued) {
      task.status = RecordingTaskStatus.cancelled;
      await _releaseInput(task);
      await _save(task);
    } else {
      await task._handle?.cancel();
    }
    notifyListeners();
  }

  void retry(RecordingTask task,
      {ClipEncoding encoding = ClipEncoding.streamCopy}) {
    if (!task.canRetry) return;
    task.encoding = encoding;
    task.status = RecordingTaskStatus.queued;
    task.error = null;
    task._cancelRequested = false;
    task.progress = Duration.zero;
    notifyListeners();
    unawaited(_save(task).then((_) => _pump()));
  }

  /// Explicitly abandon failed/cancelled tasks. Saved files use a separate action.
  Future<void> remove(RecordingTask task, {bool deleteFile = false}) async {
    if (task.busy) return;
    if (deleteFile &&
        task.localPath != null &&
        p.isWithin(directory.path, task.localPath!)) {
      final file = File(task.localPath!);
      if (await file.exists()) await file.delete();
    }
    await _releaseInput(task);
    await _writes.synchronized(() async {
      final manifest = File(p.join(directory.path, '${task.id}.json'));
      if (await manifest.exists()) await manifest.delete();
      _tasks.remove(task);
    });
    notifyListeners();
  }

  Future<void> _releaseInput(RecordingTask task) async {
    final input = task.input;
    task.input = null;
    if (input is CachedRecordingInput) await input.lease.release();
  }

  Future<void> _save(RecordingTask task) => _writes.synchronized(() async {
        if (!_tasks.contains(task)) return;
        try {
          await directory.create(recursive: true);
          final file = File(p.join(directory.path, '${task.id}.json.partial'));
          await file.writeAsString(
              jsonEncode({
                'version': 1,
                'id': task.id,
                'title': task.title,
                'start': task.start.inMicroseconds,
                'end': task.end.inMicroseconds,
                'created': task.created.toIso8601String(),
                'status': task.status.name,
                'file': task.localPath == null
                    ? null
                    : p.relative(task.localPath!, from: directory.path),
                'digest': task.digest,
              }),
              flush: true);
          await file.rename(p.join(directory.path, '${task.id}.json'));
          task.persistenceError = null;
        } catch (_) {
          task.persistenceError = '任务记录保存失败；请保留已生成文件的路径';
        }
      });

  Future<void> restore() async {
    await directory.create(recursive: true);
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !RegExp(r'^\d+_[a-f0-9]{16}\.json$')
              .hasMatch(p.basename(entity.path))) {
        continue;
      }
      try {
        if (await entity.length() > 65536) continue;
        final data =
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        final id = data['id'] as String;
        if ('$id.json' != p.basename(entity.path)) continue;
        final task = RecordingTask(
            id: id,
            title: data['title'] as String,
            start: Duration(microseconds: data['start'] as int),
            end: Duration(microseconds: data['end'] as int),
            created: DateTime.parse(data['created'] as String));
        task.status = RecordingTaskStatus.failed;
        task.error = '上次任务已中断，缓存无法恢复，请重新录制';
        final relative = data['file'] as String?;
        if (relative != null && !p.isAbsolute(relative)) {
          final path = p.normalize(p.join(directory.path, relative));
          if (p.isWithin(directory.path, path) &&
              await File(path).exists() &&
              p.isWithin(await directory.resolveSymbolicLinks(),
                  await File(path).resolveSymbolicLinks()) &&
              data['digest'] != null &&
              (await sha256.bind(File(path).openRead()).first).toString() ==
                  data['digest']) {
            task.localPath = path;
            task.digest = data['digest'] as String;
            task.status = RecordingTaskStatus.saved;
            task.error = null;
          } else {
            task.error = '成品不存在或内容已改变，未作为有效录制恢复';
          }
        } else if (data['status'] == RecordingTaskStatus.cancelled.name) {
          task.status = RecordingTaskStatus.cancelled;
          task.error = null;
        }
        _tasks.add(task);
      } catch (_) {
        /* Ignore incomplete metadata; never promote partial outputs. */
      }
    }
    _tasks.sort((a, b) => b.created.compareTo(a.created));
    notifyListeners();
  }
}

Future<RecordingService>? _shared;
Future<RecordingService> sharedRecordingService() => _shared ??= () async {
      try {
        Directory? base;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          try {
            base = await getDownloadsDirectory();
          } catch (_) {}
        }
        base ??= await getApplicationDocumentsDirectory();
        var directory = Directory(p.join(base.path, 'AnimeFlow', 'Recordings'));
        try {
          await directory.create(recursive: true);
        } on FileSystemException {
          directory = Directory(p.join(
              (await getApplicationDocumentsDirectory()).path,
              'AnimeFlow',
              'Recordings'));
        }
        final service = RecordingService(
            directory: directory, backend: const FfmpegRecordingBackend());
        await service.restore();
        return service;
      } catch (_) {
        _shared = null;
        rethrow;
      }
    }();
