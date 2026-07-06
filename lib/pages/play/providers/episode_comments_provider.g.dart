// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
          isAutoDispose: false,
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

String _$episodeCommentsHash() => r'64abf4fb4765ffc0bfa7f91934c52cd0be1f6613';
