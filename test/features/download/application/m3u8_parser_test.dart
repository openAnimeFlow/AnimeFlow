import 'package:anime_flow/features/download/application/m3u8_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M3u8Parser', () {
    test('detects master and media playlists', () {
      expect(
        M3u8Parser.detectType('''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1000
low.m3u8
'''),
        M3u8Type.master,
      );

      expect(
        M3u8Parser.detectType('''
#EXTM3U
#EXTINF:10,
seg.ts
'''),
        M3u8Type.media,
      );
    });

    test('parses master playlist and chooses highest bandwidth variant', () {
      final playlist = M3u8Parser.parseMasterPlaylist(
        '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
low/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2500000,RESOLUTION=1920x1080
/hd/index.m3u8
''',
        'https://example.com/video/master.m3u8',
      );

      expect(playlist.variants, hasLength(2));
      expect(playlist.bestVariant.bandwidth, 2500000);
      expect(playlist.bestVariant.resolution, '1920x1080');
      expect(playlist.bestVariant.uri, 'https://example.com/hd/index.m3u8');
    });

    test('parses media playlist with keys, discontinuity, and relative URLs',
        () {
      final playlist = M3u8Parser.parseMediaPlaylist(
        '''
#EXTM3U
#EXT-X-TARGETDURATION:8
#EXT-X-PLAYLIST-TYPE:VOD
#EXT-X-KEY:METHOD=AES-128,URI="keys/key,1.key",IV=0x123
#EXTINF:7.5,
seg-1.ts
#EXT-X-DISCONTINUITY
#EXTINF:8,
../seg-2.ts
#EXT-X-ENDLIST
''',
        'https://example.com/a/b/index.m3u8',
      );

      expect(playlist.isVod, isTrue);
      expect(playlist.targetDuration, 8);
      expect(playlist.segments, hasLength(2));
      expect(playlist.segments[0].uri, 'https://example.com/a/b/seg-1.ts');
      expect(playlist.segments[0].duration, 7.5);
      expect(
        playlist.segments[0].key?.uri,
        'https://example.com/a/b/keys/key,1.key',
      );
      expect(playlist.segments[0].key?.iv, '0x123');
      expect(playlist.segments[1].uri, 'https://example.com/a/seg-2.ts');
      expect(playlist.segments[1].discontinuityGroup, 1);
    });

    test('builds local playlist with local segment and key paths', () {
      const key = M3u8Key(
        method: 'AES-128',
        uri: 'https://example.com/key.key',
        iv: '0xabc',
      );
      final content = M3u8Parser.buildLocalM3u8(
        [
          const M3u8Segment(
            duration: 6,
            uri: 'https://example.com/seg0.ts',
            discontinuityGroup: 0,
            key: key,
          ),
          const M3u8Segment(
            duration: 7,
            uri: 'https://example.com/seg1.ts',
            discontinuityGroup: 1,
            key: key,
          ),
        ],
        targetDuration: 7,
        keyUriToLocal: {'https://example.com/key.key': 'key_0.key'},
      );

      expect(content, contains('#EXT-X-TARGETDURATION:7'));
      expect(
        content,
        contains('#EXT-X-KEY:METHOD=AES-128,URI="key_0.key",IV=0xabc'),
      );
      expect(content, contains('#EXT-X-DISCONTINUITY'));
      expect(content, contains('seg_00000.ts'));
      expect(content, contains('seg_00001.ts'));
      expect(content.trimRight().endsWith('#EXT-X-ENDLIST'), isTrue);
    });

    test('resolves nested m3u8 segments', () async {
      final segments = [
        const M3u8Segment(
          duration: 0,
          uri: 'https://example.com/nested/part.m3u8',
          discontinuityGroup: 0,
        ),
      ];

      final resolved = await M3u8Parser.resolveNestedSegments(
        segments,
        (url) async {
          expect(url, 'https://example.com/nested/part.m3u8');
          return '''
#EXTM3U
#EXT-X-TARGETDURATION:5
#EXTINF:5,
seg.ts
#EXT-X-ENDLIST
''';
        },
      );

      expect(resolved, hasLength(1));
      expect(resolved.single.uri, 'https://example.com/nested/seg.ts');
      expect(resolved.single.duration, 5);
    });
  });
}
