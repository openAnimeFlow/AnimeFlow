import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/core/crawler/api_crawler.dart';
import 'package:anime_flow/core/crawler/html_crawler.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_api_level.dart';
import 'package:anime_flow/core/crawler/rule_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// 读取随应用发布的内置规则（测试工作目录为包根目录）。
List<CrawlConfigItem> _loadBuiltinPlugins() {
  return Directory('assets/plugins')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .map(
        (file) => CrawlConfigItem.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        ),
      )
      .toList();
}

void main() {
  group('内置规则文件', () {
    test('全部可解析、兼容当前客户端且通过规则校验', () {
      final plugins = _loadBuiltinPlugins();

      expect(plugins, isNotEmpty);
      for (final plugin in plugins) {
        final reason = '规则 ${plugin.name}';
        expect(plugin.name.trim(), isNotEmpty, reason: reason);
        expect(plugin.isRuleCompatible, isTrue, reason: reason);
        expect(plugin.ruleCompatibility.name, 'compatible', reason: reason);

        // 规则声明的级别必须覆盖其内容所需的能力。
        final declaredApi = int.parse(plugin.api);
        expect(
          declaredApi,
          greaterThanOrEqualTo(
            RuleApiLevel.requiredFor(
              usesApiSearch: plugin.usesApiSearch,
              usesApiChapter: plugin.usesApiChapter,
              usesSourceTemplate:
                  plugin.searchApiConfig.sourceTemplate.isNotEmpty,
            ),
          ),
          reason: '$reason 的 api 级别低于其内容所需',
        );

        if (plugin.usesApiSearch) {
          expect(
            () => ApiCrawler.validateSearchConfig(plugin.searchApiConfig),
            returnsNormally,
            reason: reason,
          );
        }
        if (plugin.usesApiChapter) {
          expect(
            () => ApiCrawler.validateChapterConfig(plugin.chapterApiConfig),
            returnsNormally,
            reason: reason,
          );
        }
      }
    });
  });

  test('LMM 搜索结果转换为详情页并解析线路剧集', () async {
    final plugin =
        _loadBuiltinPlugins().firstWhere((item) => item.name == '路慢慢动漫');
    expect(plugin.api, '3');
    expect(plugin.usesApiSearch, isTrue);
    expect(plugin.usesApiChapter, isFalse);
    final items = ApiCrawler.parseSearch(
      '{"list":[{"id":2012,"name":"火影忍者"}]}',
      plugin.searchApiConfig,
    );
    expect(items.single.link,
        'https://www.lmm85.com/index.php/vod/detail/id/2012.html');
    final roads = await HtmlCrawler.parseEpisodeResources('''
      <div class="module-tab-items"><div class="module-tab-item tab-item selected"><span>聚合线路</span></div></div>
      <div class="module-list module-player-list tab-list"><a href="/play/2012_1_1.html"><span>第01集</span></a></div>
    ''', plugin);
    expect(roads.single.lineNames, '聚合线路');
    expect(roads.single.episodes.single.like, '/play/2012_1_1.html');
  });

  group('xfdmnext（Kazumi API 规则转换）', () {
    late CrawlConfigItem plugin;

    setUpAll(() {
      plugin = _loadBuiltinPlugins().firstWhere(
        (item) => item.name == 'xfdmnext',
      );
    });

    test('搜索与章节都走 API 模式，POST + JSON 请求体', () {
      expect(plugin.usesApiSearch, isTrue);
      expect(plugin.usesApiChapter, isTrue);
      expect(plugin.searchApiConfig.request.method, 'POST');
      expect(plugin.searchApiConfig.request.bodyType, ApiBodyType.json);
      expect(plugin.chapterApiConfig.request.method, 'POST');
      expect(plugin.chapterApiConfig.format, ApiChapterFormat.nested);
    });

    test('声明到 API 模式所需的规则级别', () {
      expect(plugin.api, '${RuleApiLevel.apiMode}');
      expect(plugin.isRuleCompatible, isTrue);
    });

    test('搜索响应按 listPath 与 title/id 解析', () {
      const payload = '[{"id":"anime-1","title":"进击的巨人"},'
          '{"id":"anime-2","title":"进击的巨人 第二季"}]';

      final items = ApiCrawler.parseSearch(payload, plugin.searchApiConfig);

      expect(items.map((item) => item.name).toList(), [
        '进击的巨人',
        '进击的巨人 第二季',
      ]);
      expect(items.first.link, 'anime-1');
    });

    test('请求体中的占位符可正确渲染', () {
      expect(
        RuleTemplate.renderValue(
          plugin.searchApiConfig.request.body,
          <String, Object?>{'keyword': '巨人'},
        ),
        <String, dynamic>{
          'search_term': '巨人',
          'page_number': 1,
          'items_per_page': 24,
        },
      );
      expect(
        RuleTemplate.renderValue(
          plugin.chapterApiConfig.request.body,
          <String, Object?>{'source': '1548'},
        ),
        <String, dynamic>{'p_id': '1548'},
      );
    });

    test('章节响应按 sources/episodes 解析', () {
      const payload = '{"sources":[{"name":"线路A","episodes":['
          '{"id":"ep-1","title":"第1集"},{"id":"ep-2","title":"第2集"}]}]}';

      final roads = ApiCrawler.parseChapters(
        payload,
        plugin.chapterApiConfig,
        source: 'anime-1',
        baseUrl: plugin.baseUrl,
      );

      expect(roads, hasLength(1));
      expect(roads.single.lineNames, '线路A');
      expect(roads.single.episodes.map((episode) => episode.like).toList(), [
        'https://next.xifanacg.com/anime/anime-1/play/ep-1',
        'https://next.xifanacg.com/anime/anime-1/play/ep-2',
      ]);
    });

    test('播放页模板不带多余的空查询串', () {
      const payload = '{"sources":[{"name":"线路A","episodes":[{"id":"ep-1"}]}]}';

      final roads = ApiCrawler.parseChapters(
        payload,
        plugin.chapterApiConfig,
        source: 'anime-1',
        baseUrl: plugin.baseUrl,
      );

      expect(
        roads.single.episodes.single.like,
        'https://next.xifanacg.com/anime/anime-1/play/ep-1',
      );
      expect(roads.single.episodes.single.like, isNot(endsWith('?')));
    });
  });
}
