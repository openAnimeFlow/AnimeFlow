import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/shared/models/enums/video_controls_icon_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('top notification auto hides without touching parsing',
      (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);

    ui.showParsingIndicator();
    ui.showTopIndicator(VideoControlsIndicatorType.playStatusIndicator);

    // 顶部提示与居中指示器同时展示，互不影响。
    expect(ui.topIndicator, VideoControlsIndicatorType.playStatusIndicator);
    expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);

    await tester.pump(const Duration(seconds: 4));

    expect(ui.topIndicator, VideoControlsIndicatorType.noIndicator);
    expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);
  });

  testWidgets('held top notification stays until cleared', (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);

    ui.showTopIndicator(
      VideoControlsIndicatorType.volumeIndicator,
      autoHide: null,
    );
    await tester.pump(const Duration(seconds: 31));
    expect(ui.topIndicator, VideoControlsIndicatorType.volumeIndicator);

    ui.clearTopIndicator();
    expect(ui.topIndicator, VideoControlsIndicatorType.noIndicator);
  });

  testWidgets('center indicator persists until parsing finishes',
      (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);

    ui.showParsingIndicator();
    // 手势提示与缓冲回调都不能关闭解析指示器。
    ui.showTopIndicator(VideoControlsIndicatorType.brightnessIndicator);
    ui.updateBufferingIndicator(false, isParsing: false);
    ui.clearTopIndicator();
    await tester.pump(const Duration(seconds: 31));

    expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);

    ui.finishParsingIndicator();
    expect(ui.centerIndicator, VideoControlsIndicatorType.noIndicator);
  });

  testWidgets('buffering replaces parsing only after parsing finished',
      (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);

    ui.showParsingIndicator();
    for (final buffering in [true, false, true]) {
      ui.updateBufferingIndicator(buffering, isParsing: false);
      expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);
    }

    ui.finishParsingIndicator();
    ui.updateBufferingIndicator(true, isParsing: false);
    expect(ui.centerIndicator, VideoControlsIndicatorType.bufferingIndicator);

    ui.updateBufferingIndicator(false, isParsing: false);
    expect(ui.centerIndicator, VideoControlsIndicatorType.noIndicator);
  });

  testWidgets('resolver errors keep the persistent parsing indicator',
      (tester) async {
    final container = _container();
    addTearDown(container.dispose);
    final ui = container.read(videoUiProvider.notifier);

    ui.showParsingIndicator();
    ui.updateBufferingIndicator(false, isParsing: false);
    expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);

    ui.updateBufferingIndicator(true, isParsing: true);
    expect(ui.centerIndicator, VideoControlsIndicatorType.parsingIndicator);
  });
}

ProviderContainer _container() => ProviderContainer(overrides: [
      videoUiProvider.overrideWith(_TestVideoUiNotifier.new),
    ]);

// Exercise the production indicator methods without platform battery or
// brightness initialization and its unrelated periodic timers.
class _TestVideoUiNotifier extends VideoUiNotifier {
  @override
  VideoUiState build() => const VideoUiState();
}
