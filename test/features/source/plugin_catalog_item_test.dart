import 'package:anime_flow/features/source/application/providers/plugin_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _entry({Object? api}) {
  return <String, dynamic>{
    'name': 'API 源',
    'path': 'api.json',
    'version': '1.0.0',
    'icon': null,
    'updateTime': null,
    if (api != null) 'api': api,
  };
}

void main() {
  group('PluginCatalogItem', () {
    test('目录未声明 api 时按兼容处理', () {
      final item = PluginCatalogItem.fromJson(_entry());

      expect(item.api, isNull);
      expect(item.requiresNewerClient, isFalse);
    });

    test('目录声明的 api 兼容当前客户端', () {
      final item = PluginCatalogItem.fromJson(_entry(api: '1'));

      expect(item.api, '1');
      expect(item.requiresNewerClient, isFalse);
    });

    test('目录声明的 api 高于当前客户端时标记为需要更新', () {
      final item = PluginCatalogItem.fromJson(_entry(api: 99));

      expect(item.api, '99');
      expect(item.requiresNewerClient, isTrue);
    });

    test('目录声明非法 api 时按兼容处理，交由下载后校验兜底', () {
      final item = PluginCatalogItem.fromJson(_entry(api: 'abc'));

      expect(item.requiresNewerClient, isFalse);
    });
  });
}
