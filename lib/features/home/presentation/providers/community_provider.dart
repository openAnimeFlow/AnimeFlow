import 'dart:async';

import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/flow/watching_subject.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_provider.g.dart';

@riverpod
class CommunityWatchingSubjects extends _$CommunityWatchingSubjects {
  @override
  Future<List<WatchingSubject>> build() {
    final timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidateSelf(),
    );
    ref.onDispose(timer.cancel);
    return FlowApi.getWatchingSubjects();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(FlowApi.getWatchingSubjects);
  }
}
