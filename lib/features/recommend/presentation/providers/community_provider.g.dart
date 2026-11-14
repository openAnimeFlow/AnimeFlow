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
    r'f802fa31c7d18c23e65180e782785a8a250f1253';

abstract class _$CommunityWatchingSubjects
    extends $AsyncNotifier<List<WatchingSubject>> {
  FutureOr<List<WatchingSubject>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<WatchingSubject>>, List<WatchingSubject>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<WatchingSubject>>, List<WatchingSubject>>,
        AsyncValue<List<WatchingSubject>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CommunityOnlineCount)
final communityOnlineCountProvider = CommunityOnlineCountProvider._();

final class CommunityOnlineCountProvider
    extends $AsyncNotifierProvider<CommunityOnlineCount, OnlineCount> {
  CommunityOnlineCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityOnlineCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityOnlineCountHash();

  @$internal
  @override
  CommunityOnlineCount create() => CommunityOnlineCount();
}

String _$communityOnlineCountHash() =>
    r'd04ec76c4f89b3378c39f7a17c76e822f39532e9';

abstract class _$CommunityOnlineCount extends $AsyncNotifier<OnlineCount> {
  FutureOr<OnlineCount> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnlineCount>, OnlineCount>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<OnlineCount>, OnlineCount>,
        AsyncValue<OnlineCount>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
