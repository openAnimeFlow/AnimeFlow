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
    r'42e45bafb8430bd9ced78338983fa872859e53b3';

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

String _$characterWorksHash() => r'46558719fb9b45674cde49c712992821e0451f14';

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

String _$characterCommentsHash() => r'6ec70e94dbd3f075b1c7260066d8ddff6870d8ef';

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
