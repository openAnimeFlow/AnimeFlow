// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoSourceNotifier)
final videoSourceProvider = VideoSourceNotifierProvider._();

final class VideoSourceNotifierProvider
    extends $NotifierProvider<VideoSourceNotifier, VideoSourceState> {
  VideoSourceNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoSourceProvider',
          isAutoDispose: false,
          dependencies: <ProviderOrFamily>[
            episodesProvider,
            playExtraProvider,
            playStateProvider,
            playSessionProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>{
            VideoSourceNotifierProvider.$allTransitiveDependencies0,
            VideoSourceNotifierProvider.$allTransitiveDependencies1,
            VideoSourceNotifierProvider.$allTransitiveDependencies2,
            VideoSourceNotifierProvider.$allTransitiveDependencies3,
            VideoSourceNotifierProvider.$allTransitiveDependencies4,
            VideoSourceNotifierProvider.$allTransitiveDependencies5,
          },
        );

  static final $allTransitiveDependencies0 = episodesProvider;
  static final $allTransitiveDependencies1 =
      EpisodesProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = playStateProvider;
  static final $allTransitiveDependencies3 = playSessionProvider;
  static final $allTransitiveDependencies4 =
      PlaySessionProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies5 =
      PlaySessionProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$videoSourceNotifierHash();

  @$internal
  @override
  VideoSourceNotifier create() => VideoSourceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoSourceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoSourceState>(value),
    );
  }
}

String _$videoSourceNotifierHash() =>
    r'e434930092d7a15c157e793530e93468608dc1a9';

abstract class _$VideoSourceNotifier extends $Notifier<VideoSourceState> {
  VideoSourceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VideoSourceState, VideoSourceState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoSourceState, VideoSourceState>,
        VideoSourceState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
