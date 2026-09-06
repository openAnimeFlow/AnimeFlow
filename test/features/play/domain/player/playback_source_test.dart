import 'dart:io';

import 'package:anime_flow/features/play/domain/player/playback_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('local file paths round trip without trimming or double decoding', () {
    final path = p.join(Directory.systemTemp.path, ' 视频 #100%20.mp4 ');
    final source = PlaybackSource.localFile(path);
    expect(source.isLocal, isTrue);
    expect(source.uri.isScheme('file'), isTrue);
    expect(source.uri.toFilePath(), path);
    expect(source.uri.hasQuery, isFalse);
    expect(source.uri.hasFragment, isFalse);
    final restored = PlaybackSource.localFile(source.uri.toString());
    expect(restored.uri, source.uri);
    expect(restored.uri.toFilePath(), path);
  });

  test('local file sources reject URLs and ambiguous file references', () {
    final fileUri = Directory.systemTemp.uri.resolve('video.mp4');
    for (final invalid in [
      '',
      ' ',
      'video.mp4',
      'https://example.com/video.mp4',
      'content://media/external/video/1',
      '$fileUri?query=value',
      '$fileUri#fragment',
    ]) {
      expect(() => PlaybackSource.localFile(invalid),
          throwsA(anyOf(isA<ArgumentError>(), isA<UnsupportedError>())),
          reason: invalid);
    }
  });
}
