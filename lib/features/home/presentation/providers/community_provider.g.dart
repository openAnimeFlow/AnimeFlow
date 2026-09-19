// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommunityWatchingSubjects)
final communityWatchingSubjectsProvider = CommunityWatchingSubjectsProvider._();

final class CommunityWatchingSubjectsProvider extends $AsyncNotifierProvider<
    CommunityWatchingSubjects, List<WatchingSubject>> {
  CommunityWatchingSubjectsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityWatchingSubjectsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityWatchingSubjectsHash();

  @$internal
  @override
  CommunityWatchingSubjects create() => CommunityWatchingSubjects();
}

String _$communityWatchingSubjectsHash() =>
    r'76b7bc50cfbd50a1699ae6e16f63fc2384fdce80';

abstract class _$CommunityWatchingSubjects
    extends $AsyncNotifier<List<WatchingSubject>> {
  FutureOr<List<WatchingSubject>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<WatchingSubject>>, List<WatchingSubject>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<WatchingSubject>>, List<WatchingSubject>>,
        AsyncValue<List<WatchingSubject>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
