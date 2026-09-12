import 'dart:async';
import 'dart:io';

import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';
import 'package:anime_flow/features/recording/infrastructure/ffmpeg_kit_runner.dart';
import 'package:anime_flow/features/recording/application/recording_controller.dart';
import 'package:anime_flow/features/recording/application/recording_service.dart';
import 'package:anime_flow/features/recording/infrastructure/ffmpeg_recording_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Native regression test, not an application/demo entry point.
// flutter test integration_test/hls_shared_cache_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  testWidgets('mpv, MDK and FFmpeg reuse one authenticated HLS cache',
      (tester) async {
    final root =
        await (await getTemporaryDirectory()).createTemp('hls-native-test-');
    final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final cache =
        HlsMediaCache(directory: Directory(p.join(root.path, 'cache')));
    final counts = <String, int>{};
    final engines = <PlayerEngine>[
      MediaKitEngine(adBlocker: false, hardwareDecoder: false),
      FvpEngine(hardwareDecoder: false),
    ];
    const runner = FfmpegKitRunner();
    const backend = FfmpegRecordingBackend(runner: runner);
    final service = RecordingService(
        directory: Directory(p.join(root.path, 'recordings')),
        backend: backend);
    Future<void> execute(List<String> arguments) async {
      final command = await runner.start(arguments);
      final result = await command.completed
          .timeout(const Duration(seconds: 60), onTimeout: () async {
        await command.cancel();
        await command.completed;
        throw TimeoutException('Native FFmpeg timeout');
      });
      expect(result.returnCode, 0, reason: result.output);
    }

    Future<List<String>> frameHashes(String input, String name) async {
      final output = File(p.join(root.path, '$name.framemd5'));
      await execute([
        '-v',
        'error',
        '-i',
        input,
        '-map',
        '0:v:0',
        '-f',
        'framemd5',
        output.path
      ]);
      return (await output.readAsLines())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split(',').last.trim())
          .toList();
    }

    HlsCacheSession? session;
    HlsCacheLease? lease;
    final errors = <Object>[];
    final subscriptions = <StreamSubscription<PlayerEvent>>[];
    try {
      await execute([
        '-v',
        'error',
        '-nostdin',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc2=size=320x180:rate=25',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=880:sample_rate=48000',
        '-t',
        '6',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-g',
        '50',
        '-sc_threshold',
        '0',
        '-c:a',
        'aac',
        '-f',
        'hls',
        '-hls_time',
        '2',
        '-hls_playlist_type',
        'vod',
        '-hls_segment_filename',
        p.join(root.path, 's%d.ts'),
        p.join(root.path, 'index.m3u8'),
      ]);
      final sourceFrames =
          await frameHashes(p.join(root.path, 'index.m3u8'), 'source');
      expect(sourceFrames, hasLength(150));
      origin.listen((request) async {
        if (request.headers.value('authorization') != 'Bearer test-only') {
          request.response.statusCode = 401;
          await request.response.close();
          return;
        }
        final name = request.uri.pathSegments.single;
        if (!RegExp(r'^(index\.m3u8|s\d+\.ts)$').hasMatch(name)) {
          request.response.statusCode = 404;
        } else {
          counts.update(name, (n) => n + 1, ifAbsent: () => 1);
          final file = File(p.join(root.path, name));
          request.response.headers.set('cache-control', 'max-age=600');
          request.response.contentLength = await file.length();
          await request.response.addStream(file.openRead());
        }
        await request.response.close();
      });
      session = await cache.open(PlaybackSource(
        uri: Uri.parse('http://127.0.0.1:${origin.port}/index.m3u8'),
        headers: const {'Authorization': 'Bearer test-only'},
      ));
      lease = session.retainRange(Duration.zero, session.timeline.duration);
      for (final engine in engines) {
        final recorder =
            RecordingController(serviceFactory: () async => service);
        var currentPosition = Duration.zero;
        await engine.initialize();
        subscriptions.add(engine.events.listen((e) {
          if (e is PlayerError) errors.add(e.error);
        }));
        await tester.pumpWidget(MaterialApp(
            home: SizedBox(
                width: 320,
                height: 180,
                child: engine.buildVideoSurface(fit: BoxFit.contain))));
        var progressed = false;
        final startAt = engine == engines.first ? 300 : 4300;
        subscriptions.add(engine.events.listen((e) {
          if (e is PlayerPositionChanged &&
              e.position.inMilliseconds > startAt) {
            progressed = true;
          }
          if (e is PlayerPositionChanged) {
            currentPosition = e.position;
            recorder.updatePosition(e.position);
          }
        }));
        await engine.open(session.playbackSource, autoPlay: true);
        for (var i = 0; i < 200 && !progressed; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(progressed, isTrue,
            reason: '${engine.kernel} did not play through proxy');
        final screenshot = await engine.screenshot();
        expect(screenshot, isNotNull);
        expect(screenshot, isNotEmpty);
        final originalKernel = engine.kernel;
        await recorder.start(
            title: '${engine.kernel.name} test',
            position: currentPosition,
            cache: session);
        expect(recorder.value.status, RecordingMarkerStatus.marking,
            reason: recorder.value.message);
        final stopAt = engine == engines.first ? 3300 : 5700;
        for (var i = 0;
            i < 100 && currentPosition.inMilliseconds < stopAt;
            i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final task = recorder.freeze();
        expect(task, isNotNull);
        recorder.dispose();
        if (engine == engines.last) {
          // A frozen job is independent of the playback owner and controller.
          await engine.stop();
          await session.releasePlayback();
          await lease.release();
        }
        for (var i = 0; i < 600 && task!.busy; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(task!.status, RecordingTaskStatus.saved, reason: task.error);
        expect(engine.kernel, originalKernel);
        final clipFrames =
            await frameHashes(task.localPath!, engine.kernel.name);
        expect(clipFrames, isNotEmpty);
        final firstSourceFrame = sourceFrames.indexOf(clipFrames.first);
        final lastSourceFrame = sourceFrames.indexOf(clipFrames.last);
        expect(firstSourceFrame, greaterThanOrEqualTo(0));
        expect(lastSourceFrame, greaterThanOrEqualTo(firstSourceFrame));
        // Compare decoded content with the fixture, not only container duration.
        expect(
            firstSourceFrame / 25,
            inInclusiveRange(
                (task.start.inMilliseconds / 1000 - 2.2).clamp(0, 6),
                task.start.inMilliseconds / 1000 + .2));
        expect(
            lastSourceFrame / 25, closeTo(task.end.inMilliseconds / 1000, .25));
        final probe = await backend.probe(task.localPath!);
        expect(probe.hasAudio, isTrue);
        expect(probe.streams.any((s) => s.type == 'video'), isTrue);
        // Fixture GOP is two seconds. Stream copy may include a preceding GOP.
        expect(
            probe.duration.inMilliseconds,
            inInclusiveRange(
                (task.duration.inMilliseconds - 200).clamp(500, 10000),
                task.duration.inMilliseconds + 2200));
        if (engine == engines.last) {
          expect(task.start.inMilliseconds, greaterThan(4000));
        }
        await engine.stop();
      }
      expect(errors, isEmpty);
      expect(counts['index.m3u8'], 1);
      final segmentCounts = counts.entries
          .where((e) => e.key.endsWith('.ts'))
          .map((e) => e.value)
          .toList();
      expect(segmentCounts, hasLength(3));
      expect(segmentCounts, everyElement(1));
      expect(service.tasks, hasLength(2));
      expect(
          service.tasks
              .every((task) => task.status == RecordingTaskStatus.saved),
          isTrue);
      expect(counts.values, everyElement(1));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      for (final engine in engines) {
        await engine.dispose();
      }
      await session?.releasePlayback();
      await lease?.release();
      await cache.close();
      await origin.close(force: true);
      await root.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
