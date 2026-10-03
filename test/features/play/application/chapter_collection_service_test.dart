import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:anime_flow/features/play/application/chapter_collection_service.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';
import 'package:flutter_test/flutter_test.dart';

CrawlConfigItem _config() {
  return CrawlConfigItem(
    version: '1.0.0',
    name: '测试源',
    iconUrl: '',
    baseUrl: 'https://example.com',
    searchUrl: '',
    searchList: '',
    searchName: '',
    searchLink: '',
    lineNames: '',
    lineList: '',
    episode: '',
  );
}

ChapterCandidate _candidate(String name, String link) {
  return ChapterCandidate(name: name, link: link, matchRatio: 0.5);
}

List<CrawlerEpisodeResourcesItem> _chapters(String lineName, String url) {
  return [
    CrawlerEpisodeResourcesItem(
      lineNames: lineName,
      episodes: [Episode(episodeSort: 1, like: url)],
    ),
  ];
}

void main() {
  group('ChapterCollectionService', () {
    test('汇总所有候选的线路', () async {
      final service = ChapterCollectionService(
        fetcher: (link, config) async => _chapters('线路$link', link),
      );

      final result = await service.collect(
        candidates: [_candidate('A', '/a'), _candidate('B', '/b')],
        config: _config(),
      );

      expect(result.resources.map((item) => item.lineNames).toList(), [
        '线路/a',
        '线路/b',
      ]);
      expect(result.resources.map((item) => item.subjectsTitle).toList(), [
        'A',
        'B',
      ]);
      expect(result.failedCount, 0);
      expect(result.allFailed, isFalse);
    });

    test('单个候选失败不影响其它候选', () async {
      final service = ChapterCollectionService(
        fetcher: (link, config) async {
          if (link == '/bad') {
            throw const ChapterErrorException('测试源');
          }
          return _chapters('线路$link', link);
        },
      );

      final result = await service.collect(
        candidates: [
          _candidate('A', '/a'),
          _candidate('B', '/bad'),
          _candidate('C', '/c'),
        ],
        config: _config(),
      );

      expect(result.resources.map((item) => item.subjectsTitle).toList(), [
        'A',
        'C',
      ]);
      expect(result.failedCount, 1);
      expect(result.allFailed, isFalse);
    });

    test('全部候选失败时把错误交回调用方', () async {
      final service = ChapterCollectionService(
        fetcher: (link, config) async =>
            throw const ChapterErrorException('测试源'),
      );

      final result = await service.collect(
        candidates: [_candidate('A', '/a'), _candidate('B', '/b')],
        config: _config(),
      );

      expect(result.resources, isEmpty);
      expect(result.failedCount, 2);
      expect(result.allFailed, isTrue);
      expect(result.lastError, isA<ChapterErrorException>());
    });

    test('验证码异常直接上抛并中断，不当作单条失败', () async {
      var calls = 0;
      final service = ChapterCollectionService(
        fetcher: (link, config) async {
          calls++;
          throw const CaptchaRequiredException('测试源');
        },
      );

      await expectLater(
        service.collect(
          candidates: [_candidate('A', '/a'), _candidate('B', '/b')],
          config: _config(),
        ),
        throwsA(isA<CaptchaRequiredException>()),
      );
      expect(calls, 1);
    });

    test('isActive 变 false 后停止抓取并丢弃失效结果', () async {
      var calls = 0;
      final service = ChapterCollectionService(
        fetcher: (link, config) async {
          calls++;
          return _chapters('线路', link);
        },
      );

      final result = await service.collect(
        candidates: [
          _candidate('A', '/a'),
          _candidate('B', '/b'),
          _candidate('C', '/c'),
        ],
        config: _config(),
        // 抓完第 2 个候选后会话已失效。
        isActive: () => calls < 2,
      );

      // 第 3 个候选不再请求；第 2 个的结果因为已失效被丢弃。
      expect(calls, 2);
      expect(result.resources, hasLength(1));
    });

    test('一开始就失效时不发起任何请求', () async {
      var calls = 0;
      final service = ChapterCollectionService(
        fetcher: (link, config) async {
          calls++;
          return _chapters('线路', link);
        },
      );

      final result = await service.collect(
        candidates: [_candidate('A', '/a')],
        config: _config(),
        isActive: () => false,
      );

      expect(calls, 0);
      expect(result.resources, isEmpty);
      expect(result.failedCount, 0);
    });

    test('没有候选时返回空结果而不是全部失败', () async {
      final service = ChapterCollectionService(
        fetcher: (link, config) async => const [],
      );

      final result = await service.collect(
        candidates: const [],
        config: _config(),
      );

      expect(result.resources, isEmpty);
      expect(result.failedCount, 0);
      expect(result.allFailed, isFalse);
    });
  });
}
