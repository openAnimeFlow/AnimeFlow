import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/presence/presence_service.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subject_online_count_provider.g.dart';

@riverpod
Stream<OnlineCount> subjectOnlineCount(Ref ref, int subjectId) {
  final cancelToken = CancelToken();
  final stream = FlowApi.getSubjectPresenceOnlineCount(
    subjectId,
    PresenceService.instance.presenceId,
    cancelToken,
  );
  ref.onDispose(() {
    cancelToken.cancel('subject online count provider disposed');
  });
  return stream;
}
