import 'dart:async';
import 'dart:io';

import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:anime_flow/features/play/domain/player/player_engine.dart';
import 'package:anime_flow/features/play/domain/player/player_event.dart';
import 'package:anime_flow/features/play/infrastructure/player/fvp/fvp_engine.dart';
import 'package:anime_flow/features/play/infrastructure/player/media_kit/media_kit_engine.dart';
import 'package:anime_flow/features/recording/infrastructure/ffmpeg_kit_runner.dart';
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
    final backend = FfmpegRecordingBackend(runner: runner);
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
        subscriptions.add(engine.events.listen((e) {
          if (e is PlayerPositionChanged &&
              e.position > const Duration(milliseconds: 200)) {
            progressed = true;
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
        final output = p.join(root.path, '${engine.kernel.name}.mkv');
        await execute([
          '-v',
          'error',
          '-nostdin',
          '-y',
          '-protocol_whitelist',
          'http,tcp',
          '-i',
          lease.playlistUri.toString(),
          '-map',
          '0:v:0',
          '-map',
          '0:a:0',
          '-c',
          'copy',
          output,
        ]);
        final probe = await backend.probe(output);
        expect(probe.hasAudio, isTrue);
        expect(probe.streams.any((s) => s.type == 'video'), isTrue);
        expect(probe.duration.inMilliseconds, inInclusiveRange(5800, 6300));
        await execute([
          '-v',
          'error',
          '-xerror',
          '-i',
          output,
          '-map',
          '0:v:0',
          '-map',
          '0:a:0',
          '-f',
          'null',
          '-'
        ]);
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
      await session.releasePlayback();
      // The lease must keep the proxy alive after the playback owner is gone.
      await execute([
        '-v',
        'error',
        '-protocol_whitelist',
        'http,tcp',
        '-i',
        lease.playlistUri.toString(),
        '-f',
        'null',
        '-'
      ]);
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
