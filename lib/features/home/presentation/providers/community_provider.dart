import 'dart:async';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/network/sse/sse_connection_status.dart';
import 'package:anime_flow/shared/models/flow/online_count.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_provider.g.dart';

class CommunityConnectionState {
  const CommunityConnectionState({
    this.watchingSubjects = SseConnectionStatus.connecting,
    this.onlineCount = SseConnectionStatus.connecting,
  });

  final SseConnectionStatus watchingSubjects;
  final SseConnectionStatus onlineCount;

  CommunityConnectionState copyWith({
    SseConnectionStatus? watchingSubjects,
    SseConnectionStatus? onlineCount,
  }) {
    return CommunityConnectionState(
      watchingSubjects: watchingSubjects ?? this.watchingSubjects,
      onlineCount: onlineCount ?? this.onlineCount,
    );
  }

  SseConnectionStatus get overall {
    final statuses = [watchingSubjects, onlineCount];
    if (statuses.contains(SseConnectionStatus.error)) {
      return SseConnectionStatus.error;
    }
    if (statuses.contains(SseConnectionStatus.reconnecting)) {
      return SseConnectionStatus.reconnecting;
    }
    if (statuses.contains(SseConnectionStatus.connecting)) {
      return SseConnectionStatus.connecting;
    }
    if (statuses.every((status) => status == SseConnectionStatus.connected)) {
      return SseConnectionStatus.connected;
    }
    return SseConnectionStatus.disconnected;
  }
}

class CommunityConnectionNotifier extends Notifier<CommunityConnectionState> {
  @override
  CommunityConnectionState build() => const CommunityConnectionState();

  void update({
    required bool watchingSubjects,
    required SseConnectionStatus status,
  }) {
    state = state.copyWith(
      watchingSubjects: watchingSubjects ? status : null,
      onlineCount: watchingSubjects ? null : status,
    );
  }
}

final communityConnectionProvider =
    NotifierProvider<CommunityConnectionNotifier, CommunityConnectionState>(
  CommunityConnectionNotifier.new,
);

void _setConnectionStatus(
  Ref ref, {
  required bool watchingSubjects,
  required SseConnectionStatus status,
}) {
  ref.read(communityConnectionProvider.notifier).update(
        watchingSubjects: watchingSubjects,
        status: status,
      );
}

@riverpod
class CommunityWatchingSubjects extends _$CommunityWatchingSubjects {
  @override
  Future<List<WatchingSubject>> build() async {
    final cancelToken = CancelToken();
    final stream = FlowApi.getWatchingSubjects(
      cancelToken,
      onStatus: (status) => _setConnectionStatus(
        ref,
        watchingSubjects: true,
        status: status,
      ),
    );
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
    final stream = FlowApi.getPresenceOnlineCount(
      cancelToken,
      onStatus: (status) => _setConnectionStatus(
        ref,
        watchingSubjects: false,
        status: status,
      ),
    );
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
