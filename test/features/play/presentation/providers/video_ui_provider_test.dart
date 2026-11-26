import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/composition/play_overrides.dart';
import 'package:anime_flow/features/play/presentation/extensions/playback_notice_presentation.dart';
import 'package:anime_flow/shared/navigation/args/play_route_extra.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/domain/player/playback_phase.dart';
import 'package:anime_flow/features/play/domain/player/player_kernel.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/widgets/player/ui/control/middle_area_control.dart';
import 'package:anime_flow/features/play/presentation/widgets/player_settings_sheet.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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
      ...playFeatureOverrides,
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

  testWidgets(
      'MDK buffering shares playback state with an isolated dialog scope',
      (tester) async {
    var cacheSpeedSamples = 0;
    final container = createContainer(PlaybackPhase.playing);
    final playback = container.read(playStateProvider.notifier)
      ..setKernel(PlayerKernel.fvp);
    const sheetKey = ValueKey('settings');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(children: [
            MiddleAreaControl(readCacheSpeed: () async {
              cacheSpeedSamples++;
              return 1024;
            }),
            Builder(builder: (context) {
              return TextButton(
                onPressed: () => showPlayerSettingsSheet(
                  context: context,
                  label: 'Settings',
                  child: Consumer(
                    key: sheetKey,
                    builder: (context, ref, _) {
                      final buffering = ref.watch(
                        playStateProvider.select((state) => state.buffering),
                      );
                      return Text('Settings buffering: $buffering');
                    },
                  ),
                ),
                child: const Text('Open settings'),
              );
            }),
          ]),
        ),
      ),
    ));

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    final sheetContainer = ProviderScope.containerOf(
      tester.element(find.byKey(sheetKey)),
      listen: false,
    );
    expect(sheetContainer, isNot(same(container)));
    expect(sheetContainer.read(playStateProvider.notifier), same(playback));

    playback.setBuffering(true);
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MiddleAreaControl)),
    );
    expect(find.text(l10n.buffering), findsOneWidget);
    expect(find.text('Settings buffering: true'), findsOneWidget);
    expect(cacheSpeedSamples, 0);

    playback.setSwitchingKernel(true);
    playback.setKernel(PlayerKernel.mediaKit);
    await tester.pump();
    expect(cacheSpeedSamples, 0);
    playback.setSwitchingKernel(false);
    await tester.pump();
    await tester.pump();
    expect(cacheSpeedSamples, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(cacheSpeedSamples, 2);

    playback.setSwitchingKernel(true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(cacheSpeedSamples, 2);

    playback.setSwitchingKernel(false);
    await tester.pump();
    await tester.pump();
    expect(cacheSpeedSamples, 3);

    playback.setBuffering(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(cacheSpeedSamples, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player center displays playback errors until the phase changes',
      (tester) async {
    final container = createContainer(PlaybackPhase.idle);
    final playback = container.read(playStateProvider.notifier);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MiddleAreaControl(readCacheSpeed: () async => null),
      ),
    ));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MiddleAreaControl)),
    );
    final resolving = find.text(l10n.videoSourceResolving);

    const errors = [
      PlaybackNotice.sourceResolutionTimedOut,
      PlaybackNotice.sourceNotFound,
      PlaybackNotice.sourceResolutionFailed,
      PlaybackNotice.localVideoNoTrack,
      PlaybackNotice.localVideoValidationTimedOut,
      PlaybackNotice.localVideoOpenFailed,
      PlaybackNotice.localVideoPlaybackFailed,
      PlaybackNotice.onlineVideoPlaybackFailed,
    ];
    for (final notice in errors) {
      playback.setPlaybackPhase(PlaybackPhase.resolving,
          notice: PlaybackNotice.resolvingSource);
      await tester.pump();
      expect(resolving, findsOneWidget);

      final message = find.text(notice.localize(l10n));
      playback.setPlaybackPhase(PlaybackPhase.error, notice: notice);
      await tester.pump();
      expect(message, findsOneWidget);
      expect(resolving, findsNothing);

      playback.setPlaybackPhase(PlaybackPhase.idle);
      await tester.pump();
      expect(message, findsNothing);
    }
  });
}
