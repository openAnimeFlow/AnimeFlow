import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/actor_item.dart';
import 'package:anime_flow/models/item/bangumi/producers_item.dart';
import 'package:anime_flow/models/item/bangumi/related_subjects_item.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:anime_flow/routes/provider/anime_info_args.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_provider.g.dart';

@Riverpod(dependencies: [animeInfoArgs])
class AnimeInfo extends _$AnimeInfo {
  @override
  Future<SubjectsInfoItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return FlowRequest.getSubjectByIdService(subjectId);
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

@Riverpod(dependencies: [animeInfoArgs])
class SubjectComments extends _$SubjectComments {
  static const _pageSize = 20;
  static const _loadMoreThreshold = 200.0;

  bool _armedForBottomLoad = true;
  bool _loadMoreScheduled = false;

  @override
  Future<SubjectCommentsViewState> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    final comments = await FlowRequest.getSubjectCommentsByIdService(
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
      final subjectId = ref.read(animeInfoArgsProvider.select((e) => e.id));
      final result = await FlowRequest.getSubjectCommentsByIdService(
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
@Riverpod(dependencies: [animeInfoArgs])
class SubjectRelated extends _$SubjectRelated {
  @override
  Future<SubjectRelationItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return FlowRequest.relatedSubjectsService(subjectId, limit: 20, offset: 0);
  }
}

///条目角色信息
@Riverpod(dependencies: [animeInfoArgs])
class SubjectCharacters extends _$SubjectCharacters {
  @override
  Future<CharactersItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return FlowRequest.charactersService(subjectId, limit: 10, offset: 0);
  }
}

///番剧制作人信息
@Riverpod(dependencies: [animeInfoArgs])
class SubjectProducers extends _$SubjectProducers {
  @override
  Future<ProducersItem> build() async {
    final subjectId = ref.watch(animeInfoArgsProvider.select((e) => e.id));
    return FlowRequest.getProducersService(subjectId, limit: 10, offset: 0);
  }
}
