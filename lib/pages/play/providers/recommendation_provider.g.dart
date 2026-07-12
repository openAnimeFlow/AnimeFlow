// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_provider.dart';

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
          isAutoDispose: false,
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

String _$recommendationHash() => r'706799299dd58e4207e96bb57906bc90c492787e';
