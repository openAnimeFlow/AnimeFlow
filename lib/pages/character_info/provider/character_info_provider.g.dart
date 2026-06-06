// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CharacterInfoDetail)
final characterInfoDetailProvider = CharacterInfoDetailProvider._();

final class CharacterInfoDetailProvider
    extends $AsyncNotifierProvider<CharacterInfoDetail, CharacterDetailItem> {
  CharacterInfoDetailProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'characterInfoDetailProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[characterInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            CharacterInfoDetailProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = characterInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$characterInfoDetailHash();

  @$internal
  @override
  CharacterInfoDetail create() => CharacterInfoDetail();
}

String _$characterInfoDetailHash() =>
    r'4bfaa0aafb10437b76e14b23b76d5ed79f7c9aff';

abstract class _$CharacterInfoDetail
    extends $AsyncNotifier<CharacterDetailItem> {
  FutureOr<CharacterDetailItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CharacterDetailItem>, CharacterDetailItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CharacterDetailItem>, CharacterDetailItem>,
        AsyncValue<CharacterDetailItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CharacterWorks)
final characterWorksProvider = CharacterWorksProvider._();

final class CharacterWorksProvider
    extends $AsyncNotifierProvider<CharacterWorks, CharacterCastsItem> {
  CharacterWorksProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'characterWorksProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[characterInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            CharacterWorksProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = characterInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$characterWorksHash();

  @$internal
  @override
  CharacterWorks create() => CharacterWorks();
}

String _$characterWorksHash() => r'6d6a0d3635cb942055968454c200490dfa19d86f';

abstract class _$CharacterWorks extends $AsyncNotifier<CharacterCastsItem> {
  FutureOr<CharacterCastsItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CharacterCastsItem>, CharacterCastsItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CharacterCastsItem>, CharacterCastsItem>,
        AsyncValue<CharacterCastsItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CharacterComments)
final characterCommentsProvider = CharacterCommentsProvider._();

final class CharacterCommentsProvider extends $AsyncNotifierProvider<
    CharacterComments, List<CharacterCommentItem>> {
  CharacterCommentsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'characterCommentsProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[characterInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            CharacterCommentsProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = characterInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$characterCommentsHash();

  @$internal
  @override
  CharacterComments create() => CharacterComments();
}

String _$characterCommentsHash() => r'17083f6e8c81e21d278a0bc5aace978cb5d32e37';

abstract class _$CharacterComments
    extends $AsyncNotifier<List<CharacterCommentItem>> {
  FutureOr<List<CharacterCommentItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<CharacterCommentItem>>,
        List<CharacterCommentItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<CharacterCommentItem>>,
            List<CharacterCommentItem>>,
        AsyncValue<List<CharacterCommentItem>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
