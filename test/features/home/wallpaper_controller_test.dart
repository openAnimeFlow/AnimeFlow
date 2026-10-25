import 'dart:async';
import 'dart:math';

import 'package:anime_flow/features/home/presentation/providers/wallpaper_controller.dart';
import 'package:anime_flow/shared/models/enums/sort_type.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';

SubjectWallpaper subject(int id, [List<String>? posters]) => SubjectWallpaper(
      subjectId: id,
      name: 'subject$id',
      nameCn: '',
      posters: posters ?? ['poster$id-a', 'poster$id-b'],
    );

SubjectWallpaperPage page(List<SubjectWallpaper> subjects,
        {int page = 1, int? total}) =>
    SubjectWallpaperPage(
        data: subjects, page: page, total: total ?? subjects.length);

void main() {
  test('uses source-specific placeholder ratios', () {
    const mixed = SubjectWallpaper(
      subjectId: 1,
      name: 'mixed',
      nameCn: '',
      backdrops: ['backdrop'],
      posters: ['poster'],
    );
    const backdrop = WallpaperPoster(subject: mixed, url: 'backdrop');
    const poster = WallpaperPoster(subject: mixed, url: 'poster');
    expect(backdrop.isBackdrop, isTrue);
    expect(backdrop.placeholderAspectRatio, 16 / 9);
    expect(poster.isBackdrop, isFalse);
    expect(poster.placeholderAspectRatio, 2 / 3);
  });

  test(
      'parses image arrays, removes invalid URLs and falls back to original title',
      () {
    final response = SubjectWallpaperPage.fromJson({
      'page': 1,
      'total': 21,
      'data': [
        {
          'subjectId': 1,
          'name': 'Original',
          'nameCn': '',
          'posters': [null, '', ' ', 'https://example.com/poster.jpg'],
          'backdrops': [null, '', ' ', 'https://example.com/backdrop.jpg'],
        },
        {'subjectId': 2, 'name': 'Original', 'nameCn': '中文', 'posters': []},
      ],
    });
    expect(response.total, 21);
    expect(response.data.first.posters, ['https://example.com/poster.jpg']);
    expect(response.data.first.backdrops, ['https://example.com/backdrop.jpg']);
    expect(response.data.first.coverImages, [
      'https://example.com/backdrop.jpg',
      'https://example.com/poster.jpg',
    ]);
    expect(response.data.last.coverImages, isEmpty);
    expect(response.data.first.displayName, 'Original');
    expect(response.data.last.displayName, '中文');
  });

  test('selects one stable poster per subject and respects server total',
      () async {
    final requests = <int>[];
    final controller = WallpaperController(
      random: Random(42),
      loader: (
          {required sort,
          required page,
          required pageSize,
          cancelToken}) async {
        requests.add(page);
        expect(sort, SortType.trends);
        expect(pageSize, 20);
        return SubjectWallpaperPage(
          data: page == 1
              ? [subject(1), subject(2, [])]
              : [subject(1), subject(3)],
          page: page,
          total: 21,
        );
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    final firstSnapshot = controller.items;
    expect(controller.items, same(firstSnapshot));
    final firstUrl = controller.items.single.url;
    expect(subject(1).posters, contains(firstUrl));
    await controller.loadMore();
    expect(firstSnapshot.length, 1);
    expect(controller.items, isNot(same(firstSnapshot)));
    expect(() => controller.items.clear(), throwsUnsupportedError);
    expect(controller.items.map((item) => item.subject.subjectId), [1, 3]);
    expect(controller.items.first.url, firstUrl);
    expect(controller.hasMore, false);
    await controller.loadMore();
    expect(requests, [1, 2]);
  });

  test('does not stop on a page without any cover images', () async {
    final controller = WallpaperController(
      loader: (
              {required sort,
              required page,
              required pageSize,
              cancelToken}) async =>
          SubjectWallpaperPage(
        data: page == 1 ? [subject(1, [])] : [subject(2)],
        page: page,
        total: 21,
      ),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.items, isEmpty);
    expect(controller.hasMore, true);
    await controller.loadMore();
    expect(controller.items.single.subject.subjectId, 2);
  });

  test('displays subjects with only backdrops and skips empty image arrays',
      () async {
    final controller = WallpaperController(
      loader: (
              {required sort,
              required page,
              required pageSize,
              cancelToken}) async =>
          SubjectWallpaperPage(data: [
        const SubjectWallpaper(
          subjectId: 1,
          name: 'one',
          nameCn: '',
          posters: [],
          backdrops: ['backdrop'],
        ),
        subject(2, []),
      ], page: 1, total: 2),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.items.single.subject.subjectId, 1);
    expect(controller.items.single.url, 'backdrop');
  });

  test('selects from both arrays and removes duplicated image URLs', () async {
    const mixed = SubjectWallpaper(
      subjectId: 1,
      name: 'mixed',
      nameCn: '',
      backdrops: ['backdrop', 'same'],
      posters: ['poster', 'same'],
    );
    expect(mixed.coverImages, ['backdrop', 'same', 'poster']);
    final controller = WallpaperController(
      random: Random(42),
      loader: (
              {required sort,
              required page,
              required pageSize,
              cancelToken}) async =>
          SubjectWallpaperPage(data: [mixed], page: page, total: 1),
    );
    addTearDown(controller.dispose);
    final choices = <String>{};
    for (var i = 0; i < 32; i++) {
      await controller.refresh();
      choices.add(controller.items.single.url);
    }
    expect(choices, mixed.coverImages.toSet());
  });

  test('changing sort ignores late responses from the previous request',
      () async {
    final old = Completer<SubjectWallpaperPage>();
    final controller = WallpaperController(
      loader: ({required sort, required page, required pageSize, cancelToken}) {
        if (sort == SortType.trends) return old.future;
        expect(sort, SortType.rank);
        expect(page, 1);
        return Future.value(
            SubjectWallpaperPage(data: [subject(2)], page: 1, total: 1));
      },
    );
    addTearDown(controller.dispose);
    final first = controller.refresh();
    await controller.refresh(sort: SortType.rank);
    old.complete(page([subject(1)]));
    await first;
    expect(controller.items.single.subject.subjectId, 2);
    expect(controller.sort, SortType.rank);
    expect(controller.isLoading, false);
  });

  test('failed pagination preserves cards and retries the same page', () async {
    var failNext = true;
    final requests = <int>[];
    final controller = WallpaperController(
      loader: (
          {required sort,
          required page,
          required pageSize,
          cancelToken}) async {
        requests.add(page);
        if (page == 2 && failNext) {
          failNext = false;
          throw StateError('offline');
        }
        return SubjectWallpaperPage(
            data: [subject(page)], page: page, total: 21);
      },
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.loadMore();
    expect(controller.error, isA<StateError>());
    expect(controller.items.single.subject.subjectId, 1);
    await controller.loadMore();
    expect(controller.error, isNull);
    expect(requests, [1, 2, 2]);
    expect(controller.items.length, 2);
  });

  test('deduplicates concurrent loads and ignores completion after disposal',
      () async {
    var calls = 0;
    final response = Completer<SubjectWallpaperPage>();
    final controller = WallpaperController(
      loader: ({required sort, required page, required pageSize, cancelToken}) {
        calls++;
        return response.future;
      },
    );
    final pending = controller.refresh();
    await controller.loadMore();
    expect(calls, 1);
    controller.dispose();
    response.complete(page([subject(1)]));
    await pending;
    expect(controller.items, isEmpty);
  });
}
