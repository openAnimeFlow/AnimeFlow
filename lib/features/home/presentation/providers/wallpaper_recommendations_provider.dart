import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/subject_wallpaper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wallpaperRecommendationsProvider =
    FutureProvider.autoDispose.family<List<SubjectWallpaper>, int>(
  (ref, subjectId) async {
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    final response = await FlowApi.getRecommendedWallpapersService(
      subjectId,
      cancelToken: cancelToken,
    );
    final seen = <int>{subjectId};
    return response.data
        .where((subject) =>
            subject.coverImages.isNotEmpty && seen.add(subject.subjectId))
        .toList(growable: false);
  },
  retry: (_, __) => null,
);
