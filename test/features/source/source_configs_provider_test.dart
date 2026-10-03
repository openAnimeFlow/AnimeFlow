import 'dart:io';

import 'package:anime_flow/core/crawler/item/crawler_config_item.dart';
import 'package:anime_flow/core/constants/storage_key.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/features/source/application/providers/source_configs_provider.dart';
import 'package:anime_flow/features/source/application/providers/source_repository_provider.dart';
import 'package:anime_flow/features/source/data/datasources/source_local_datasource.dart';
import 'package:anime_flow/hive_registrar.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

CrawlConfigItem _config(String name) {
  return CrawlConfigItem(
    version: '1.0.0',
    name: name,
    iconUrl: '',
    baseUrl: 'https://example.com',
    searchUrl: 'https://example.com/search?wd={keyword}',
    searchList: '//div',
    searchName: '/a',
    searchLink: '/a',
    lineNames: '//span',
    lineList: '//ul',
    episode: '//a',
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    Hive.registerAdapters();
    tempDir = Directory.systemTemp.createTempSync('animeflow_source_configs');
    Hive.init(tempDir.path);
    Storage.setting = await Hive.openBox<dynamic>(StorageKey.settingsKey);
    Storage.crawlConfigs = await Hive.openBox<CrawlConfigItem>('crawlConfigs');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('listenable 返回稳定实例，监听才能被移除', () {
    final dataSource = SourceLocalDataSource();

    final first = dataSource.listenable;
    // 每次调用都新建实例时，removeListener 会作用在另一个对象上，
    // 监听残留会在持有者销毁后继续触发。
    expect(identical(dataSource.listenable, first), isTrue);

    var notified = 0;
    void listener() => notified++;
    dataSource.listenable.addListener(listener);
    dataSource.listenable.removeListener(listener);
    expect(notified, 0);
  });

  test('provider 释放后数据源变更不再访问已失效的 ref', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final subscription = container.listen(sourceConfigsProvider, (_, __) {});
    await container.read(sourceConfigsProvider.future);

    final listenable = container.read(sourceRepositoryProvider).listenable;
    subscription.close();

    // 释放后再写入：残留监听会在这里调用 ref.invalidateSelf() 并抛出
    // “Cannot use the Ref ... after it has been disposed”。
    await Storage.crawlConfigs.put('probe', _config('probe'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 数据源本身仍然可用，说明只是 provider 的监听被正确摘除。
    expect(Storage.crawlConfigs.get('probe')?.name, 'probe');
    expect(listenable, isNotNull);
  });

  test('reorder 同步更新状态，拖拽松手后不会跳回原顺序', () async {
    addTearDown(() async {
      await Storage.crawlConfigs.deleteAll(const ['a', 'b', 'c']);
      await AppSettings.deleteSetting(StorageKey.crawlConfigOrder);
    });

    // 上一个用例会往 box 里写入 probe，先清理避免顺序断言被污染。
    await Storage.crawlConfigs.delete('probe');
    for (final name in const ['a', 'b', 'c']) {
      await Storage.crawlConfigs.put(name, _config(name));
    }
    // 排序单独存放在设置项里，数据源 box 的监听不会因为排序变化触发。
    await AppSettings.setSetting(
      StorageKey.crawlConfigOrder,
      const ['a', 'b', 'c'],
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = await container.read(sourceConfigsProvider.future);
    expect(
      before.map((source) => source.name),
      ['a', 'b', 'c'],
    );

    container.read(sourceConfigsProvider.notifier).reorder(0, 2);

    expect(
      container.read(sourceConfigsProvider).requireValue.map((s) => s.name),
      ['b', 'c', 'a'],
    );
  });
}
