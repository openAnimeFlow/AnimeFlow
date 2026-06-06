// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeInfo)
final animeInfoProvider = AnimeInfoProvider._();

final class AnimeInfoProvider
    extends $AsyncNotifierProvider<AnimeInfo, SubjectsInfoItem> {
  AnimeInfoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'animeInfoProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            AnimeInfoProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$animeInfoHash();

  @$internal
  @override
  AnimeInfo create() => AnimeInfo();
}

String _$animeInfoHash() => r'af71e7e4092c829eb5fb0fcaac4dded4d8e18f07';

abstract class _$AnimeInfo extends $AsyncNotifier<SubjectsInfoItem> {
  FutureOr<SubjectsInfoItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubjectsInfoItem>, SubjectsInfoItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectsInfoItem>, SubjectsInfoItem>,
        AsyncValue<SubjectsInfoItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SubjectComments)
final subjectCommentsProvider = SubjectCommentsProvider._();

final class SubjectCommentsProvider
    extends $AsyncNotifierProvider<SubjectComments, SubjectCommentsViewState> {
  SubjectCommentsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectCommentsProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectCommentsProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectCommentsHash();

  @$internal
  @override
  SubjectComments create() => SubjectComments();
}

String _$subjectCommentsHash() => r'0a19a22a3171bb0554eb431957496f81acfd1a90';

abstract class _$SubjectComments
    extends $AsyncNotifier<SubjectCommentsViewState> {
  FutureOr<SubjectCommentsViewState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<SubjectCommentsViewState>, SubjectCommentsViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectCommentsViewState>,
            SubjectCommentsViewState>,
        AsyncValue<SubjectCommentsViewState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

///相关条目

@ProviderFor(SubjectRelated)
final subjectRelatedProvider = SubjectRelatedProvider._();

///相关条目
final class SubjectRelatedProvider
    extends $AsyncNotifierProvider<SubjectRelated, SubjectRelationItem> {
  ///相关条目
  SubjectRelatedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectRelatedProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectRelatedProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectRelatedHash();

  @$internal
  @override
  SubjectRelated create() => SubjectRelated();
}

String _$subjectRelatedHash() => r'953a4fbcfcc6a61e795b46d52db9d2842f54163f';

///相关条目

abstract class _$SubjectRelated extends $AsyncNotifier<SubjectRelationItem> {
  FutureOr<SubjectRelationItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SubjectRelationItem>, SubjectRelationItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<SubjectRelationItem>, SubjectRelationItem>,
        AsyncValue<SubjectRelationItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

///条目角色信息

@ProviderFor(SubjectCharacters)
final subjectCharactersProvider = SubjectCharactersProvider._();

///条目角色信息
final class SubjectCharactersProvider
    extends $AsyncNotifierProvider<SubjectCharacters, CharactersItem> {
  ///条目角色信息
  SubjectCharactersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectCharactersProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectCharactersProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectCharactersHash();

  @$internal
  @override
  SubjectCharacters create() => SubjectCharacters();
}

String _$subjectCharactersHash() => r'1bbf4d7ee30947caee5f48953e862238d6cffafd';

///条目角色信息

abstract class _$SubjectCharacters extends $AsyncNotifier<CharactersItem> {
  FutureOr<CharactersItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CharactersItem>, CharactersItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CharactersItem>, CharactersItem>,
        AsyncValue<CharactersItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

///番剧制作人信息

@ProviderFor(SubjectProducers)
final subjectProducersProvider = SubjectProducersProvider._();

///番剧制作人信息
final class SubjectProducersProvider
    extends $AsyncNotifierProvider<SubjectProducers, ProducersItem> {
  ///番剧制作人信息
  SubjectProducersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectProducersProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectProducersProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectProducersHash();

  @$internal
  @override
  SubjectProducers create() => SubjectProducers();
}

String _$subjectProducersHash() => r'a5057ebf939add838ecbb9b84bb0658313e1518d';

///番剧制作人信息

abstract class _$SubjectProducers extends $AsyncNotifier<ProducersItem> {
  FutureOr<ProducersItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ProducersItem>, ProducersItem>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ProducersItem>, ProducersItem>,
        AsyncValue<ProducersItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
