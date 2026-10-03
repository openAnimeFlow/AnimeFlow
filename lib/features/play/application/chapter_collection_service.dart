import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_request.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/shared/models/player/play/video/episode_resources_item.dart';

/// 一次章节抓取要用的规则。
typedef ChapterFetcher = Future<List<CrawlerEpisodeResourcesItem>> Function(
  String sourceUrl,
  CrawlConfigItem config,
);

/// 搜索命中的一个候选条目。
class ChapterCandidate {
  const ChapterCandidate({
    required this.name,
    required this.link,
    required this.matchRatio,
  });

  final String name;
  final String link;
  final double matchRatio;
}

/// 候选条目的抓取结果。
class ChapterCollectionResult {
  const ChapterCollectionResult({
    required this.resources,
    required this.failedCount,
    this.lastError,
  });

  final List<EpisodeResourcesItem> resources;

  /// 抓取失败的候选数量（不含中断流程的验证码异常）。
  final int failedCount;

  /// 最后一次失败的原因；全部失败时交给调用方报错。
  final Object? lastError;

  /// 所有候选都失败。
  ///
  /// 这种情况要报错，而不是静默展示成「没有结果」。
  bool get allFailed => resources.isEmpty && failedCount > 0;
}

/// 逐条抓取候选条目的剧集资源。
///
/// 单个条目失败（详情接口报错、字段缺失导致解析失败等）只跳过该条目，
/// 不影响其它候选——否则一个异常条目会让整个数据源没有任何结果。
/// 需要人工验证时直接抛出 [CaptchaRequiredException]，由上层切换验证流程。
class ChapterCollectionService {
  ChapterCollectionService({ChapterFetcher? fetcher})
      : _fetch = fetcher ?? RuleRequest.fetchEpisodeResources;

  final ChapterFetcher _fetch;
  final LiggLogger _logger = LiggLogger();

  Future<ChapterCollectionResult> collect({
    required List<ChapterCandidate> candidates,
    required CrawlConfigItem config,
    bool Function()? isActive,
  }) async {
    final resources = <EpisodeResourcesItem>[];
    Object? lastError;
    var failedCount = 0;

    for (final candidate in candidates) {
      if (isActive != null && !isActive()) break;

      final List<CrawlerEpisodeResourcesItem> chapters;
      try {
        chapters = await _fetch(candidate.link, config);
      } on CaptchaRequiredException {
        // 验证码要中断整条链路，不能只跳过当前条目。
        rethrow;
      } catch (error) {
        failedCount++;
        lastError = error;
        _logger.w(
          'ChapterCollectionService: ${config.name} '
          '获取「${candidate.name}」剧集失败，已跳过',
          error: error,
        );
        continue;
      }

      if (isActive != null && !isActive()) break;

      for (final chapter in chapters) {
        resources.add(
          EpisodeResourcesItem(
            lineNames: chapter.lineNames,
            episodes: chapter.episodes,
            subjectsTitle: candidate.name,
            matchRatio: candidate.matchRatio,
          ),
        );
      }
    }

    return ChapterCollectionResult(
      resources: resources,
      failedCount: failedCount,
      lastError: lastError,
    );
  }
}
