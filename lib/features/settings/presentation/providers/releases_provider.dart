import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/github_release.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'releases_provider.g.dart';

typedef ReleasePageLoader = Future<List<GithubRelease>> Function(
    int page, CancelToken cancelToken);

final releasePageLoaderProvider = Provider<ReleasePageLoader>((ref) =>
    (page, token) => FlowApi.getReleases(page: page, cancelToken: token));

class ReleasesState {
  const ReleasesState({
    required this.releases,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<GithubRelease> releases;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;
}

// 保留页面原有的显式重试，避免 Riverpod 默认自动重试导致错误页反复加载。
Duration? _manualRetry(int retryCount, Object error) => null;

/// 简单分页用例直接访问 API，刷新和离开页面时取消当前请求。
@Riverpod(retry: _manualRetry)
class Releases extends _$Releases {
  late CancelToken _cancelToken;

  @override
  Future<ReleasesState> build() async {
    final token = _cancelToken = CancelToken();
    ref.onDispose(token.cancel);
    final releases = await ref.read(releasePageLoaderProvider)(1, token);
    return ReleasesState(
        releases: List.unmodifiable(releases),
        page: 1,
        hasMore: releases.isNotEmpty);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    final token = _cancelToken;
    state = AsyncData(ReleasesState(
      releases: current.releases,
      page: current.page,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));
    try {
      final page = current.page + 1;
      final releases = await ref.read(releasePageLoaderProvider)(page, token);
      if (!ref.mounted || token.isCancelled || token != _cancelToken) return;
      state = AsyncData(ReleasesState(
        releases: List.unmodifiable([...current.releases, ...releases]),
        page: page,
        hasMore: releases.isNotEmpty,
      ));
    } catch (error) {
      if (!ref.mounted || token.isCancelled || token != _cancelToken) return;
      state = AsyncData(ReleasesState(
        releases: current.releases,
        page: current.page,
        hasMore: current.hasMore,
        loadMoreError: error,
      ));
    }
  }
}
