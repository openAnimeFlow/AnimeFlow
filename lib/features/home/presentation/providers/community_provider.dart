import 'dart:async';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_provider.g.dart';

@riverpod
class CommunityWatchingSubjects extends _$CommunityWatchingSubjects {
  @override
  Future<List<WatchingSubject>> build() async {
    final cancelToken = CancelToken();
    final stream = FlowApi.getWatchingSubjects(cancelToken);
    final firstValue = Completer<List<WatchingSubject>>();
    late final StreamSubscription<List<WatchingSubject>> subscription;
    subscription = stream.listen(
      (subjects) {
        if (!firstValue.isCompleted) {
          firstValue.complete(subjects);
        }
        if (ref.mounted) state = AsyncData(subjects);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!firstValue.isCompleted) {
          firstValue.completeError(error, stackTrace);
        }
        if (ref.mounted) state = AsyncError(error, stackTrace);
      },
    );
    ref.onDispose(() {
      cancelToken.cancel('community watching subjects disposed');
      unawaited(subscription.cancel());
    });
    return firstValue.future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class CommunityOnlineCount extends _$CommunityOnlineCount {
  @override
  Future<OnlineCount> build() async {
    final cancelToken = CancelToken();
    final stream = FlowApi.getPresenceOnlineCount(cancelToken);
    final firstValue = Completer<OnlineCount>();
    late final StreamSubscription<OnlineCount> subscription;
    subscription = stream.listen(
      (count) {
        if (!firstValue.isCompleted) {
          firstValue.complete(count);
        }
        if (ref.mounted) state = AsyncData(count);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!firstValue.isCompleted) {
          firstValue.completeError(error, stackTrace);
        }
        if (ref.mounted) state = AsyncError(error, stackTrace);
      },
    );
    ref.onDispose(() {
      cancelToken.cancel('community online count disposed');
      unawaited(subscription.cancel());
    });
    return firstValue.future;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
