// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_bindings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 在装配处将业务会话连接到路由内的状态和 UI 实现。

@ProviderFor(playSession)
final playSessionProvider = PlaySessionProvider._();

/// 在装配处将业务会话连接到路由内的状态和 UI 实现。

final class PlaySessionProvider
    extends $FunctionalProvider<PlaySession, PlaySession, PlaySession>
    with $Provider<PlaySession> {
  /// 在装配处将业务会话连接到路由内的状态和 UI 实现。
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

String _$playSessionHash() => r'bd468773eba176dcc8457f4c3e8bd35bf5b867d3';
