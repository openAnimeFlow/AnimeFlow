// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playSession)
final playSessionProvider = PlaySessionProvider._();

final class PlaySessionProvider
    extends $FunctionalProvider<PlaySession, PlaySession, PlaySession>
    with $Provider<PlaySession> {
  PlaySessionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playSessionProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[
            shadersDirectoryProvider,
            playStateProvider,
            videoUiProvider,
            episodesProvider,
            playExtraProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlaySessionProvider.$allTransitiveDependencies0,
            PlaySessionProvider.$allTransitiveDependencies1,
            PlaySessionProvider.$allTransitiveDependencies2,
            PlaySessionProvider.$allTransitiveDependencies3,
            PlaySessionProvider.$allTransitiveDependencies4,
          },
        );

  static final $allTransitiveDependencies0 = shadersDirectoryProvider;
  static final $allTransitiveDependencies1 = playStateProvider;
  static final $allTransitiveDependencies2 =
      PlayStateNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 = videoUiProvider;
  static final $allTransitiveDependencies4 = episodesProvider;

  @override
  String debugGetCreateSourceHash() => _$playSessionHash();

  @$internal
  @override
  $ProviderElement<PlaySession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaySession create(Ref ref) {
    return playSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaySession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaySession>(value),
    );
  }
}

String _$playSessionHash() => r'6de0e4d94c0808278c3e578d6f1541d050060ec4';

@ProviderFor(PlayStateNotifier)
final playStateProvider = PlayStateNotifierProvider._();

final class PlayStateNotifierProvider
    extends $NotifierProvider<PlayStateNotifier, PlayState> {
  PlayStateNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playStateProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            PlayStateNotifierProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$playStateNotifierHash();

  @$internal
  @override
  PlayStateNotifier create() => PlayStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayState>(value),
    );
  }
}

String _$playStateNotifierHash() => r'3be31cdc9d20018075bc71a3ccba842c51fc7079';

abstract class _$PlayStateNotifier extends $Notifier<PlayState> {
  PlayState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlayState, PlayState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PlayState, PlayState>, PlayState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
