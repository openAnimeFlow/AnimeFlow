// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_query_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendation)
final recommendationProvider = RecommendationProvider._();

final class RecommendationProvider extends $FunctionalProvider<
        AsyncValue<SubjectItem>, SubjectItem, FutureOr<SubjectItem>>
    with $FutureModifier<SubjectItem>, $FutureProvider<SubjectItem> {
  RecommendationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recommendationProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            RecommendationProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$recommendationHash();

  @$internal
  @override
  $FutureProviderElement<SubjectItem> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SubjectItem> create(Ref ref) {
    return recommendation(ref);
  }
}

String _$recommendationHash() => r'908e379a504345432b97c7c411a06a6942ce51e2';

@ProviderFor(episodeComments)
final episodeCommentsProvider = EpisodeCommentsProvider._();

final class EpisodeCommentsProvider extends $FunctionalProvider<
        AsyncValue<List<EpisodeComment>>,
        List<EpisodeComment>,
        FutureOr<List<EpisodeComment>>>
    with
        $FutureModifier<List<EpisodeComment>>,
        $FutureProvider<List<EpisodeComment>> {
  EpisodeCommentsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'episodeCommentsProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[episodesProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            EpisodeCommentsProvider.$allTransitiveDependencies0,
            EpisodeCommentsProvider.$allTransitiveDependencies1,
          ],
        );

  static final $allTransitiveDependencies0 = episodesProvider;
  static final $allTransitiveDependencies1 =
      EpisodesProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$episodeCommentsHash();

  @$internal
  @override
  $FutureProviderElement<List<EpisodeComment>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<EpisodeComment>> create(Ref ref) {
    return episodeComments(ref);
  }
}

String _$episodeCommentsHash() => r'97c65a583bace4d164dd8ffaaa1d36b56b01dc99';

@ProviderFor(subjectOnlineCount)
final subjectOnlineCountProvider = SubjectOnlineCountProvider._();

final class SubjectOnlineCountProvider extends $FunctionalProvider<
        AsyncValue<OnlineCount>, OnlineCount, Stream<OnlineCount>>
    with $FutureModifier<OnlineCount>, $StreamProvider<OnlineCount> {
  SubjectOnlineCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectOnlineCountProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectOnlineCountProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectOnlineCountHash();

  @$internal
  @override
  $StreamProviderElement<OnlineCount> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<OnlineCount> create(Ref ref) {
    return subjectOnlineCount(ref);
  }
}

String _$subjectOnlineCountHash() =>
    r'65246ad3b555ebfd0338f80fff6174e7cf5cdf9f';
