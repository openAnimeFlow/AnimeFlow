import 'dart:async';
import 'dart:io';

import 'package:anime_flow/core/cache/cache_usage_service.dart';
import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory directory;
  late Map<CacheCategory, Box<String>> boxes;
  final service = CacheUsageService();

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('cache_usage_test_');
    Hive.init(directory.path);
    Storage.animeInfoCache = await Hive.openBox<String>('anime_info');
    Storage.characterDataCache = await Hive.openBox<String>('characters');
    Storage.subjectMetadataCache = await Hive.openBox<String>('metadata');
    Storage.subjectCommentsCache = await Hive.openBox<String>('comments');
    Storage.popularAnimeCache = await Hive.openBox<String>('popular');
    Storage.calendarCache = await Hive.openBox<String>('calendar');
    Storage.subjectEpisodesCache = await Hive.openBox<String>('episodes');
    Storage.userDataCache = await Hive.openBox<String>('user_data');
    boxes = {
      CacheCategory.animeInfo: Storage.animeInfoCache,
      CacheCategory.characters: Storage.characterDataCache,
      CacheCategory.subjectMetadata: Storage.subjectMetadataCache,
      CacheCategory.subjectComments: Storage.subjectCommentsCache,
      CacheCategory.popularAnime: Storage.popularAnimeCache,
      CacheCategory.calendar: Storage.calendarCache,
      CacheCategory.subjectEpisodes: Storage.subjectEpisodesCache,
      CacheCategory.userData: Storage.userDataCache,
    };
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  setUp(() async {
    for (final box in boxes.values) {
      await box.clear();
    }
  });

  test(
      'measures every data cache file including expired, corrupt and deleted records',
      () async {
    for (final entry in boxes.entries) {
      await entry.value.put('expired', '{"cachedAt":0,"data":"中文放送表"}');
      await entry.value.put('broken', 'corrupt JSON');
      await entry.value.put('removed', 'old cache data' * 100);
      await entry.value.delete('removed');
    }
    final other = await Hive.openBox<String>('settings');
    await other.put('account', 'personal data' * 10000);
    await File('${directory.path}/video.mp4')
        .writeAsBytes(List.filled(4096, 0));
    final before = boxes.map((key, box) => MapEntry(key, box.toMap()));

    final sizes = await service.dataSizesInBytes();
    expect(sizes.keys, unorderedEquals(boxes.keys));
    var expectedTotal = 1024;
    for (final entry in boxes.entries) {
      final physicalBytes = await File(entry.value.path!).length();
      expect(sizes[entry.key], physicalBytes);
      expect(physicalBytes, greaterThan(0));
      expect(entry.value.toMap(), before[entry.key]);
      expectedTotal += physicalBytes;
    }
    final usage = CacheUsage({CacheCategory.images: 1024, ...sizes});
    expect(usage.totalBytes, expectedTotal);
    expect(usage.sizes.keys, unorderedEquals(CacheCategory.values));
    expect(other.get('account'), 'personal data' * 10000);
  });

  test('remeasures after writes and clearing rather than retaining an old size',
      () async {
    final initial = await service.dataSizesInBytes();
    await Storage.calendarCache.put('season', 'new schedule' * 2000);
    final written = await service.dataSizesInBytes();
    expect(written[CacheCategory.calendar],
        greaterThan(initial[CacheCategory.calendar]!));
    await Storage.calendarCache.clear();
    final cleared = await service.dataSizesInBytes();
    expect(cleared[CacheCategory.calendar],
        await File(Storage.calendarCache.path!).length());
    expect(Storage.calendarCache.isEmpty, isTrue);
    expect(cleared[CacheCategory.calendar],
        lessThan(written[CacheCategory.calendar]!));
  });

  test(
      'clears only selected categories and preserves settings and other caches',
      () async {
    final settings = await Hive.openBox<String>('settings');
    await settings.put('keep', 'settings');
    for (final selected in <Set<CacheCategory>>[
      {
        CacheCategory.characters,
        CacheCategory.calendar,
        CacheCategory.subjectEpisodes,
      },
      {CacheCategory.userData},
    ]) {
      for (final box in boxes.values) {
        await box.put('data', 'cached data');
      }
      await service.clearData(selected);
      for (final entry in boxes.entries) {
        expect(entry.value.isEmpty, selected.contains(entry.key));
        expect(entry.value.isOpen, isTrue);
      }
      expect(settings.get('keep'), 'settings');
    }
  });

  test('responses started before clearing cannot repopulate selected caches',
      () async {
    final pending = Completer<Map<String, dynamic>>();
    final request = JsonResponseCache.get(Storage.calendarCache, 'current',
        load: () => pending.future,
        fromJson: (data) => data,
        toJson: (data) => data);
    await service.clearData({CacheCategory.calendar});
    pending.complete({'result': 'old'});
    expect(await request, {'result': 'old'});
    expect(Storage.calendarCache.isEmpty, isTrue);
    await JsonResponseCache.get(Storage.calendarCache, 'current',
        load: () async => {'result': 'fresh'},
        fromJson: (data) => data,
        toJson: (data) => data);
    expect(Storage.calendarCache.isNotEmpty, isTrue);
  });
}
