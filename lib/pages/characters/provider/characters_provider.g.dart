// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'characters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CharactersList)
final charactersListProvider = CharactersListProvider._();

final class CharactersListProvider
    extends $AsyncNotifierProvider<CharactersList, CharactersViewState> {
  CharactersListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'charactersListProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[charactersArgsProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            CharactersListProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = charactersArgsProvider;

  @override
  String debugGetCreateSourceHash() => _$charactersListHash();

  @$internal
  @override
  CharactersList create() => CharactersList();
}

String _$charactersListHash() => r'86499dee7ce69c14aa01d86d6b17051b96de233c';

abstract class _$CharactersList extends $AsyncNotifier<CharactersViewState> {
  FutureOr<CharactersViewState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CharactersViewState>, CharactersViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CharactersViewState>, CharactersViewState>,
        AsyncValue<CharactersViewState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
