import 'package:anime_flow/core/crawler/item/bgm_user_statistics_item.dart';
import 'package:anime_flow/features/user_space/data/repository/user_space_repository.dart';
import 'package:anime_flow/features/user_space/presentation/providers/user_space_provider.dart';
import 'package:anime_flow/shared/models/bangumi/user_info_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserInfoItem profile(String username, String nickname) =>
    UserInfoItem.fromJson({
      'id': 1,
      'username': username,
      'nickname': nickname,
      'avatar': {'small': '', 'medium': '', 'large': ''},
      'group': 10,
      'joinedAt': 1,
      'sign': '',
      'site': '',
      'location': '',
      'networkServices': [],
      'homepage': {'left': <String>[], 'right': <String>[]},
      'stats': {
        'subject': {
          for (final type in [1, 2, 3, 4, 6])
            '$type': {for (var status = 1; status <= 5; status++) '$status': 0},
        },
        'mono': {'character': 0, 'person': 0},
        'blog': 0,
        'friend': 0,
        'group': 0,
        'index': {'create': 0, 'collect': 0},
      },
    });

class UserSpaceRepositoryStub extends UserSpaceRepository {
  UserSpaceRepositoryStub(this.label);

  final String label;
  final profileRequests = <String>[];
  final statisticsRequests = <String>[];

  @override
  Future<UserInfoItem> getUserProfile(String username) async {
    profileRequests.add(username);
    return profile(username, label);
  }

  @override
  Future<BgmUserStatisticsItem> getUserStatistics(String username) async {
    statisticsRequests.add(username);
    return BgmUserStatisticsItem(
      statistics: [Statistic(name: 'watched', value: label)],
    );
  }
}

void main() {
  test('public profiles and statistics are isolated by username', () async {
    final repository = UserSpaceRepositoryStub('public');
    final container = ProviderContainer(overrides: [
      userSpaceRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    for (final username in ['alice', 'bob']) {
      container.listen(userSpaceProvider(username), (_, __) {});
      container.listen(userSpaceStatisticsProvider(username), (_, __) {});
      expect(
          (await container.read(userSpaceProvider(username).future)).username,
          username);
      expect(
          (await container.read(userSpaceStatisticsProvider(username).future))
              .statistics
              .single
              .value,
          'public');
    }
    expect(repository.profileRequests, ['alice', 'bob']);
    expect(repository.statisticsRequests, ['alice', 'bob']);
  });

  test('replacing the space repository rebuilds both dependent providers',
      () async {
    final first = UserSpaceRepositoryStub('first');
    final second = UserSpaceRepositoryStub('second');
    final container = ProviderContainer(overrides: [
      userSpaceRepositoryProvider.overrideWithValue(first),
    ]);
    addTearDown(container.dispose);
    container.listen(userSpaceProvider('alice'), (_, __) {});
    container.listen(userSpaceStatisticsProvider('alice'), (_, __) {});
    await container.read(userSpaceProvider('alice').future);
    await container.read(userSpaceStatisticsProvider('alice').future);

    container.updateOverrides([
      userSpaceRepositoryProvider.overrideWithValue(second),
    ]);
    await container.pump();

    expect((await container.read(userSpaceProvider('alice').future)).nickname,
        'second');
    expect(
        (await container.read(userSpaceStatisticsProvider('alice').future))
            .statistics
            .single
            .value,
        'second');
    expect(first.profileRequests, ['alice']);
    expect(second.profileRequests, ['alice']);
    expect(second.statisticsRequests, ['alice']);
  });
}
