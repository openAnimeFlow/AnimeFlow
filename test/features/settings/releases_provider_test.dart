import 'dart:async';

import 'package:anime_flow/features/settings/presentation/providers/releases_provider.dart';
import 'package:anime_flow/shared/models/github_release.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

GithubRelease _release(int id) => GithubRelease(
    name: '$id', tagName: '$id', createdAt: '', body: '', htmlUrl: '');

void main() {
  testWidgets('initial failure stays visible until the user retries',
      (tester) async {
    var requests = 0;
    final container = ProviderContainer(overrides: [
      releasePageLoaderProvider.overrideWithValue((page, token) async {
        if (++requests == 1) throw StateError('network');
        return [_release(1)];
      }),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(releasesProvider, (_, next) {});
    addTearDown(subscription.close);
    await expectLater(
        container.read(releasesProvider.future), throwsStateError);
    await tester.pump(const Duration(seconds: 2));
    expect(requests, 1);
    expect(container.read(releasesProvider).hasError, isTrue);
    container.invalidate(releasesProvider);
    await tester.pump(const Duration(milliseconds: 1));
    expect((await container.read(releasesProvider.future)).releases.single.name,
        '1');
    expect(requests, 2);
  });

  test(
      'paging coalesces requests, preserves data on failure and retries offset',
      () async {
    final requests = <int>[];
    final pending = Completer<List<GithubRelease>>();
    var fail = true;
    final container = ProviderContainer(overrides: [
      releasePageLoaderProvider.overrideWithValue((page, token) async {
        requests.add(page);
        if (page == 1) return [_release(1)];
        if (page == 2 && fail) return pending.future;
        return page == 2 ? [_release(2)] : [];
      }),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(releasesProvider, (_, next) {});
    addTearDown(subscription.close);
    await container.read(releasesProvider.future);
    final notifier = container.read(releasesProvider.notifier);
    final first = notifier.loadMore();
    await notifier.loadMore();
    expect(requests, [1, 2]);
    pending.completeError(StateError('network'));
    await first;
    var data = container.read(releasesProvider).requireValue;
    expect(data.releases.map((e) => e.name), ['1']);
    expect(data.page, 1);
    expect(data.loadMoreError, isStateError);
    fail = false;
    await notifier.loadMore();
    data = container.read(releasesProvider).requireValue;
    expect(data.releases.map((e) => e.name), ['1', '2']);
    expect(data.loadMoreError, isNull);
    await notifier.loadMore();
    await notifier.loadMore();
    expect(requests, [1, 2, 2, 3]);
    expect(container.read(releasesProvider).requireValue.hasMore, isFalse);
  });

  test('refresh and disposal cancel requests and ignore a late page', () async {
    final tokens = <CancelToken>[];
    final pending = Completer<List<GithubRelease>>();
    var initial = 0;
    final container = ProviderContainer(overrides: [
      releasePageLoaderProvider.overrideWithValue((page, token) async {
        tokens.add(token);
        if (page == 1) return [_release(++initial)];
        return pending.future;
      }),
    ]);
    final subscription = container.listen(releasesProvider, (_, next) {});
    await container.read(releasesProvider.future);
    final loading = container.read(releasesProvider.notifier).loadMore();
    container.invalidate(releasesProvider);
    await container.read(releasesProvider.future);
    expect(tokens.first.isCancelled, isTrue);
    pending.complete([_release(99)]);
    await loading;
    expect(container.read(releasesProvider).requireValue.releases.single.name,
        '2');
    subscription.close();
    container.dispose();
    expect(tokens.last.isCancelled, isTrue);
  });
}
