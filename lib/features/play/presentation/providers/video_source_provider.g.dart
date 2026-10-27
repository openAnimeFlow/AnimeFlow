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
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[
            episodesProvider,
            playExtraProvider,
            playSessionProvider,
            playStateProvider
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
  static final $allTransitiveDependencies2 = playSessionProvider;
  static final $allTransitiveDependencies3 =
      PlaySessionProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 =
      PlaySessionProvider.$allTransitiveDependencies2;
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
    r'4b81e1548e092cb7ab7a7281013726a66a0d15ad';

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
