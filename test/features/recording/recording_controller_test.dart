import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/recording/application/recording_controller.dart';
import 'package:anime_flow/features/recording/application/recording_service.dart';
import 'package:anime_flow/features/recording/domain/recording_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'recording_test_support.dart';

void main() {
  late Directory root;
  late RecordingService service;
  late RecordingController controller;
  late ControlledRecordingBackend backend;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('recording-controller-');
    backend = ControlledRecordingBackend();
    service = RecordingService(directory: root, backend: backend);
    controller = RecordingController(serviceFactory: () async => service);
  });
  tearDown(() async {
    controller.dispose();
    for (final handle in backend.handles) {
      if (!handle.done.isCompleted) handle.finish(ExportStatus.cancelled);
    }
    await eventually(() => service.tasks.every((t) => !t.busy));
    for (final task in service.tasks) {
      await service.remove(task);
    }
    await root.delete(recursive: true);
  });
  Future<void> start([int seconds = 2]) => controller.start(
      title: 'Title E1',
      position: Duration(seconds: seconds),
      localPath: p.join(root.path, 'source.mp4'));

  test('media positions define intervals and exports allow the next marker',
      () async {
    await start();
    controller.updatePosition(const Duration(seconds: 5));
    controller
        .updatePosition(const Duration(seconds: 5)); // buffering adds no time
    final first = controller.freeze()!;
    await eventually(() => backend.requests.length == 1);
    expect(backend.requests.single.duration, const Duration(seconds: 3));
    expect(backend.requests.single.audioStreamIndex, 2);
    await start(8);
    controller.updatePosition(const Duration(seconds: 10));
    controller.freeze();
    expect(service.tasks.first.status, RecordingTaskStatus.queued);
    backend.handles.first.finish(ExportStatus.cancelled);
    await eventually(() => backend.requests.length == 2);
    expect(first.status, RecordingTaskStatus.cancelled);
    backend.handles.last.finish(ExportStatus.cancelled);
  });

  test(
      'source/seek invalidation during preparation cannot publish a stale marker',
      () async {
    backend.probeGate = Completer<void>();
    final pending = start();
    await Future<void>.delayed(Duration.zero);
    controller.freeze();
    backend.probeGate!.complete();
    await pending;
    expect(controller.value.status, RecordingMarkerStatus.idle);
    expect(service.tasks, isEmpty);
    backend.probeGate = null;
    await start(20);
    expect(controller.value.start, const Duration(seconds: 20));
    controller.freeze();
  });

  test('ambiguous audio tracks and tiny clips do not enter the export queue',
      () async {
    backend.multiAudio = true;
    await start();
    expect(controller.active, isFalse);
    expect(controller.value.message, contains('音轨'));
    backend.multiAudio = false;
    await start();
    controller.updatePosition(const Duration(milliseconds: 2200));
    expect(controller.freeze(), isNull);
    expect(service.tasks, isEmpty);
  });

  test('disposing a playback controller freezes its marker into the app queue',
      () async {
    final other = RecordingController(serviceFactory: () async => service);
    await other.start(
        title: 'Old page',
        position: Duration.zero,
        localPath: p.join(root.path, 'source.mp4'));
    other.updatePosition(const Duration(seconds: 2));
    other.dispose();
    expect(service.tasks.single.duration, const Duration(seconds: 2));
    await eventually(() => backend.handles.isNotEmpty);
    backend.handles.single.finish(ExportStatus.cancelled);
  });

  test(
      'interrupted metadata is visible but cannot reuse an unvalidated partial',
      () async {
    const id = '123456_0123456789abcdef';
    await File(p.join(root.path, 'clip.partial.mkv'))
        .writeAsString('incomplete');
    await File(p.join(root.path, '$id.json')).writeAsString(jsonEncode({
      'version': 1,
      'id': id,
      'title': 'Interrupted',
      'start': 0,
      'end': 2000000,
      'created': DateTime.now().toIso8601String(),
      'status': 'exporting',
    }));
    await service.restore();
    expect(service.tasks.single.status, RecordingTaskStatus.failed);
    expect(service.tasks.single.canRetry, isFalse);
    expect(service.tasks.single.localPath, isNull);
  });

  test(
      'unexpected backward position freezes old interval without joining timelines',
      () async {
    await start(10);
    controller.updatePosition(const Duration(seconds: 13));
    controller.updatePosition(const Duration(seconds: 2));
    expect(service.tasks.single.end, const Duration(seconds: 13));
    expect(controller.active, isFalse);
    await eventually(() => backend.handles.isNotEmpty);
    backend.handles.single.finish(ExportStatus.cancelled);
  });

  test('failed tasks retain bounded inputs for retry or explicit discard',
      () async {
    for (var i = 0; i < 3; i++) {
      await start();
      controller.updatePosition(const Duration(seconds: 4));
      controller.freeze();
      await eventually(() => backend.handles.length == i + 1);
      backend.handles.last.finish(ExportStatus.failed);
      await eventually(() => service.tasks.every((t) => !t.busy));
    }
    await start();
    expect(controller.active, isFalse);
    expect(controller.value.message, contains('最多'));
    final task = service.tasks.first;
    service.retry(task, encoding: ClipEncoding.h264Aac);
    await eventually(() => backend.handles.length == 4);
    expect(backend.requests.last.encoding, ClipEncoding.h264Aac);
    backend.handles.last.finish(ExportStatus.failed);
    await eventually(() => !task.busy);
    await service.remove(task);
    await start();
    expect(controller.active, isTrue);
    controller.freeze();
  });

  test('cancel while handle creation is pending waits for native completion',
      () async {
    backend.exportGate = Completer<void>();
    await start();
    controller.updatePosition(const Duration(seconds: 4));
    final task = controller.freeze()!;
    await eventually(() => backend.handles.isNotEmpty);
    await service.cancel(task);
    expect(task.input, isNotNull);
    backend.exportGate!.complete();
    await eventually(() => backend.handles.single.cancelCalled);
    expect(task.input, isNotNull);
    backend.handles.single.finish(ExportStatus.cancelled);
    await eventually(() => task.input == null);
    expect(task.status, RecordingTaskStatus.cancelled);
  });

  test(
      'metadata omits source credentials and restores only validated unchanged files',
      () async {
    await start();
    controller.updatePosition(const Duration(seconds: 4));
    final task = controller.freeze()!;
    await eventually(() => backend.handles.isNotEmpty);
    final output = File(p.join(root.path, 'verified.mkv'));
    await output.writeAsString('validated fixture');
    backend.handles.single.finish(ExportStatus.savedLocal, path: output.path);
    await eventually(() => task.digest != null && task.input == null);
    // Wait for the manifest write after terminal state publication.
    final manifest = File(p.join(root.path, '${task.id}.json'));
    while (!(await manifest.readAsString()).contains('digest":"')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final json = await manifest.readAsString();
    expect(json, isNot(contains('source.mp4')));
    expect(jsonDecode(json)['file'], 'verified.mkv');
    final restored = RecordingService(directory: root, backend: backend);
    await restored.restore();
    expect(restored.tasks.single.status, RecordingTaskStatus.saved);
    await output.writeAsString('changed');
    final changed = RecordingService(directory: root, backend: backend);
    await changed.restore();
    expect(changed.tasks.single.status, RecordingTaskStatus.failed);
    expect(changed.tasks.single.canRetry, isFalse);
  });

  test(
      'cache lease survives playback release and remains on failure until discard',
      () async {
    final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final cache =
        HlsMediaCache(directory: Directory(p.join(root.path, 'cache')));
    origin.listen((request) async {
      if (request.uri.path.endsWith('.m3u8')) {
        request.response.write(
            '#EXTM3U\n#EXT-X-TARGETDURATION:2\n#EXTINF:2,\ns0.ts\n#EXTINF:2,\ns1.ts\n#EXTINF:2,\ns2.ts\n#EXT-X-ENDLIST\n');
      } else {
        final bytes = Uint8List(564);
        bytes[0] = bytes[188] = bytes[376] = 0x47;
        request.response.add(bytes);
      }
      await request.response.close();
    });
    final session = await cache.open(PlaybackSource(
        uri: Uri.parse('http://127.0.0.1:${origin.port}/index.m3u8'),
        headers: const {'Authorization': 'secret'}));
    await controller.start(
        title: 'Cache', position: const Duration(seconds: 3), cache: session);
    controller.updatePosition(const Duration(seconds: 5));
    final task = controller.freeze()!;
    await session.releasePlayback();
    await eventually(() => backend.requests.isNotEmpty);
    final input = backend.requests.single.input as CachedRecordingInput;
    expect(input.lease.isReleased, isFalse);
    expect(backend.requests.single.start, const Duration(seconds: 3));
    backend.handles.single.finish(ExportStatus.failed);
    await eventually(() => !task.busy);
    expect(input.lease.isReleased, isFalse);
    final manifest =
        await File(p.join(root.path, '${task.id}.json')).readAsString();
    expect(manifest, isNot(contains('secret')));
    expect(manifest, isNot(contains('127.0.0.1')));
    await service.remove(task);
    expect(input.lease.isReleased, isTrue);
    await cache.close();
    await origin.close(force: true);
  });
}
