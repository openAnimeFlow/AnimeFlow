import 'package:flutter/widgets.dart';

import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'anime_info_provider.g.dart';

/// 条目详情页总状态：条目信息 + 吐槽评论
class AnimeInfoState {
  const AnimeInfoState({
    this.subjectInfo,
    this.subjectComments,
    this.isLoadingComments = false,
    this.hasMoreComments = true,
  });

  final SubjectsInfoItem? subjectInfo;
  final SubjectCommentItem? subjectComments;
  final bool isLoadingComments;
  final bool hasMoreComments;

  AnimeInfoState copyWith({
    SubjectsInfoItem? subjectInfo,
    SubjectCommentItem? subjectComments,
    bool? isLoadingComments,
    bool? hasMoreComments,
  }) {
    return AnimeInfoState(
      subjectInfo: subjectInfo ?? this.subjectInfo,
      subjectComments: subjectComments ?? this.subjectComments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
    );
  }
}

@riverpod
class AnimeInfo extends _$AnimeInfo {
  static const _commentPageSize = 20;

  @override
  Future<AnimeInfoState> build(int subjectId) async {
    final subjectInfo = await BgmRequest.getSubjectByIdService(subjectId);
    final subjectComments = await BgmRequest.getSubjectCommentsByIdService(
      subjectId: subjectId,
      limit: _commentPageSize,
      offset: 0,
    );
    return AnimeInfoState(
      subjectInfo: subjectInfo,
      subjectComments: subjectComments,
      hasMoreComments: subjectComments.data.isNotEmpty &&
          subjectComments.data.length < subjectComments.total,
    );
  }

  void setAnimeInfo(SubjectsInfoItem? subjectInfo) {
    state = switch (state) {
      AsyncData(:final value) => AsyncData(value.copyWith(subjectInfo: subjectInfo)),
      _ => AsyncData(AnimeInfoState(subjectInfo: subjectInfo)),
    };
  }

  Future<void> loadMoreComments() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingComments ||
        !current.hasMoreComments) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingComments: true));

    try {
      final offset = current.subjectComments?.data.length ?? 0;
      final result = await BgmRequest.getSubjectCommentsByIdService(
        subjectId: subjectId,
        limit: _commentPageSize,
        offset: offset,
      );

      final merged = current.subjectComments == null
          ? result
          : SubjectCommentItem(
              data: [...current.subjectComments!.data, ...result.data],
              total: result.total,
            );

      state = AsyncData(
        current.copyWith(
          subjectComments: merged,
          isLoadingComments: false,
          hasMoreComments: result.data.isNotEmpty &&
              merged.data.length < merged.total,
        ),
      );
    } catch (_) {
      final latest = state.asData?.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isLoadingComments: false));
      }
    }
  }

  void checkAndLoadMore(ScrollMetrics metrics) {
    if (metrics.pixels >= metrics.maxScrollExtent - 200) {
      loadMoreComments();
    }
  }
}
