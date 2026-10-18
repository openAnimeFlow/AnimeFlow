import 'dart:async';

import 'package:anime_flow/features/home/data/repositories/popular_anime_repository.dart';
import 'package:anime_flow/shared/models/bangumi/hot_item.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_provider.g.dart';

class AnimeHotState {
  const AnimeHotState({
    this.items = const [],
    this.nextOffset = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isRefreshing = false,
    this.hasUpdate = false,
  });

  final List<Data> items;
  final int nextOffset;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isRefreshing;
  final bool hasUpdate;

  AnimeHotState copyWith({
    List<Data>? items,
    int? nextOffset,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isRefreshing,
    bool? hasUpdate,
  }) {
    return AnimeHotState(
      items: items ?? this.items,
      nextOffset: nextOffset ?? this.nextOffset,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasUpdate: hasUpdate ?? this.hasUpdate,
    );
  }
}

@riverpod
class AnimeHot extends _$AnimeHot {
  static const int limit = 20;
  CancelToken? _cancelToken;
  HotItem? _pendingPage;
  bool _hasScrolled = false;

  /// 用户开始浏览后，不再自动替换排名，避免滚动位置跳变。
  void markScrolled() => _hasScrolled = true;

  CancelToken _startRequest() {
    _cancelToken?.cancel();
    final token = _cancelToken = CancelToken();
    ref.onDispose(() => token.cancel());
    return token;
  }

  @override
  Future<AnimeHotState> build() async {
    final repository = ref.watch(popularAnimeRepositoryProvider.notifier);
    final token = _startRequest();
    _pendingPage = null;
    final cached = repository.readPage(limit: limit, offset: 0);
    if (cached != null) {
      final needsRefresh = !cached.isFresh || !ref.isFirstBuild;
      if (needsRefresh) {
        // 等初始 AsyncData 发布后，再通知页面后台刷新的结果。
        unawaited(Future(() => _refreshCachedPage(repository, token)));
      }
      return _pageState(cached.data).copyWith(isRefreshing: needsRefresh);
    }
    return _pageState(
        await repository.getPage(limit: limit, offset: 0, cancelToken: token));
  }

  AnimeHotState _pageState(HotItem page) => AnimeHotState(
        items: page.data,
        nextOffset: page.data.length,
        hasMore: page.data.isNotEmpty && page.data.length < page.total,
      );

  Future<void> _refreshCachedPage(
    PopularAnimeRepository repository,
    CancelToken token,
  ) async {
    if (!ref.mounted || token.isCancelled) return;
    try {
      final page = await repository.getPage(
          limit: limit,
          offset: 0,
          cancelToken: token,
          forceRefresh: true,
          fallbackToCache: false);
      if (!ref.mounted || token.isCancelled) return;
      final current = state.asData?.value;
      if (current == null) return;
      if (_hasScrolled) {
        _pendingPage = page;
        state =
            AsyncData(current.copyWith(isRefreshing: false, hasUpdate: true));
      } else {
        state = AsyncData(_pageState(page));
      }
    } catch (_) {
      if (!ref.mounted || token.isCancelled) return;
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData(current.copyWith(isRefreshing: false));
      }
    }
  }

  void applyUpdate() {
    if (!ref.mounted || _pendingPage == null) return;
    final page = _pendingPage!;
    _pendingPage = null;
    _startRequest();
    _hasScrolled = false;
    state = AsyncData(_pageState(page));
  }

  Future<void> loadMore() async {
    if (!ref.mounted) return;
    final token = _cancelToken;
    if (token == null || token.isCancelled) return;
    final current = state.asData?.value;
    if (current == null ||
        current.isLoading ||
        current.isRefreshing ||
        current.hasUpdate ||
        !current.hasMore) {
      return;
    }
    _hasScrolled = true;

    state = AsyncData(
      current.copyWith(isLoading: true, clearErrorMessage: true),
    );

    try {
      final hotItem = await ref
          .read(popularAnimeRepositoryProvider.notifier)
          .getPage(
              limit: limit, offset: current.nextOffset, cancelToken: token);
      if (!ref.mounted || token.isCancelled) return;
      final nextItems = {
        for (final item in current.items) item.subject.id: item,
        for (final item in hotItem.data) item.subject.id: item,
      }.values.toList();
      final nextOffset = current.nextOffset + hotItem.data.length;
      state = AsyncData(
        AnimeHotState(
          items: nextItems,
          nextOffset: nextOffset,
          hasMore: hotItem.data.isNotEmpty && nextOffset < hotItem.total,
        ),
      );
    } catch (error) {
      if (!ref.mounted || token.isCancelled) return;
      state = AsyncData(
        current.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    if (_pendingPage != null) {
      applyUpdate();
      return;
    }
    final repository = ref.read(popularAnimeRepositoryProvider.notifier);
    final token = _startRequest();
    final current = state.asData?.value;
    state = current == null
        ? const AsyncLoading()
        : AsyncData(current.copyWith(isLoading: false, isRefreshing: true));
    try {
      final page = await repository.getPage(
          limit: limit,
          offset: 0,
          cancelToken: token,
          forceRefresh: true,
          fallbackToCache: false);
      if (!ref.mounted || token.isCancelled) return;
      _hasScrolled = false;
      state = AsyncData(_pageState(page));
    } catch (error, stack) {
      if (!ref.mounted || token.isCancelled) return;
      state = current == null
          ? AsyncError(error, stack)
          : AsyncData(current.copyWith(isLoading: false, isRefreshing: false));
    }
  }
}
