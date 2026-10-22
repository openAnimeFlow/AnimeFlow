import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/app/router/routes_args.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([PlayStateNotifier, VideoUiNotifier])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const battery = MethodChannel('dev.fluttercommunity.plus/battery');
  const charging = MethodChannel('dev.fluttercommunity.plus/charging');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(battery,
        (call) async => call.method == 'getBatteryLevel' ? 100 : 'full');
    messenger.setMockMethodCallHandler(charging, (_) async => null);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(battery, null);
    messenger.setMockMethodCallHandler(charging, null);
  });

  @Dependencies([PlayStateNotifier, VideoUiNotifier])
  ProviderContainer createContainer(PlaybackPhase phase) {
    final container = ProviderContainer(overrides: [
      playExtraProvider.overrideWithValue(const PlayRouteExtra(
        playExtra: PlayExtra(
            subjectId: 1,
            subjectName: '',
            subjectCover: '',
            subjectAliases: []),
      )),
    ]);
    addTearDown(container.dispose);
    container.read(playStateProvider.notifier).setPlaybackPhase(phase);
    container.listen(videoUiProvider, (_, __) {});
    return container;
  }

  test('UI derives startup and buffering indicators from playback state', () {
    final container = createContainer(PlaybackPhase.opening);
    final playback = container.read(playStateProvider.notifier);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.parsingIndicator);
    playback.setBuffering(true);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.parsingIndicator);
    playback.setPlaybackPhase(PlaybackPhase.playing);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.bufferingIndicator);
    playback.setBuffering(false);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.noIndicator);
  });

  test('manual source selection remains visible until the new phase takes over',
      () {
    final container = createContainer(PlaybackPhase.playing);
    final playback = container.read(playStateProvider.notifier);
    container.read(videoUiProvider.notifier).showParsingIndicator();
    playback.setBuffering(true);
    playback.setBuffering(false);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.parsingIndicator);
    playback.setPlaybackPhase(PlaybackPhase.opening);
    playback.setPlaybackPhase(PlaybackPhase.playing);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.noIndicator);
  });

  test('startup errors clear loading even when the old media was buffering',
      () {
    final container = createContainer(PlaybackPhase.resolving);
    final playback = container.read(playStateProvider.notifier);
    playback.setBuffering(true);
    playback.setPlaybackPhase(PlaybackPhase.error);
    expect(container.read(videoUiProvider).centerIndicator,
        VideoControlsIndicatorType.noIndicator);
  });
}
