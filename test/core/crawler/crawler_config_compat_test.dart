import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anime_flow/core/crawler/item/anti_crawler_config.dart';
import 'package:anime_flow/core/crawler/item/api_rule_config.dart';
import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/crawler/rule_api_level.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
// 测试需要构造「老版本」的原始二进制负载，只能使用 Hive 的内部 reader。
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/registry/type_registry_impl.dart';

/// Hive 二进制值类型中的 String 标记。
const int _stringType = 4;

/// 按 Hive 二进制格式写入一个 String（类型字节 + 小端长度 + UTF-8 内容）。
void _addString(BytesBuilder out, String value) {
  final bytes = utf8.encode(value);
  out
    ..addByte(_stringType)
    ..add(<int>[
      bytes.length & 0xFF,
      (bytes.length >> 8) & 0xFF,
      (bytes.length >> 16) & 0xFF,
      (bytes.length >> 24) & 0xFF,
    ])
    ..add(bytes);
}

/// 构造一份「老版本」CrawlConfigItem 的适配器负载：只有前 11 个字段，
/// 没有 searchMode / chapterMode / API 配置 / api 级别。
///
/// Hive 按字段索引读取，新字段在老数据里缺失，必须能被默认值兜底。
Uint8List _legacyCrawlConfigBytes() {
  final out = BytesBuilder();
  out.addByte(11); // numOfFields

  void field(int index, String value) {
    out.addByte(index);
    _addString(out, value);
  }

  field(0, '1.0.4');
  field(1, '七色动漫');
  field(2, 'https://example.com/icon.ico');
  field(3, 'https://example.com/');
  field(4, 'https://example.com/search?wd={keyword}');
  field(5, "//div[@class='video anim']");
  field(6, '/div[2] /text()');
  field(7, '/a');
  field(8, '//span');
  field(9, '//ul');
  field(10, '//a');

  // 老数据允许 antiCrawlerConfig 为空。
  out
    ..addByte(11)
    ..addByte(0);
  return out.toBytes();
}

CrawlConfigItem _legacyCrawlConfig() {
  final reader = BinaryReaderImpl(
    _legacyCrawlConfigBytes(),
    TypeRegistryImpl.nullImpl,
  );
  return CrawlConfigItemAdapter().read(reader);
}

void _registerAdaptersOnce() {
  void register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  register<AntiCrawlerConfig>(AntiCrawlerConfigAdapter());
  register<ApiRequestConfig>(ApiRequestConfigAdapter());
  register<ApiSearchConfig>(ApiSearchConfigAdapter());
  register<ApiEpisodePageConfig>(ApiEpisodePageConfigAdapter());
  register<ApiChapterConfig>(ApiChapterConfigAdapter());
  register<CrawlConfigItem>(CrawlConfigItemAdapter());
}

CrawlConfigItem _apiRule() {
  return CrawlConfigItem(
    version: '1.0.0',
    name: '示例 API 源',
    iconUrl: 'https://example.com/icon.ico',
    baseUrl: 'https://example.com',
    searchUrl: 'https://example.com/s?wd={keyword}',
    searchList: '//div',
    searchName: 'x',
    searchLink: 'y',
    lineNames: 'l',
    lineList: 'll',
    episode: 'e',
    searchMode: RuleMode.api,
    chapterMode: RuleMode.api,
    searchApiConfig: ApiSearchConfig(
      request: ApiRequestConfig(
        method: 'get',
        url: 'https://example.com/api/search',
        headers: <String, dynamic>{'referer': 'https://example.com/'},
        query: <String, dynamic>{'wd': '@keyword'},
      ),
      listPath: r'$.data[*]',
      namePath: r'$.name',
      sourcePath: r'$.url',
    ),
    chapterApiConfig: ApiChapterConfig(
      request: ApiRequestConfig(
        method: 'POST',
        url: 'https://example.com/api/detail',
        bodyType: ApiBodyType.json,
        body: <String, dynamic>{'id': '@source'},
      ),
      format: ApiChapterFormat.nested,
      variables: <String, String>{'ver': r'$.version'},
      episodePage: ApiEpisodePageConfig(
        url: 'https://example.com/play/@episodeUrl',
        query: <String, dynamic>{'ep': '@episodeNumber'},
      ),
    ),
  );
}

void main() {
  group('RuleApiLevel', () {
    test('缺省 api 视为兼容', () {
      expect(RuleApiLevel.check(null), RuleCompatibility.compatible);
      expect(RuleApiLevel.check(''), RuleCompatibility.compatible);
      expect(RuleApiLevel.check('   '), RuleCompatibility.compatible);
    });

    test('等于或低于 current 兼容', () {
      expect(
        RuleApiLevel.check('${RuleApiLevel.current}'),
        RuleCompatibility.compatible,
      );
      expect(RuleApiLevel.check(1), RuleCompatibility.compatible);
    });

    test('高于 current 需要更高客户端', () {
      expect(
        RuleApiLevel.check('${RuleApiLevel.current + 1}'),
        RuleCompatibility.requiresNewerClient,
      );
    });

    test('非法值判定为 invalid', () {
      expect(RuleApiLevel.check('abc'), RuleCompatibility.invalid);
      expect(RuleApiLevel.check('0'), RuleCompatibility.invalid);
      expect(RuleApiLevel.check('-1'), RuleCompatibility.invalid);
    });
  });

  group('CrawlConfigItem JSON 兼容', () {
    test('老规则 JSON 缺省为 XPath 且兼容', () {
      final item = CrawlConfigItem.fromJson(<String, dynamic>{
        'version': '1.0.4',
        'name': '七色动漫',
        'baseUrl': 'https://example.com/',
        'searchUrl': 'https://example.com/search?wd={keyword}',
        'searchList': '//div',
        'searchName': '/div[2]',
        'searchLink': '/a',
        'lineNames': '//span',
        'lineList': '//ul',
        'episode': '//a',
      });

      expect(item.searchMode, RuleMode.xpath);
      expect(item.chapterMode, RuleMode.xpath);
      expect(item.usesApiSearch, isFalse);
      expect(item.api, RuleApiLevel.defaultApi);
      expect(item.isRuleCompatible, isTrue);
      expect(item.searchApiConfig.listPath, r'$.data[*]');
      expect(item.chapterApiConfig.format, ApiChapterFormat.nested);
    });

    test('toJson/fromJson 往返保留 API 配置', () {
      final restored = CrawlConfigItem.fromJson(_apiRule().toJson());

      expect(restored.usesApiSearch, isTrue);
      expect(restored.usesApiChapter, isTrue);
      expect(restored.searchApiConfig.request.method, 'GET');
      expect(restored.searchApiConfig.request.query['wd'], '@keyword');
      expect(restored.chapterApiConfig.request.bodyType, ApiBodyType.json);
      expect(
        restored.chapterApiConfig.request.body,
        <String, dynamic>{'id': '@source'},
      );
      expect(restored.chapterApiConfig.variables['ver'], r'$.version');
      expect(
        restored.chapterApiConfig.episodePage?.url,
        'https://example.com/play/@episodeUrl',
      );
    });

    test('切换模式后未激活的一侧配置仍然保留', () {
      final switched = CrawlConfigItem.fromJson(<String, dynamic>{
        ..._apiRule().toJson(),
        'searchMode': RuleMode.xpath,
      });

      expect(switched.usesApiSearch, isFalse);
      expect(
        switched.searchApiConfig.request.url,
        'https://example.com/api/search',
      );
      expect(switched.toJson()['searchApiConfig'], isNotNull);
    });
  });

  group('Hive 二进制兼容', () {
    test('老数据缺少新字段时读出默认值', () {
      final item = _legacyCrawlConfig();

      expect(item.name, '七色动漫');
      expect(item.antiCrawlerConfig.enabled, isFalse);
      expect(item.searchMode, RuleMode.xpath);
      expect(item.chapterMode, RuleMode.xpath);
      expect(item.api, RuleApiLevel.defaultApi);
      expect(item.isRuleCompatible, isTrue);
      expect(item.searchApiConfig.request.method, 'GET');
      expect(item.chapterApiConfig.episodesPath, r'$.episodes[*]');
    });

    test('新增字段可完整写入并读回', () async {
      _registerAdaptersOnce();
      final tempDir = Directory.systemTemp.createTempSync('animeflow_hive');
      Hive.init(tempDir.path);
      final box = await Hive.openBox<CrawlConfigItem>('crawlConfigs');

      try {
        final source = _apiRule();
        await box.put(source.name, source);
        // 关闭再打开，强制从磁盘按适配器重新解码。
        await box.close();

        final reopened = await Hive.openBox<CrawlConfigItem>('crawlConfigs');
        final restored = reopened.get(source.name)!;

        expect(restored.searchMode, RuleMode.api);
        expect(restored.chapterMode, RuleMode.api);
        expect(restored.api, RuleApiLevel.defaultApi);
        expect(restored.searchApiConfig.request.method, 'GET');
        expect(
          restored.searchApiConfig.request.headers['referer'],
          'https://example.com/',
        );
        expect(restored.searchApiConfig.request.query['wd'], '@keyword');
        expect(restored.chapterApiConfig.request.method, 'POST');
        expect(restored.chapterApiConfig.request.bodyType, ApiBodyType.json);
        expect(restored.chapterApiConfig.variables['ver'], r'$.version');
        expect(
          restored.chapterApiConfig.episodePage?.query['ep'],
          '@episodeNumber',
        );

        await reopened.close();
      } finally {
        await Hive.close();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
