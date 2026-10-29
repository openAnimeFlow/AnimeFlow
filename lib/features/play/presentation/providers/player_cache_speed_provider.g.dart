// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_cache_speed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 仅缓冲指示器可见且有订阅者时采样，FVP 不启动采样。

@ProviderFor(playerCacheSpeed)
final playerCacheSpeedProvider = PlayerCacheSpeedProvider._();

/// 仅缓冲指示器可见且有订阅者时采样，FVP 不启动采样。

final class PlayerCacheSpeedProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  /// 仅缓冲指示器可见且有订阅者时采样，FVP 不启动采样。
  PlayerCacheSpeedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playerCacheSpeedProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[
            videoUiProvider,
            playStateProvider,
            playSessionProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            PlayerCacheSpeedProvider.$allTransitiveDependencies0,
            PlayerCacheSpeedProvider.$allTransitiveDependencies1,
            PlayerCacheSpeedProvider.$allTransitiveDependencies2,
            PlayerCacheSpeedProvider.$allTransitiveDependencies3,
            PlayerCacheSpeedProvider.$allTransitiveDependencies4,
            PlayerCacheSpeedProvider.$allTransitiveDependencies5,
          },
        );

  static final $allTransitiveDependencies0 = videoUiProvider;
  static final $allTransitiveDependencies1 =
      VideoUiNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      VideoUiNotifierProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = playSessionProvider;
  static final $allTransitiveDependencies4 =
      PlaySessionProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies5 =
      PlaySessionProvider.$allTransitiveDependencies4;

  @override
  String debugGetCreateSourceHash() => _$playerCacheSpeedHash();

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    return playerCacheSpeed(ref);
  }
}

String _$playerCacheSpeedHash() => r'9a1e4fe8c195a3aca96a77cef98c5ee591e2af68';
