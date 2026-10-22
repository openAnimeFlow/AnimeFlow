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
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[
            playExtraProvider,
            playStateProvider,
            danmakuStateProvider,
            videoUiProvider,
            episodesProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlaySessionProvider.$allTransitiveDependencies0,
            PlaySessionProvider.$allTransitiveDependencies1,
            PlaySessionProvider.$allTransitiveDependencies2,
            PlaySessionProvider.$allTransitiveDependencies3,
            PlaySessionProvider.$allTransitiveDependencies4,
          },
        );

  static final $allTransitiveDependencies0 = playExtraProvider;
  static final $allTransitiveDependencies1 = playStateProvider;
  static final $allTransitiveDependencies2 = danmakuStateProvider;
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

String _$playSessionHash() => r'294ac3ea71cbcf2c58b2109bf3017f5b5ba6ab87';

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
          isAutoDispose: true,
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

String _$playStateNotifierHash() => r'8a7580129a927e7c4ee7ab2494cdc491ea04b208';

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
