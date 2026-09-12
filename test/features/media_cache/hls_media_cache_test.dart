import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/features/media_cache/application/hls_media_cache.dart';
import 'package:anime_flow/features/media_cache/domain/hls_snapshot.dart';
import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late HttpServer origin;
  late HttpClient client;
  late HlsMediaCache cache;
  late Uri base;
  final counts = <String, int>{};
  final seenHeaders = <String, Map<String, String>>{};
  final gates = <String, Completer<void>>{};
  final entered = <String, Completer<void>>{};
  final playlists = <String, String>{};
  var playlist = '';
  var cacheControl = 'max-age=600';
  var revision = 0;
  String? redirect;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hls-cache-test-');
    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = HttpClient();
    base = Uri.parse('http://127.0.0.1:${origin.port}/');
    cache = HlsMediaCache(
        directory: Directory(p.join(root.path, 'cache')),
        capacityBytes: 4000,
        maxSegmentBytes: 600,
        maxDownloads: 2);
    counts.clear();
    playlists.clear();
    seenHeaders.clear();
    gates.clear();
    entered.clear();
    playlist = _playlist();
    cacheControl = 'max-age=600';
    revision = 0;
    redirect = null;
    origin.listen((request) async {
      final name = request.uri.path;
      counts.update(name, (n) => n + 1, ifAbsent: () => 1);
      seenHeaders[name] = {
        for (final key in [
          'cookie',
          'authorization',
          'x-token',
          'referer',
          'user-agent'
        ])
          key: request.headers.value(key) ?? ''
      };
      if (entered[name] != null && !entered[name]!.isCompleted) {
        entered[name]!.complete();
      }
      if (gates[name] != null) await gates[name]!.future;
      if (name == '/redirect.m3u8') {
        request.response.statusCode = 302;
        request.response.headers.set('location', redirect ?? 'index.m3u8');
      } else if (name.endsWith('.m3u8')) {
        request.response.write(playlists[name] ?? playlist);
      } else {
        final bytes = _transportBytes(revision);
        request.response.headers.set('cache-control', cacheControl);
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    for (final gate in gates.values) {
      if (!gate.isCompleted) gate.complete();
    }
    client.close(force: true);
    await cache.close();
    await origin.close(force: true);
    await root.delete(recursive: true);
  });

  Future<HlsCacheSession> open({Map<String, String> headers = const {}}) =>
      cache.open(
          PlaybackSource(uri: base.resolve('index.m3u8'), headers: headers));
  Future<(int, List<int>, HttpHeaders)> get(Uri uri,
      {String? range, String method = 'GET'}) async {
    final request = await client.openUrl(method, uri);
    if (range != null) request.headers.set('range', range);
    final response = await request.close();
    final bytes = await response
        .fold<List<int>>([], (list, chunk) => list..addAll(chunk));
    return (response.statusCode, bytes, response.headers);
  }

  test(
      'playlist rewriting keeps sequence and timing, and contains only proxy routes',
      () async {
    final session =
        await open(headers: {'Cookie': 'secret', 'X-Token': 'token'});
    final result = await get(session.playbackSource.uri);
    final content = utf8.decode(result.$2);
    expect(content, contains('#EXT-X-MEDIA-SEQUENCE:40'));
    expect(content, contains('#EXTINF:2.000000'));
    expect(content, isNot(contains('secret')));
    expect(content, isNot(contains(base.resolve('s0.ts').toString())));
    expect(session.playbackSource.headers, isEmpty);
    expect(seenHeaders['/s0.ts']!['cookie'], 'secret');
    expect(seenHeaders['/s0.ts']!['x-token'], 'token');
    await session.releasePlayback();
  });

  test(
      'concurrent playback/export and later cache hits download each segment once',
      () async {
    final session = await open();
    entered['/s1.ts'] = Completer<void>();
    gates['/s1.ts'] = Completer<void>();
    final playback = get(session.segmentUri(1));
    await entered['/s1.ts']!.future;
    final exporting = get(session.exportSegmentUri(1));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    gates['/s1.ts']!.complete();
    final results = await Future.wait([playback, exporting]);
    expect(results.every((r) => r.$1 == 200), isTrue);
    expect(results[0].$2, results[1].$2);
    await get(session.segmentUri(1));
    expect(counts['/s1.ts'], 1);
    await session.releasePlayback();
  });

  test(
      'leases preserve old session and finite relative playlist after playback release',
      () async {
    final session = await open();
    final lease = session.retainRange(
        const Duration(seconds: 3), const Duration(seconds: 4));
    lease.extend(const Duration(seconds: 5));
    expect(lease.relativeStart, const Duration(seconds: 3));
    await session.releasePlayback();
    final result = await get(lease.playlistUri);
    expect(result.$1, 200);
    expect(utf8.decode(result.$2), contains('export-seg-2.ts'));
    expect((await get(session.exportSegmentUri(2))).$1, 200);
    final directory = session.directory;
    await lease.release();
    // The client can finish receiving bytes before the server releases its
    // response reference. Cleanup follows the final reader, not lease release.
    final cleanupDeadline = DateTime.now().add(const Duration(seconds: 2));
    while (
        await directory.exists() && DateTime.now().isBefore(cleanupDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await directory.exists(), isFalse);
    expect((await get(session.playbackSource.uri)).$1, 404);
  });

  test(
      'serves HEAD, suffix, open and bounded ranges from completed cached segments',
      () async {
    final session = await open();
    final full = _transportBytes(0);
    final head = await get(session.segmentUri(0), method: 'HEAD');
    expect(head.$1, 200);
    expect(head.$2, isEmpty);
    expect(head.$3.contentLength, full.length);
    for (final entry in {
      'bytes=0-9': full.sublist(0, 10),
      'bytes=-10': full.sublist(full.length - 10),
      'bytes=560-': full.sublist(560)
    }.entries) {
      final response = await get(session.segmentUri(0), range: entry.key);
      expect(response.$1, 206);
      expect(response.$2, entry.value);
    }
    for (final invalid in [
      'bytes=999-',
      'bytes=3-2',
      'bytes=0-1,3-4',
      'bytes=-'
    ]) {
      expect((await get(session.segmentUri(0), range: invalid)).$1, 416);
    }
    expect(counts['/s0.ts'], 1);
    await session.releasePlayback();
  });

  test(
      'unknown token/routes cannot forward arbitrary URLs or release valid sessions',
      () async {
    final session = await open();
    expect(
        (await get(session.playbackSource.uri
                .replace(path: '/unknown/index.m3u8')))
            .$1,
        404);
    expect(
        (await get(session.playbackSource.uri
                .replace(query: 'url=https://example.com')))
            .$1,
        404);
    expect(
        (await get(session.playbackSource.uri
                .replace(path: '/${session.id}/secret.txt')))
            .$1,
        404);
    expect((await get(session.segmentUri(0))).$1, 200);
    expect(counts.keys, unorderedEquals(['/index.m3u8', '/s0.ts']));
    await session.releasePlayback();
  });

  test('different authentication snapshots never share resources', () async {
    final headers = {'Cookie': 'one'};
    final first = await open(headers: headers);
    headers['Cookie'] = 'two';
    final second = await open(headers: headers);
    expect(first.id, isNot(second.id));
    expect(first.source.headers['Cookie'], 'one');
    expect(counts['/s0.ts'], 2);
    await first.releasePlayback();
    await second.releasePlayback();
  });

  test('cross-origin redirects strip cookies, auth and custom tokens',
      () async {
    final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => other.close(force: true));
    Map<String, String?>? forwarded;
    other.listen((r) async {
      forwarded = {
        for (final key in ['cookie', 'authorization', 'x-token'])
          key: r.headers.value(key)
      };
      r.response.write(_playlist(base: base.toString()));
      await r.response.close();
    });
    redirect = 'http://127.0.0.1:${other.port}/media.m3u8';
    final session = await cache.open(PlaybackSource(
        uri: base.resolve('redirect.m3u8'),
        headers: const {
          'Cookie': 'private',
          'Authorization': 'Bearer private',
          'X-Token': 'private'
        }));
    expect(forwarded!.values, everyElement(isNull));
    await session.releasePlayback();
  });

  test(
      'changed expired resource invalidates the source instead of mixing bytes',
      () async {
    cacheControl = 'max-age=0';
    final session = await open();
    revision = 1;
    expect((await get(session.segmentUri(0))).$1, 502);
    expect((await get(session.segmentUri(1))).$1, 502);
    expect(counts['/s1.ts'], isNull);
    await session.releasePlayback();
  });

  test('capacity evicts unpinned LRU segments but never retained ranges',
      () async {
    await cache.close();
    cache = HlsMediaCache(
        directory: Directory(p.join(root.path, 'small')),
        capacityBytes: 1200,
        maxSegmentBytes: 600);
    final session = await open();
    await get(session.segmentUri(1));
    await get(session.segmentUri(2));
    await get(session.segmentUri(0));
    expect(counts['/s0.ts'], 2);
    final lease =
        session.retainRange(Duration.zero, const Duration(seconds: 4));
    await get(session.segmentUri(1));
    expect((await get(session.segmentUri(2))).$1, 502);
    expect(cache.cachedBytes, lessThanOrEqualTo(1200));
    await lease.release();
    await session.releasePlayback();
  });

  test('queued playback runs before background transfers with a reserved slot',
      () async {
    final session = await open();
    entered['/s1.ts'] = Completer<void>();
    gates['/s1.ts'] = Completer<void>();
    final background = get(session.exportSegmentUri(1));
    await entered['/s1.ts']!.future;
    final secondBackground = get(session.exportSegmentUri(2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final play = await get(session.segmentUri(3));
    expect(play.$1, 200);
    expect(counts['/s2.ts'], isNull);
    gates['/s1.ts']!.complete();
    await Future.wait([background, secondBackground]);
    await session.releasePlayback();
  });

  test('disconnecting one consumer does not cancel the shared transfer',
      () async {
    final session = await open();
    entered['/s1.ts'] = Completer<void>();
    gates['/s1.ts'] = Completer<void>();
    final request = await client.getUrl(session.segmentUri(1));
    final abandoned = request.close().then<void>((r) async {
      await r.drain<void>();
    }).catchError((Object _) {});
    await entered['/s1.ts']!.future;
    final survivor = get(session.exportSegmentUri(1));
    request.abort();
    gates['/s1.ts']!.complete();
    expect((await survivor).$1, 200);
    await abandoned;
    expect(counts['/s1.ts'], 1);
    await session.releasePlayback();
  });

  test('unsupported variants are rejected before media downloads', () async {
    for (final tag in [
      '#EXT-X-KEY:METHOD=AES-128,URI="key"',
      '#EXT-X-MAP:URI="init.mp4"',
      '#EXT-X-BYTERANGE:10@0',
      '#EXT-X-DISCONTINUITY',
      '#EXT-X-PART:DURATION=1,URI="part"'
    ]) {
      playlist = _playlist().replaceFirst('#EXTINF', '$tag\n#EXTINF');
      await expectLater(open(), throwsA(isA<MediaCacheException>()));
    }
    playlist = _playlist().replaceAll('#EXT-X-ENDLIST', '');
    await expectLater(open(), throwsA(isA<MediaCacheException>()));
    expect(counts['/s0.ts'], isNull);
  });

  test(
      'master fixes highest rendition and resolves redirected relative segment paths',
      () async {
    playlist =
        '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=100\nlow/index.m3u8\n#EXT-X-STREAM-INF:BANDWIDTH=200\nhigh/index.m3u8\n';
    playlists['/high/index.m3u8'] = _playlist();
    final session = await open();
    expect(counts['/high/index.m3u8'], 1);
    expect(counts['/high/s0.ts'], 1);
    expect(counts['/low/index.m3u8'], isNull);
    await session.releasePlayback();
    final timeline =
        HlsSnapshot.parse(_playlist(), base.resolve('sub/index.m3u8'));
    expect(timeline.segments.first.uri, base.resolve('sub/s0.ts').toString());
    final range =
        timeline.range(const Duration(seconds: 5), const Duration(seconds: 7));
    expect(range.$1, 1);
    expect(range.$2, 3);
    expect(range.$3, const Duration(seconds: 2));
    final boundary =
        timeline.range(const Duration(seconds: 2), const Duration(seconds: 2));
    expect(boundary.$1, 0);
    expect(boundary.$2, 1,
        reason: 'Retain both preceding and starting segments');
  });

  test(
      'same-origin redirects resolve against final playlist and keep credentials',
      () async {
    redirect = 'sub/index.m3u8';
    final session = await cache.open(PlaybackSource(
        uri: base.resolve('redirect.m3u8'),
        headers: const {'Cookie': 'private'}));
    expect(counts['/sub/s0.ts'], 1);
    expect(seenHeaders['/sub/s0.ts']!['cookie'], 'private');
    await session.releasePlayback();
  });

  test('no-store source is rejected without publishing cached bytes', () async {
    cacheControl = 'no-store';
    await expectLater(open(), throwsA(isA<MediaCacheException>()));
    expect(cache.cachedBytes, 0);
  });
}

String _playlist({String base = ''}) =>
    '#EXTM3U\n#EXT-X-TARGETDURATION:2\n#EXT-X-MEDIA-SEQUENCE:40\n${List.generate(4, (i) => '#EXTINF:2,\n${base}s$i.ts').join('\n')}\n#EXT-X-ENDLIST\n';
Uint8List _transportBytes(int revision) {
  final bytes = Uint8List(188 * 3)..fillRange(0, 188 * 3, revision);
  bytes[0] = bytes[188] = bytes[376] = 0x47;
  return bytes;
}
