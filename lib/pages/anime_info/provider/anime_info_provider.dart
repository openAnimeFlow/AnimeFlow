import 'package:anime_flow/http/requests/anime_flow_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/models/item/bangumi/producers_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';

part 'anime_info_provider.g.dart';

@riverpod
class AnimeInfo extends _$AnimeInfo {
  @override
  Future<SubjectsInfoItem> build(int subjectId) async {
    return AnimeFlowRequest.getSubjectByIdService(subjectId);
  }

  void setAnimeInfo(SubjectsInfoItem subjectInfo) {
    state = AsyncData(subjectInfo);
  }
}

/// 评论列表 UI 状态（分页加载标记与 [SubjectCommentItem] 绑定）
class SubjectCommentsViewState {
  const SubjectCommentsViewState({
    required this.comments,
    this.isLoadingMore = false,
  });

  final SubjectCommentItem comments;
  final bool isLoadingMore;

  bool get hasMore => comments.data.length < comments.total;
}

@riverpod
class SubjectComments extends _$SubjectComments {
  static const _pageSize = 20;
  static const _loadMoreThreshold = 200.0;

  bool _armedForBottomLoad = true;
  bool _loadMoreScheduled = false;

  @override
  Future<SubjectCommentsViewState> build(int subjectId) async {
    final comments = await BgmRequest.getSubjectCommentsByIdService(
      subjectId: subjectId,
      limit: _pageSize,
      offset: 0,
    );
    return SubjectCommentsViewState(comments: comments);
  }

  /// 滚动接近底部时加载更多：离开底部后重新武装，触底仅触发一次（postFrame 延后）。
  void onCommentsScroll(ScrollMetrics metrics) {
    if (metrics.maxScrollExtent <= 0) return;

    final nearBottom =
        metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold;
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
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _loadMoreScheduled = false;
      await loadMore();
    });
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      SubjectCommentsViewState(
        comments: current.comments,
        isLoadingMore: true,
      ),
    );

    try {
      final prev = current.comments;
      final result = await BgmRequest.getSubjectCommentsByIdService(
        subjectId: subjectId,
        limit: _pageSize,
        offset: prev.data.length,
      );
      final merged = SubjectCommentItem(
        data: [...prev.data, ...result.data],
        total: result.total,
      );
      state = AsyncData(SubjectCommentsViewState(comments: merged));
    } catch (_) {
      _armedForBottomLoad = true;
      state = AsyncData(
        SubjectCommentsViewState(
          comments: current.comments,
          isLoadingMore: false,
        ),
      );
    }
  }
}

///相关条目
@riverpod
class SubjectRelated extends _$SubjectRelated {
  @override
  Future<SubjectRelationItem> build(int subjectId) async {
    return BgmRequest.relatedSubjectsService(
        subjectId,
        limit: 20,
        offset: 0);
  }
}

///条目角色信息
@riverpod
class SubjectCharacters extends _$SubjectCharacters {
  @override
  Future<CharactersItem> build(int subjectId) async {
    return AnimeFlowRequest.charactersService(subjectId,limit: 10, offset: 0);
  }
}

///番剧制作人信息
@riverpod
class SubjectProducers extends _$SubjectProducers {
  @override
  Future<ProducersItem> build(int subjectId) async {
    return BgmRequest.getProducersService(subjectId,limit: 10, offset: 0);
  }
}
