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

String _$animeInfoHash() => r'5903a11c2aea08e665ec360b7697a7ecdc30be74';

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

String _$subjectCommentsHash() => r'5536335f30cba84d8425d0a9deea11a5c67677a8';

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

String _$subjectRelatedHash() => r'5e23fa6efaa9228a0cf93cb0a6e153f84dc7e98c';

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

String _$subjectCharactersHash() => r'e959e11ff38c8a48841e76e2e5d2266f74caa769';

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

String _$subjectProducersHash() => r'dae90c1a8de03f6900d6344eabcb03c15dbfc2ed';

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
