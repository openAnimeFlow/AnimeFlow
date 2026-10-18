// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 角色公开资料

@ProviderFor(CharacterRepository)
final characterRepositoryProvider = CharacterRepositoryProvider._();

/// 角色公开资料
final class CharacterRepositoryProvider
    extends $NotifierProvider<CharacterRepository, void> {
  /// 角色公开资料
  CharacterRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'characterRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$characterRepositoryHash();

  @$internal
  @override
  CharacterRepository create() => CharacterRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$characterRepositoryHash() =>
    r'43d42203f521c15e7db5d5c28e5f659ca6ba7cf9';

/// 角色公开资料

abstract class _$CharacterRepository extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
