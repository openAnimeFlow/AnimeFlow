// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bangumi_recommendation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bangumiRecommendation)
final bangumiRecommendationProvider = BangumiRecommendationProvider._();

final class BangumiRecommendationProvider extends $FunctionalProvider<
        AsyncValue<SubjectItem>, SubjectItem, FutureOr<SubjectItem>>
    with $FutureModifier<SubjectItem>, $FutureProvider<SubjectItem> {
  BangumiRecommendationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bangumiRecommendationProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            BangumiRecommendationProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$bangumiRecommendationHash();

  @$internal
  @override
  $FutureProviderElement<SubjectItem> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SubjectItem> create(Ref ref) {
    return bangumiRecommendation(ref);
  }
}

String _$bangumiRecommendationHash() =>
    r'f750f037543df0623d8795d0d418ed0ec3b8f4b0';
