import 'package:anime_flow/features/auth/auth_api.dart';
import 'dart:async';
import 'package:anime_flow/core/network/api/api.dart';

import 'package:anime_flow/features/anime_info/data/repositories/anime_info_repository.dart';
import 'package:anime_flow/features/characters/data/repositories/character_repository.dart';
import 'package:anime_flow/features/user/user_events.dart';
import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/shared/models/bangumi/producers_item.dart';
import 'package:anime_flow/shared/models/bangumi/related_subjects_item.dart';
import 'package:anime_flow/shared/models/bangumi/subject_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/features/user/user_api.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/bangumi/interest_item.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_provider.g.dart';

/// 路由可传入已加载的条目详情，供子页面复用，避免重复请求。
final animeInfoInitialProvider = Provider<SubjectsInfoItem?>((ref) => null);

// 每次构建独立管理请求，依赖变化导致重建时会取消上次构建发出的请求。
CancelToken _requestCancelToken(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel());
  return token;
}

@Riverpod(dependencies: [animeInfoArgs])
class AnimeInfo extends _$AnimeInfo {
  bool _initialConsumed = false;

  Future<String> downloadCover(String image, String name) =>
      Api.downloadImage(image, name);

  @override
  Stream<SubjectsInfoItem> build() async* {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    // 监听收藏和会话变化，使路由传入的旧数据失效，并获取当前用户的最新收藏状态。
    ref.watch(collectionRevisionProvider);
    final repository = ref.watch(animeInfoRepositoryProvider.notifier);
    final tokenFuture = ref.watch(currentFlowTokenProvider.future);
    final initial = ref.watch(animeInfoInitialProvider);
    final forceRefresh = !ref.isFirstBuild;
    final cancelToken = _requestCancelToken(ref);
    // 等待凭证加载完成后再选择会话缓存或请求用户数据，避免误用访客缓存。
    final token = await tokenFuture;
    if (cancelToken.isCancelled) throw cancelToken.cancelError!;
    if (!_initialConsumed && initial?.id == subjectId) {
      _initialConsumed = true;
      yield initial!;
      return;
    }
    yield* repository.watchSubject(subjectId,
        sessionId: token?.sessionId,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh);
  }

  void setAnimeInfo(SubjectsInfoItem subjectInfo) {
    state = AsyncData(subjectInfo);
    final repository = ref.read(animeInfoRepositoryProvider.notifier);
    repository.invalidateCache();
    unawaited(repository.cacheSubject(subjectInfo,
        sessionId: ref.read(currentFlowTokenProvider).value?.sessionId));
  }

  Future<CollectionUpdateResult?> updateCollectionType(int newType) async {
    final subject = state.asData?.value;
    if (subject == null) return null;
    final token = ref.read(currentFlowTokenProvider).value?.sessionId;
    final result =
        await ref.read(userCollectionsProvider.notifier).updateCollectionType(
              UserCollectionData.fromSubject(subject),
              newType,
            );
    if (!ref.mounted ||
        ref.read(currentFlowTokenProvider).value?.sessionId != token) {
      return null;
    }
    final current = state.asData?.value;
    if (current == null || current.id != subject.id) return null;
    if (newType == 0) {
      setAnimeInfo(current.copyWith(clearInterest: true));
      return null;
    }
    final interest = current.interest;
    setAnimeInfo(current.copyWith(
      interest: InterestItem(
        id: interest?.id,
        rate: interest?.rate ?? 0,
        type: newType,
        comment: interest?.comment ?? '',
        tags: interest?.tags ?? const [],
        epStatus: interest?.epStatus ?? 0,
        volStatus: interest?.volStatus ?? 0,
        private: interest?.private ?? false,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        remoteSyncStatus: result?.remoteSyncStatus.apiValue,
      ),
    ));
    return result;
  }
}

@Riverpod(dependencies: [animeInfoArgs])
class SubjectStills extends _$SubjectStills {
  @override
  Stream<List<String>> build() {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return ref.watch(animeInfoRepositoryProvider.notifier).watchStills(
        subjectId,
        cancelToken: _requestCancelToken(ref),
        forceRefresh: ref.isRefresh);
  }
}

/// 评论列表 UI 状态（分页加载标记与 [SubjectCommentItem] 绑定）
class SubjectCommentsViewState {
  const SubjectCommentsViewState({
    required this.comments,
    this.nextOffset = 0,
    this.hasNextPage = true,
    this.isLoadingMore = false,
  });

  final SubjectCommentItem comments;
  final int nextOffset;
  final bool hasNextPage;
  final bool isLoadingMore;

  bool get hasMore => hasNextPage && nextOffset < comments.total;
}

@Riverpod(dependencies: [animeInfoArgs])
class SubjectComments extends _$SubjectComments {
  static const _pageSize = 20;
  static const _loadMoreThreshold = 200.0;

  bool _armedForBottomLoad = true;
  bool _loadMoreScheduled = false;
  late CancelToken _cancelToken;
  bool _forceRefresh = false;

  @override
  Future<SubjectCommentsViewState> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    _cancelToken = _requestCancelToken(ref);
    _armedForBottomLoad = true;
    _loadMoreScheduled = false;
    _forceRefresh = !ref.isFirstBuild;
    final comments =
        await ref.watch(animeInfoRepositoryProvider.notifier).getComments(
              subjectId,
              limit: _pageSize,
              offset: 0,
              cancelToken: _cancelToken,
              forceRefresh: _forceRefresh,
            );
    return SubjectCommentsViewState(
        comments: comments,
        nextOffset: comments.data.length,
        hasNextPage: comments.data.isNotEmpty);
  }

  /// 清理当前条目的评论缓存，并取消旧请求、从首页重新加载。
  void refresh() {
    if (!ref.mounted) return;
    final subjectId = ref.read(animeInfoArgsProvider).id;
    // 清理任务先进入 Repository 队列，新请求会等待清理完成。
    unawaited(ref
        .read(animeInfoRepositoryProvider.notifier)
        .invalidateCommentsCache(subjectId));
    ref.invalidateSelf();
  }

  /// 滚动接近底部时加载更多：离开底部后重新武装，触底仅触发一次（postFrame 延后）。
  void onCommentsScroll(
      {required double pixels, required double maxScrollExtent}) {
    if (maxScrollExtent <= 0) return;

    final nearBottom = pixels >= maxScrollExtent - _loadMoreThreshold;
    if (!nearBottom) {
      _armedForBottomLoad = true;
      return;
    }
    if (!_armedForBottomLoad || _loadMoreScheduled) return;

    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    _armedForBottomLoad = false;
    _loadMoreScheduled = true;
    final cancelToken = _cancelToken;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!ref.mounted || cancelToken.isCancelled) return;
      _loadMoreScheduled = false;
      await loadMore();
    });
  }

  Future<void> loadMore() async {
    if (!ref.mounted || _cancelToken.isCancelled) return;
    final cancelToken = _cancelToken;
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      SubjectCommentsViewState(
        comments: current.comments,
        nextOffset: current.nextOffset,
        hasNextPage: current.hasNextPage,
        isLoadingMore: true,
      ),
    );

    try {
      final prev = current.comments;
      final subjectId = ref.read(animeInfoArgsProvider.select((e) => e.id));
      final result =
          await ref.read(animeInfoRepositoryProvider.notifier).getComments(
                subjectId,
                limit: _pageSize,
                offset: current.nextOffset,
                cancelToken: cancelToken,
                forceRefresh: _forceRefresh,
              );
      if (!ref.mounted || cancelToken.isCancelled) return;
      final merged = SubjectCommentItem(
        data: {
          for (final comment in prev.data) comment.id: comment,
          for (final comment in result.data) comment.id: comment,
        }.values.toList(),
        total: result.total,
      );
      state = AsyncData(SubjectCommentsViewState(
        comments: merged,
        nextOffset: current.nextOffset + result.data.length,
        hasNextPage: result.data.isNotEmpty,
      ));
    } catch (_) {
      if (!ref.mounted || cancelToken.isCancelled) return;
      _armedForBottomLoad = true;
      state = AsyncData(
        SubjectCommentsViewState(
          comments: current.comments,
          nextOffset: current.nextOffset,
          hasNextPage: current.hasNextPage,
          isLoadingMore: false,
        ),
      );
    }
  }
}

///相关条目
@Riverpod(dependencies: [animeInfoArgs])
class SubjectRelated extends _$SubjectRelated {
  @override
  Future<SubjectRelationItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return ref.watch(animeInfoRepositoryProvider.notifier).getRelated(subjectId,
        limit: 20,
        offset: 0,
        cancelToken: _requestCancelToken(ref),
        forceRefresh: !ref.isFirstBuild);
  }
}

///条目角色信息
@Riverpod(dependencies: [animeInfoArgs])
class SubjectCharacters extends _$SubjectCharacters {
  @override
  Future<CharactersItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return ref.watch(characterRepositoryProvider.notifier).getCharacters(
        subjectId,
        limit: 10,
        offset: 0,
        cancelToken: _requestCancelToken(ref),
        forceRefresh: !ref.isFirstBuild);
  }
}

///番剧制作人信息
@Riverpod(dependencies: [animeInfoArgs])
class SubjectProducers extends _$SubjectProducers {
  @override
  Future<ProducersItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return ref.watch(animeInfoRepositoryProvider.notifier).getProducers(
        subjectId,
        limit: 10,
        offset: 0,
        cancelToken: _requestCancelToken(ref),
        forceRefresh: !ref.isFirstBuild);
  }
}
