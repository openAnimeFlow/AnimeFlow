import 'dart:async';

import 'package:anime_flow/features/user_space/presentation/providers/space_collections_provider.dart';
import 'package:anime_flow/features/user_space/presentation/providers/user_space_provider.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/bangumi/user_info_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends UserSpace {
  @override
  Future<UserInfoItem> build(String username) async => _Info(username);
}

class _Info implements UserInfoItem {
  _Info(this.username);
  @override
  final String username;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserCollectionsItem _page(int id, {int total = 2}) =>
    UserCollectionsItem(data: [
      UserCollectionData.fromJson({
        'id': id,
        'name': '$id',
        'type': 2,
        'rating': <String, dynamic>{},
        'images': <String, dynamic>{},
        'interest': {'id': id, 'type': 3, 'updatedAt': 1},
      })
    ], total: total);

void main() {
  test(
      'out-of-order tabs keep their own cache; failed paging retries without losing data',
      () async {
    final a = Completer<UserCollectionsItem>();
    final b = Completer<UserCollectionsItem>();
    final requests = <(int, int)>[];
    var fail = true;
    final container = ProviderContainer(overrides: [
      userSpaceProvider.overrideWith2((_) => _User()),
      spaceCollectionPageLoaderProvider
          .overrideWithValue((user, type, offset, token) {
        requests.add((type, offset));
        if (offset == 0) return type == 1 ? a.future : b.future;
        return fail
            ? Future.error(StateError('network'))
            : Future.value(_page(3));
      }),
    ]);
    addTearDown(container.dispose);
    final provider = spaceCollectionsProvider('alice');
    final subscription = container.listen(provider, (_, next) {});
    addTearDown(subscription.close);
    final notifier = container.read(provider.notifier);
    final first = notifier.loadInitial(1);
    final second = notifier.loadInitial(2);
    b.complete(_page(2));
    await second;
    a.complete(_page(1));
    await first;
    await notifier.loadInitial(1);
    expect(requests, [(1, 0), (2, 0)]);
    expect(container.read(provider)[1]!.data!.data.single.id, 1);
    expect(container.read(provider)[2]!.data!.data.single.id, 2);
    final more = notifier.loadMore(1);
    await notifier.loadMore(1);
    await more;
    expect(container.read(provider)[1]!.error, isStateError);
    expect(container.read(provider)[1]!.data!.data.single.id, 1);
    fail = false;
    await notifier.loadMore(1);
    await notifier.loadMore(1);
    expect(requests, [(1, 0), (2, 0), (1, 1), (1, 1)]);
    expect(container.read(provider)[1]!.data!.data.map((e) => e.id), [1, 3]);
  });

  test(
      'users are isolated and disposal cancels and discards a pending response',
      () async {
    final pending = Completer<UserCollectionsItem>();
    final tokens = <String, CancelToken>{};
    final container = ProviderContainer(overrides: [
      userSpaceProvider.overrideWith2((_) => _User()),
      spaceCollectionPageLoaderProvider
          .overrideWithValue((user, type, offset, token) {
        tokens[user] = token;
        return user == 'alice' ? pending.future : Future.value(_page(2));
      }),
    ]);
    final a = spaceCollectionsProvider('alice');
    final b = spaceCollectionsProvider('bob');
    final subscriptions = [
      container.listen(a, (_, next) {}),
      container.listen(b, (_, next) {})
    ];
    final loading = container.read(a.notifier).loadInitial(1);
    await container.read(b.notifier).loadInitial(1);
    expect(container.read(a)[1]!.data, isNull);
    expect(container.read(b)[1]!.data!.data.single.id, 2);
    for (final subscription in subscriptions) {
      subscription.close();
    }
    container.dispose();
    expect(tokens.values.every((token) => token.isCancelled), isTrue);
    pending.complete(_page(99));
    await loading;
  });
}
