import 'package:anime_flow/features/download/application/download_directory/download_directory_platform.dart';
import 'package:anime_flow/features/download/application/download_directory/impl/ios_download_directory_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('anime_flow/download_storage');
  late IosDownloadDirectoryPlatform platform;
  late List<MethodCall> calls;
  var failRestore = false;
  var cancel = false;
  late Map<String, String> restoredPaths;

  setUp(() {
    platform = IosDownloadDirectoryPlatform();
    calls = [];
    failRestore = false;
    cancel = false;
    restoredPaths = {
      '/old/root': '/new/root',
      '/old/root/nested': '/other/nested',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'restoreAccess':
          if (failRestore) throw PlatformException(code: 'unavailable');
          return restoredPaths;
        case 'selectDirectory':
          return cancel
              ? null
              : {
                  'path': '/picked/root',
                  'paths': {'/picked/root': '/picked/root'},
                };
        case 'verifyWritable':
          throw PlatformException(code: 'read_only');
        case 'prepareDownloadDirectory':
          return '/sandbox/staging/source_1/episode';
        case 'publishDownloadDirectory':
          return '/new/root/source_1/episode';
        case 'prepareForReading':
          return '/sandbox/cache/episode/video.mp4';
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
      'restores moved directories once and preserves relative paths and boundaries',
      () async {
    await Future.wait([platform.initialize(), platform.requestAccess()]);
    expect(calls.where((call) => call.method == 'restoreAccess'), hasLength(1));
    expect(platform.resolvePath('/old/root/source_1/episode/video.mp4'),
        '/new/root/source_1/episode/video.mp4');
    expect(platform.resolvePath('/old/root/nested/video.mp4'),
        '/other/nested/video.mp4');
    expect(platform.resolvePath('/old/root_extra/video.mp4'),
        '/old/root_extra/video.mp4');
    expect(platform.fileExists('/old/root/source_1/episode/video.mp4'), isTrue);
  });

  test('failed initialization can be retried', () async {
    failRestore = true;
    await expectLater(platform.initialize(), throwsA(isA<PlatformException>()));
    failRestore = false;
    await platform.initialize();
    expect(platform.resolvePath('/old/root'), '/new/root');
  });

  test('restores paths created between successive directory moves', () async {
    restoredPaths = {'/A': '/B', '/B': '/B'};
    await platform.initialize();
    final middleMedia = platform.resolvePath('/A/source_1/episode/video.mp4');
    expect(middleMedia, '/B/source_1/episode/video.mp4');

    // A new instance represents the next launch after moving B to C. Native
    // storage supplies every historical alias, not just the originally picked A.
    restoredPaths = {'/A': '/C', '/B': '/C', '/C': '/C'};
    platform = IosDownloadDirectoryPlatform();
    await platform.initialize();
    expect(platform.resolvePath(middleMedia), '/C/source_1/episode/video.mp4');
    expect(platform.resolvePath('/A/source_1/episode/danmaku.json'),
        '/C/source_1/episode/danmaku.json');
    expect(platform.resolvePath('/B_extra/video.mp4'), '/B_extra/video.mp4');
    expect(platform.fileExists(middleMedia), isTrue);

    await platform.prepareDownloadDirectory('/B/source_1/episode');
    expect((calls.last.arguments as Map)['path'], '/C/source_1/episode');
    await platform.prepareForReading(middleMedia);
    expect(
        (calls.last.arguments as Map)['path'], '/C/source_1/episode/video.mp4');
    await platform.deleteDirectory('/B/source_1/episode');
    expect((calls.last.arguments as Map)['path'], '/C/source_1/episode');
  });

  test('selection incorporates bookmark paths and cancellation preserves them',
      () async {
    expect(await platform.selectDirectory(dialogTitle: 'Downloads'),
        '/picked/root');
    expect(platform.fileExists('/picked/root/episode/video.mp4'), isTrue);
    cancel = true;
    expect(await platform.selectDirectory(dialogTitle: 'Downloads'), isNull);
    expect(platform.resolvePath('/old/root/video.mp4'), '/new/root/video.mp4');
  });

  test('native write denial becomes a directory validation error', () async {
    await expectLater(platform.verifyWritable('/old/root'),
        throwsA(isA<DownloadDirectoryNotWritableException>()));
    expect((calls.last.arguments as Map)['path'], '/new/root');
  });

  test(
      'stages transfers, publishes, and coordinates playback, sidecars and deletion',
      () async {
    final staging =
        await platform.prepareDownloadDirectory('/old/root/source_1/episode');
    expect(staging, '/sandbox/staging/source_1/episode');
    final published = await platform.publishDownloadDirectory(staging);
    expect(published, '/new/root/source_1/episode');
    await platform.discardDownloadStaging(staging);
    expect(
        await platform
            .prepareForReading('/old/root/source_1/episode/video.mp4'),
        '/sandbox/cache/episode/video.mp4');
    await platform.writeTextFile(
        '/old/root/source_1/episode/danmaku.json', '{}');
    expect((calls.last.arguments as Map)['path'],
        '/new/root/source_1/episode/danmaku.json');
    expect((calls.last.arguments as Map)['contents'], '{}');
    await platform.deleteDirectory('/old/root/source_1/episode');
    expect((calls.last.arguments as Map)['path'], '/new/root/source_1/episode');
  });
}
