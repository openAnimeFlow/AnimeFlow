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
    r'ec1767d973616b63da522fabddafe9343c67ed66';

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
    r'04de583ff5b7f4ba0d3f2a588c64309f69c960fe';

abstract class _$CommunityOnlineCount extends $AsyncNotifier<OnlineCount> {
  FutureOr<OnlineCount> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnlineCount>, OnlineCount>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<OnlineCount>, OnlineCount>,
        AsyncValue<OnlineCount>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
