import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/user_space/presentation/providers/user_space_provider.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'space_collections_provider.g.dart';

typedef SpaceCollectionPageLoader = Future<UserCollectionsItem> Function(
    String username, int type, int offset, CancelToken cancelToken);

final spaceCollectionPageLoaderProvider = Provider<SpaceCollectionPageLoader>(
    (ref) => (username, type, offset, token) =>
        FlowApi.queryUserCollectionService(username,
            type: type, limit: 20, offset: offset, cancelToken: token));

class SpaceCollectionTabState {
  const SpaceCollectionTabState(
      {this.data, this.isLoading = false, this.error});

  final UserCollectionsItem? data;
  final bool isLoading;
  final Object? error;
}

/// 每个用户独立保存各标签的分页状态；切换标签不会覆盖另一个标签的响应。
@riverpod
class SpaceCollections extends _$SpaceCollections {
  late CancelToken _cancelToken;

  @override
  Map<int, SpaceCollectionTabState> build(String username) {
    final token = _cancelToken = CancelToken();
    ref.onDispose(token.cancel);
    return const {};
  }

  Future<void> loadInitial(int type) => _load(type, more: false);
  Future<void> loadMore(int type) => _load(type, more: true);

  Future<void> _load(int type, {required bool more}) async {
    final previous = state[type];
    final data = previous?.data;
    if (previous?.isLoading == true ||
        !more && data != null ||
        more && (data == null || data.data.length >= data.total)) {
      return;
    }

    final token = _cancelToken;
    state = {
      ...state,
      type: SpaceCollectionTabState(data: data, isLoading: true),
    };
    try {
      final user = await ref.read(userSpaceProvider(username).future);
      if (!ref.mounted || token.isCancelled) return;
      final page = await ref.read(spaceCollectionPageLoaderProvider)(
          user.username, type, more ? data!.data.length : 0, token);
      if (!ref.mounted || token.isCancelled) return;
      state = {
        ...state,
        type: SpaceCollectionTabState(
            data: UserCollectionsItem(
          data: List.unmodifiable([if (more) ...data!.data, ...page.data]),
          total: page.total,
        )),
      };
    } catch (error) {
      if (!ref.mounted || token.isCancelled) return;
      state = {
        ...state,
        type: SpaceCollectionTabState(data: data, error: error),
      };
    }
  }
}
