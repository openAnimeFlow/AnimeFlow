// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_content_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playContentActions)
final playContentActionsProvider = PlayContentActionsProvider._();

final class PlayContentActionsProvider extends $FunctionalProvider<
    PlayContentActions,
    PlayContentActions,
    PlayContentActions> with $Provider<PlayContentActions> {
  PlayContentActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playContentActionsProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[
            playExtraProvider,
            playSessionProvider,
            episodesProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlayContentActionsProvider.$allTransitiveDependencies0,
            PlayContentActionsProvider.$allTransitiveDependencies1,
            PlayContentActionsProvider.$allTransitiveDependencies2,
            PlayContentActionsProvider.$allTransitiveDependencies3,
            PlayContentActionsProvider.$allTransitiveDependencies4,
            PlayContentActionsProvider.$allTransitiveDependencies5,
          },
        );

  static final $allTransitiveDependencies0 = playExtraProvider;
  static final $allTransitiveDependencies1 = playSessionProvider;
  static final $allTransitiveDependencies2 =
      PlaySessionProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      PlaySessionProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 =
      PlaySessionProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      PlaySessionProvider.$allTransitiveDependencies4;

  @override
  String debugGetCreateSourceHash() => _$playContentActionsHash();

  @$internal
  @override
  $ProviderElement<PlayContentActions> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlayContentActions create(Ref ref) {
    return playContentActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayContentActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayContentActions>(value),
    );
  }
}

String _$playContentActionsHash() =>
    r'850a9026fdecf2e70318a61e54c4c29ac67a8a5e';
