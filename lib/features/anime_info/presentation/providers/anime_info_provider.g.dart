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
    extends $StreamNotifierProvider<AnimeInfo, SubjectsInfoItem> {
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

String _$animeInfoHash() => r'f8fe314e1154e0f3b4be37de3281a4e26770cfe4';

abstract class _$AnimeInfo extends $StreamNotifier<SubjectsInfoItem> {
  Stream<SubjectsInfoItem> build();
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

@ProviderFor(SubjectStills)
final subjectStillsProvider = SubjectStillsProvider._();

final class SubjectStillsProvider
    extends $AsyncNotifierProvider<SubjectStills, List<String>> {
  SubjectStillsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectStillsProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[animeInfoArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectStillsProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = animeInfoArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectStillsHash();

  @$internal
  @override
  SubjectStills create() => SubjectStills();
}

String _$subjectStillsHash() => r'a072252f2ad3053c35442e4fe6e8db174892bbe9';

abstract class _$SubjectStills extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<String>>, List<String>>,
        AsyncValue<List<String>>,
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

String _$subjectCommentsHash() => r'16c109ade684240f87a5eb43b18337c418aafe62';

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

String _$subjectRelatedHash() => r'eaaa843c7af504c9c4b9271db75acc06a1b1aa75';

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

String _$subjectCharactersHash() => r'219f71dc0d49953304a59cd5c3a672ab3a5d49dd';

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

String _$subjectProducersHash() => r'5511e9e4dfdc35111578a175fc1535c6cb8b11aa';

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
