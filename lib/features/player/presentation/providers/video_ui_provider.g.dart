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
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

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

String _$videoUiNotifierHash() => r'2e2b42c07b66589701281f7431512597715f8cc8';

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
