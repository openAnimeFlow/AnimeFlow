// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_ui_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoUiNotifier)
final videoUiProvider = VideoUiNotifierProvider._();

final class VideoUiNotifierProvider
    extends $NotifierProvider<VideoUiNotifier, VideoUiState> {
  VideoUiNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoUiProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[
            playExtraProvider,
            playStateProvider
          ],
          $allTransitiveDependencies: <ProviderOrFamily>[
            VideoUiNotifierProvider.$allTransitiveDependencies0,
            VideoUiNotifierProvider.$allTransitiveDependencies1,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;
  static final $allTransitiveDependencies1 = playStateProvider;

  @override
  String debugGetCreateSourceHash() => _$videoUiNotifierHash();

  @$internal
  @override
  VideoUiNotifier create() => VideoUiNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoUiState>(value),
    );
  }
}

String _$videoUiNotifierHash() => r'b69791fad70a09831a1272b9d02e0b08e112f6b8';

abstract class _$VideoUiNotifier extends $Notifier<VideoUiState> {
  VideoUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VideoUiState, VideoUiState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoUiState, VideoUiState>,
        VideoUiState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
